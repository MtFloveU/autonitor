import 'package:autonitor/main.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/services/log_service.dart';
import '../providers/history_worker_provider.dart';
import '../services/database.dart';
import '../models/history_snapshot.dart';
import '../models/app_settings.dart';
import '../models/twitter_user.dart';
import '../utils/history_rebuild_worker.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final worker = ref.watch(historyWorkerProvider);
  return HistoryRepository(db, worker);
});

// [新增] 结果封装类
class HistoryPagedResult {
  final List<HistorySnapshot> snapshots;
  final int totalCount;
  HistoryPagedResult({required this.snapshots, required this.totalCount});
}

class HistoryRepository {
  final AppDatabase _db;
  final HistoryRebuildWorker _worker;

  HistoryRepository(this._db, this._worker);

  Future<FollowUserHistoryEntry?> getLatestHistoryEntry(String ownerId, String userId) async {
    if (userId == ownerId) {
      return await (_db.select(_db.accountProfileHistory)
            ..where((tbl) => tbl.ownerId.equals(ownerId))
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc),
            ])
            ..limit(1))
          .map((e) => FollowUserHistoryEntry(
                id: e.id,
                ownerId: e.ownerId,
                userId: e.ownerId,
                reverseDiffJson: e.reverseDiffJson,
                timestamp: e.timestamp,
              ))
          .getSingleOrNull();
    } else {
      return await (_db.select(_db.followUsersHistory)
            ..where((tbl) => tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId))
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc),
            ])
            ..limit(1))
          .getSingleOrNull();
    }
  }

  // [修改] 只查 raw count 备用，实际过滤后总数由 worker 返回
  Future<int> getRawHistoryCount(String ownerId, String userId) async {
    Expression<int> countExp = const FunctionCallExpression('COUNT', [
      Constant('*'),
    ]);

    if (userId == ownerId) {
      final query = _db.selectOnly(_db.accountProfileHistory)
        ..addColumns([countExp])
        ..where(_db.accountProfileHistory.ownerId.equals(ownerId));
      return await query.map((row) => row.read(countExp)).getSingle() ?? 0;
    } else {
      final query = _db.selectOnly(_db.followUsersHistory)
        ..addColumns([countExp])
        ..where(
          _db.followUsersHistory.ownerId.equals(ownerId) &
              _db.followUsersHistory.userId.equals(userId),
        );
      return await query.map((row) => row.read(countExp)).getSingle() ?? 0;
    }
  }

  Future<HistoryPagedResult> getFilteredHistory(
    String ownerId,
    String userId,
    AppSettings settings, {
    int page = 1,
    int pageSize = 20,
  }) async {
    String? latestRawJson;
    List<Map<String, dynamic>> historyEntriesForIsolate = [];

    // [关键] 移除 limit/offset，获取全量数据以供 Worker 重建和过滤
    if (userId == ownerId) {
      final account = await (_db.select(
        _db.loggedAccounts,
      )..where((tbl) => tbl.id.equals(ownerId))).getSingleOrNull();
      latestRawJson = account?.latestRawJson;

      if (latestRawJson != null) {
        final historyEntries =
            await (_db.select(_db.accountProfileHistory)
                  ..where((tbl) => tbl.ownerId.equals(ownerId))
                  ..orderBy([
                    (tbl) => OrderingTerm(
                      expression: tbl.timestamp,
                      mode: OrderingMode.desc,
                    ),
                  ])) // [移除 limit]
                .get();

        historyEntriesForIsolate = historyEntries.map((e) {
          return <String, dynamic>{
            'id': e.id,
            'ownerId': e.ownerId,
            'userId': e.ownerId,
            'reverseDiffJson': e.reverseDiffJson,
            'timestampMs': e.timestamp.millisecondsSinceEpoch,
          };
        }).toList();
      }
    } else {
      final currentUser =
          await (_db.select(_db.followUsers)..where(
                (tbl) =>
                    tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId),
              ))
              .getSingleOrNull();
      latestRawJson = currentUser?.latestRawJson;

      if (latestRawJson != null) {
        final historyEntries =
            await (_db.select(_db.followUsersHistory)
                  ..where(
                    (tbl) =>
                        tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId),
                  )
                  ..orderBy([
                    (tbl) => OrderingTerm(
                      expression: tbl.timestamp,
                      mode: OrderingMode.desc,
                    ),
                  ])) // [移除 limit]
                .get();

        historyEntriesForIsolate = historyEntries.map((e) {
          return <String, dynamic>{
            'id': e.id,
            'ownerId': e.ownerId,
            'userId': e.userId,
            'reverseDiffJson': e.reverseDiffJson,
            'timestampMs': e.timestamp.millisecondsSinceEpoch,
          };
        }).toList();
      }
    }

    if (latestRawJson == null || historyEntriesForIsolate.isEmpty) {
      return HistoryPagedResult(snapshots: [], totalCount: 0);
    }

    final mediaHistory =
        await (_db.select(_db.mediaHistory)..orderBy([
              (tbl) =>
                  OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
            ]))
            .get();

    final mediaHistoryForIsolate = mediaHistory.map((m) {
      return <String, dynamic>{
        'id': m.id,
        'mediaType': m.mediaType,
        'remoteUrl': m.remoteUrl,
        'localFilePath': m.localFilePath,
      };
    }).toList();

    final payload = <String, dynamic>{
      'settings': settings.toJson(),
      'userId': userId,
      'latestRawJson': latestRawJson,
      'historyEntries': historyEntriesForIsolate,
      'mediaHistory': mediaHistoryForIsolate,
      'page': page, // [传递]
      'pageSize': pageSize, // [传递]
    };

    dynamic rawResult;
    try {
      rawResult = await _worker.run(payload);
    } catch (e, s) {
      logger.e('HistoryRepository: worker.run failed', error: e, stackTrace: s);
      return HistoryPagedResult(snapshots: [], totalCount: 0);
    }

    if (rawResult == null || rawResult is! Map) {
      return HistoryPagedResult(snapshots: [], totalCount: 0);
    }

    final int totalCount = rawResult['total'] as int;
    final List items = rawResult['items'] as List;

    final Map<int, Map<String, dynamic>> originalEntryMap = {
      for (var e in historyEntriesForIsolate) e['id'] as int: e,
    };

    final List<HistorySnapshot> snapshots = [];

    for (final rawItem in items) {
      try {
        if (rawItem is! Map) continue;

        final itemMap = rawItem as Map<String, dynamic>;
        final int entryId = itemMap['entryId'] as int;
        final String fullJson = itemMap['fullJson'] as String;
        final String diffJson = itemMap['diffJson'] as String;

        final Map<String, dynamic> userMap = Map<String, dynamic>.from(
          itemMap['userMap'] as Map,
        );

        final user = TwitterUser.fromJson(userMap);

        final originalData = originalEntryMap[entryId];
        if (originalData != null) {
          final int timestampMs = originalData['timestampMs'] as int;

          final entry = FollowUserHistoryEntry(
            id: entryId,
            ownerId: ownerId,
            userId: userId,
            reverseDiffJson: diffJson, // Worker 返回的是正向 Diff
            timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
          );

          snapshots.add(
            HistorySnapshot(entry: entry, user: user, fullJson: fullJson),
          );
        }
      } catch (e, s) {
        logger.w(
          'HistoryRepository: snapshot reconstruction failed',
          error: e,
          stackTrace: s,
        );
      }
    }

    return HistoryPagedResult(snapshots: snapshots, totalCount: totalCount);
  }
}
