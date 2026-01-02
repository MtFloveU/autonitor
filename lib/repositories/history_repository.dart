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

class HistoryPagedResult {
  final List<HistorySnapshot> snapshots;
  final int totalCount;
  HistoryPagedResult({required this.snapshots, required this.totalCount});
}

class HistoryRepository {
  final AppDatabase _db;
  final HistoryRebuildWorker _worker;

  HistoryRepository(this._db, this._worker);

  Future<List<Map<String, dynamic>>> getFieldHistory({
    required String ownerId,
    required String userId,
    required String targetKey,
  }) async {
    String? latestRawJson;
    int? currentStateTs;
    List<Map<String, dynamic>> historyEntriesForIsolate = [];

    if (userId == ownerId) {
      final account = await (_db.select(
        _db.loggedAccounts,
      )..where((tbl) => tbl.id.equals(ownerId))).getSingleOrNull();
      latestRawJson = account?.latestRawJson;
      // 登录账户目前没有 RunID 概念，暂时使用当前时间
      currentStateTs = DateTime.now().millisecondsSinceEpoch;

      if (latestRawJson != null) {
        final historyEntries =
            await (_db.select(_db.accountProfileHistory)
                  ..where((tbl) => tbl.ownerId.equals(ownerId))
                  ..orderBy([
                    (tbl) => OrderingTerm(
                      expression: tbl.timestamp,
                      mode: OrderingMode.desc,
                    ),
                  ]))
                .get();
        historyEntriesForIsolate = historyEntries
            .map(
              (e) => {
                'reverseDiffJson': e.reverseDiffJson,
                'timestampMs': e.timestamp.millisecondsSinceEpoch,
              },
            )
            .toList();
      }
    } else {
      final user =
          await (_db.select(_db.followUsers)..where(
                (tbl) =>
                    tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId),
              ))
              .getSingleOrNull();
      latestRawJson = user?.latestRawJson;

      if (user != null && latestRawJson != null) {
        // [修复] 获取当前 User 主表状态对应的业务时间戳 (SyncLogs)
        final currentRunLog = await (_db.select(
          _db.syncLogs,
        )..where((t) => t.runId.equals(user.runId ?? ''))).getSingleOrNull();

        currentStateTs =
            currentRunLog?.timestamp.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;

        // [修复] 联表查询：获取历史记录及其对应的业务时间戳
        final query =
            _db.select(_db.followUsersHistory).join([
                leftOuterJoin(
                  _db.syncLogs,
                  _db.syncLogs.runId.equalsExp(_db.followUsersHistory.runId),
                ),
              ])
              ..where(
                _db.followUsersHistory.ownerId.equals(ownerId) &
                    _db.followUsersHistory.userId.equals(userId),
              )
              ..orderBy([OrderingTerm.desc(_db.syncLogs.timestamp)]);

        final rows = await query.get();

        historyEntriesForIsolate = rows.map((row) {
          final history = row.readTable(_db.followUsersHistory);
          final log = row.readTableOrNull(_db.syncLogs);

          return {
            'reverseDiffJson': history.reverseDiffJson,
            // 优先使用 SyncLog 的时间，若无则回退到记录时间
            'timestampMs':
                log?.timestamp.millisecondsSinceEpoch ??
                history.timestamp.millisecondsSinceEpoch,
          };
        }).toList();
      }
    }

    if (latestRawJson == null) return [];

    final payload = {
      'action': 'fetch_field_history',
      'latestRawJson': latestRawJson,
      'historyEntries': historyEntriesForIsolate,
      'targetKey': targetKey,
      'currentStateTimestampMs': currentStateTs, // [关键] 传入锚点时间
    };

