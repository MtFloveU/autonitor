import 'package:autonitor/providers/runid_provider.dart';
import 'package:drift/drift.dart';
import '../database.dart';
import '../log_service.dart';

class MigrateToV5 {
  static Future<void> execute(AppDatabase db) async {
    logger.i("Starting migration to v5 (Timeline Reconstruction)...");

    final runIdService = RunIdService(db);

    await db.transaction(() async {
      // 1. Fetch all unique owners who have relationship records
      final ownersQuery = db.selectOnly(db.followUsers, distinct: true)
        ..addColumns([db.followUsers.ownerId]);
      final owners = await ownersQuery
          .map((row) => row.read(db.followUsers.ownerId))
          .get();

      for (final ownerId in owners.whereType<String>()) {
        logger.i("Reconstructing timeline for owner: $ownerId");

        // 2. Extract distinct sync event timestamps from history to build the timeline
        final historyTsQuery =
            db.selectOnly(db.followUsersHistory, distinct: true)
              ..addColumns([db.followUsersHistory.timestamp])
              ..where(db.followUsersHistory.ownerId.equals(ownerId))
              ..orderBy([
                OrderingTerm(expression: db.followUsersHistory.timestamp),
              ]);

        final sortedTimestamps = await historyTsQuery
            .map((row) => row.read(db.followUsersHistory.timestamp))
            .get();
        final List<DateTime> tsList = sortedTimestamps
            .whereType<DateTime>()
            .toList();

        // 3. Create SyncLogs entries for the entire timeline
        // Run 0: The Baseline (Unix Epoch 0)
        final String run0Id = await runIdService.generateUniqueRunId();
        await db
            .into(db.syncLogs)
            .insert(
              SyncLogsCompanion.insert(
                runId: run0Id,
                ownerId: Value(ownerId),
                timestamp: DateTime.fromMillisecondsSinceEpoch(0),
                status: 1,
              ),
            );

        // Map to store Timestamp -> RunID relationship for O(1) lookup
        final Map<DateTime, String> tsToRunIdMap = {};

        // runIds[0] is baseline, runIds[1] is for tsList[0], etc.
        final List<String> runIds = [run0Id];

        for (final ts in tsList) {
          final rid = await runIdService.generateUniqueRunId();
          await db
              .into(db.syncLogs)
              .insert(
                SyncLogsCompanion.insert(
                  runId: rid,
                  ownerId: Value(ownerId),
                  timestamp: ts,
                  status: 1,
                ),
              );
          runIds.add(rid);
          // 建立映射：该时间戳 ts 对应生成的 rid
          tsToRunIdMap[ts] = rid;
        }

        // 4. Backfill FollowUsersHistory based on User's Previous Version
        // 核心逻辑修改：
        // 不使用当前记录的 timestamp 对应 SyncLogs，而是找到该用户“上一次”变更的时间戳对应的 RunID。
        // 如果没有上一次变更（即第一条记录），则归属为 Baseline (run0Id)。

        // 4.1 获取该 owner 下所有有历史记录的用户
        final historyUsersQuery =
            db.selectOnly(db.followUsersHistory, distinct: true)
              ..addColumns([db.followUsersHistory.userId])
              ..where(db.followUsersHistory.ownerId.equals(ownerId));

        final historyUserIds = await historyUsersQuery
            .map((row) => row.read(db.followUsersHistory.userId))
            .get();

        // 4.2 批量更新历史记录
        await db.batch((batch) async {
          for (final userId in historyUserIds.whereType<String>()) {
            // 获取该用户按时间正序排列的所有历史记录
            final userHistoryList =
                await (db.select(db.followUsersHistory)
                      ..where(
                        (t) =>
                            t.ownerId.equals(ownerId) & t.userId.equals(userId),
                      )
                      ..orderBy([
                        (t) => OrderingTerm(
                          expression: t.timestamp,
                          mode: OrderingMode.asc,
                        ),
                      ]))
                    .get();

            for (int i = 0; i < userHistoryList.length; i++) {
              final currentHistory = userHistoryList[i];
              String targetRunId;

              if (i == 0) {
                // 第一条历史记录：意味着它的前一个状态是 Baseline
                targetRunId = run0Id;
              } else {
                // 后续记录：找到该用户“上一次”变更的时间戳
                final previousHistoryTimestamp =
                    userHistoryList[i - 1].timestamp;
                // 根据上一次的时间戳找到对应的 RunID
                if (tsToRunIdMap.containsKey(previousHistoryTimestamp)) {
                  targetRunId = tsToRunIdMap[previousHistoryTimestamp]!;
                } else {
                  // 防御性代码：理论上不应发生，如果找不到对应时间戳，回退到 Baseline
                  targetRunId = run0Id;
                  logger.w(
                    "Warning: RunID not found for timestamp $previousHistoryTimestamp, defaulting to run0.",
                  );
                }
              }

              batch.update(
                db.followUsersHistory,
                FollowUsersHistoryCompanion(runId: Value(targetRunId)),
                where: (t) => t.id.equals(currentHistory.id),
              );
            }
          }
        });

        // 5. Backfill FollowUsers with 'Current Version' RunIDs
        // 当前版本 = 用户最后一次变更所产生的 RunID
        // (即：如果最后一次变更是 T_latest，那么当前状态属于 T_latest 对应的 RunID)
        final Map<String, List<String>> ridGrouping = {
          for (var rid in runIds) rid: [],
        };

        final users = await (db.select(
          db.followUsers,
        )..where((t) => t.ownerId.equals(ownerId))).get();

        for (final user in users) {
          final latestHistory =
              await (db.select(db.followUsersHistory)
                    ..where(
                      (t) =>
                          t.ownerId.equals(ownerId) &
                          t.userId.equals(user.userId),
                    )
                    ..orderBy([
                      (t) => OrderingTerm(
                        expression: t.timestamp,
                        mode: OrderingMode.desc,
                      ),
                    ])
                    ..limit(1))
                  .getSingleOrNull();

          if (latestHistory == null) {
            // 从未变更过，属于 Baseline
            ridGrouping[run0Id]!.add(user.userId);
          } else {
            // 有变更记录，当前状态属于最后一次变更产生的时间戳对应的 RunID
            final latestTs = latestHistory.timestamp;
            if (tsToRunIdMap.containsKey(latestTs)) {
              ridGrouping[tsToRunIdMap[latestTs]!]!.add(user.userId);
            } else {
              // 异常兜底
              ridGrouping[run0Id]!.add(user.userId);
            }
          }
        }

        // Batch update users to their respective reconstructed RunIDs
        await db.batch((b) {
          for (final entry in ridGrouping.entries) {
            if (entry.value.isEmpty) continue;

            b.update(
              db.followUsers,
              FollowUsersCompanion(runId: Value(entry.key)),
              where: (t) =>
                  t.ownerId.equals(ownerId) & t.userId.isIn(entry.value),
            );
          }
        });
      }
    });

    logger.i(
      "Migration to v5 (Timeline Reconstruction) completed successfully.",
    );
  }
}
