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

class HistoryRepository {
  final AppDatabase _db;
  final HistoryRebuildWorker _worker;

  HistoryRepository(this._db, this._worker);

  Future<List<HistorySnapshot>> getFilteredHistory(
    String ownerId,
    String userId,
    AppSettings settings,
  ) async {
    String? latestRawJson;
    // 统一存储提取出的历史条目数据 (ID 和 时间戳)
    List<Map<String, dynamic>> historyEntriesForIsolate = [];

    // [新增] 1. 判断是否为主账号，分流查询
    if (userId == ownerId) {
      // --- 主账号逻辑 ---
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
          };
        }).toList();
      }
    } else {
      // --- 普通用户逻辑 (保持原有逻辑框架) ---
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

    if (latestRawJson == null) {
      return [];
    }

    // [保持不变] 获取媒体历史
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
      'latestRawJson': latestRawJson, // 使用动态获取的 json
      'historyEntries': historyEntriesForIsolate, // 使用动态获取的列表
      'mediaHistory': mediaHistoryForIsolate,
    };

    dynamic rawResult;
    try {
      rawResult = await _worker.run(payload);
    } catch (e, s) {
      logger.e('HistoryRepository: worker.run failed', error: e, stackTrace: s);
      return [];
    }

    if (rawResult == null || rawResult is! List) {
      return [];
    }

    // [优化] 2. 建立查找表：ID -> Timestamp (毫秒)
    // 这比原来的 entryById 更通用，也比 firstWhere 更快更安全
    final Map<int, int> timestampMap = {
      for (var e in historyEntriesForIsolate)
        e['id'] as int: e['timestampMs'] as int,
    };

    final List<HistorySnapshot> snapshots = [];

    for (final rawItem in rawResult) {
      try {
        if (rawItem is! Map) continue;

        final itemMap = rawItem as Map<String, dynamic>;
        final int entryId = itemMap['entryId'] as int;
        final String fullJson = itemMap['fullJson'] as String;
        final Map<String, dynamic> userMap = Map<String, dynamic>.from(
          itemMap['userMap'] as Map,
        );

        final user = TwitterUser.fromJson(userMap);

        // [修复] 3. 通过 Map 查找时间戳，避免了 firstWhere 崩溃
        final int? timestampMs = timestampMap[entryId];

        if (timestampMs != null) {
          // 构造一个 Entry 对象用于 UI 显示 (UI 只需 ID 和 Timestamp)
          // 即使是主账号，这里构造 FollowUserHistoryEntry 也是兼容的，因为 UI 并不关心底层表类型
          final entry = FollowUserHistoryEntry(
            id: entryId,
            ownerId: ownerId,
            userId: userId,
            reverseDiffJson: '', // UI 不展示 diff 内容，留空即可
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

    return snapshots;
  }
}