    final result = await _worker.run(payload);
    return (result as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getLatestRelevantDiff(
    String ownerId,
    String userId,
  ) async {
    // 此方法逻辑相对独立，暂时保持原有结构，若需 RunID 支持可参考 getFilteredHistory
    String? latestRawJson;
    List<Map<String, dynamic>> historyEntriesForIsolate = [];

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
                  ]))
                .get();
        historyEntriesForIsolate = historyEntries
            .map(
              (e) => {
                'id': e.id,
                'reverseDiffJson': e.reverseDiffJson,
                'timestampMs': e.timestamp.millisecondsSinceEpoch,
              },
            )
            .toList();
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
                  ]))
                .get();
        historyEntriesForIsolate = historyEntries
            .map(
              (e) => {
                'id': e.id,
                'reverseDiffJson': e.reverseDiffJson,
                'timestampMs': e.timestamp.millisecondsSinceEpoch,
              },
            )
            .toList();
      }
    }

    if (latestRawJson == null || historyEntriesForIsolate.isEmpty) return null;

    final payload = <String, dynamic>{
      'action': 'fetch_latest_diff',
      'userId': userId,
      'latestRawJson': latestRawJson,
      'historyEntries': historyEntriesForIsolate,
      'mediaHistory': [],
    };

    try {
      final result = await _worker.run(payload);
      if (result is Map) {
        return result as Map<String, dynamic>;
      }
    } catch (e, s) {
      logger.e('Failed to fetch latest diff', error: e, stackTrace: s);
    }
    return null;
  }

  Future<FollowUserHistoryEntry?> getLatestHistoryEntry(
    String ownerId,
    String userId,
  ) async {
    // 简单查询，暂不涉及 RunID 复杂逻辑
    if (userId == ownerId) {
      return await (_db.select(_db.accountProfileHistory)
            ..where((tbl) => tbl.ownerId.equals(ownerId))
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.timestamp,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(1))
          .map(
            (e) => FollowUserHistoryEntry(
              id: e.id,
              ownerId: e.ownerId,
              userId: e.ownerId,
              reverseDiffJson: e.reverseDiffJson,
              timestamp: e.timestamp,
            ),
          )
          .getSingleOrNull();
    } else {
      return await (_db.select(_db.followUsersHistory)
            ..where(
              (tbl) => tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId),
            )
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.timestamp,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(1))
          .getSingleOrNull();
    }
  }

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
    String? filterField, // [新增]
  }) async {
    String? latestRawJson;
    int? currentStateTs; // 用于传递当前状态的时间锚点
    List<Map<String, dynamic>> historyEntriesForIsolate = [];

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
                  ]))
                .get();

        historyEntriesForIsolate = historyEntries.map((e) {
          return <String, dynamic>{
            'id': e.id,
            'ownerId': e.ownerId,
            'userId': e.ownerId,
            'reverseDiffJson': e.reverseDiffJson,
            'timestampMs': e.timestamp.millisecondsSinceEpoch,
            'runId': null, // Account history 暂无 RunID
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

      if (currentUser != null && latestRawJson != null) {
        // [修复] 获取当前状态的时间锚点
        final currentRunLog =
            await (_db.select(_db.syncLogs)
                  ..where((t) => t.runId.equals(currentUser.runId ?? '')))
                .getSingleOrNull();
        currentStateTs =
            currentRunLog?.timestamp.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;

        // [修复] 联表查询：提取 RunID 和 Log Timestamp
        final query =
            _db.select(_db.followUsersHistory).join([
                leftOuterJoin(
                  _db.syncLogs,
                  _db.syncLogs.runId.equalsExp(_db.followUsersHistory.runId),
                ),
              ])
              ..where(
                _db.followUsersHistory.ownerId.equals(ownerId) &
                    _db.followUsersHistory.userId.equals(userId),
              )
              ..orderBy([OrderingTerm.desc(_db.syncLogs.timestamp)]);

        final rows = await query.get();

        historyEntriesForIsolate = rows.map((row) {
          final e = row.readTable(_db.followUsersHistory);
          final log = row.readTableOrNull(_db.syncLogs);

          return <String, dynamic>{
            'id': e.id,
            'ownerId': e.ownerId,
            'userId': e.userId,
            'reverseDiffJson': e.reverseDiffJson,
            // [关键] 传递 RunID
            'runId': e.runId,
            // [关键] 优先使用 Log 时间
            'timestampMs':
                log?.timestamp.millisecondsSinceEpoch ??
                e.timestamp.millisecondsSinceEpoch,
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
      'currentStateTimestampMs': currentStateTs, // 传递给 Worker
      'historyEntries': historyEntriesForIsolate,
      'mediaHistory': mediaHistoryForIsolate,
      'page': page,
      'pageSize': pageSize,
      'filterField': filterField, // [新增]
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
        // [修复] 从 Worker 结果中提取 RunID
        final String? runId = itemMap['runId'] as String?;

        final Map<String, dynamic> userMap = Map<String, dynamic>.from(
          itemMap['userMap'] as Map,
        );

        final user = TwitterUser.fromJson(userMap);

        final originalData = originalEntryMap[entryId];
        if (originalData != null) {
          // Worker 已经返回了修正后的时间戳
          final int timestampMs = itemMap['timestampMs'] as int;

          final entry = FollowUserHistoryEntry(
            id: entryId,
            ownerId: ownerId,
            userId: userId,
            reverseDiffJson: diffJson,
            timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
            runId: runId, // [关键] 将 RunID 存入 Entry
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
