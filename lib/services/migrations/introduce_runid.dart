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

        // Generate RunIDs for each detected sync event
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
        }

        // 4. Backfill FollowUsersHistory with 'Previous Version' RunIDs
        // A reverse diff at TS_i describes the state BEFORE the change.
        // Thus, History at tsList[i] is assigned the RunID of the state it reverts to.
        for (int i = 0; i < tsList.length; i++) {
          final targetTs = tsList[i];
          final targetRid = runIds[i];

          await (db.update(db.followUsersHistory)..where(
                (t) => t.ownerId.equals(ownerId) & t.timestamp.equals(targetTs),
              ))
              .write(FollowUsersHistoryCompanion(runId: Value(targetRid)));
        }

        // 5. Backfill FollowUsers with 'Current Version' RunIDs
        // Current version = (Latest History's RunID) + 1 step in the timeline
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
            ridGrouping[run0Id]!.add(user.userId);
          } else {
            final idx = tsList.indexOf(latestHistory.timestamp);
            // Result of sync at tsList[idx] is runIds[idx + 1]
            ridGrouping[runIds[idx + 1]]!.add(user.userId);
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
