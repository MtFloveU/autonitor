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
    final currentUser =
        await (_db.select(_db.followUsers)..where(
              (tbl) => tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId),
            ))
            .getSingleOrNull();

    if (currentUser == null || currentUser.latestRawJson == null) {
      return [];
    }

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

    final mediaHistory =
        await (_db.select(_db.mediaHistory)..orderBy([
              (tbl) =>
                  OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
            ]))
            .get();

    // 转换为纯 Map 传递给 Worker
    final historyEntriesForIsolate = historyEntries.map((e) {
      return <String, dynamic>{
        'id': e.id,
        'ownerId': e.ownerId,
        'userId': e.userId,
        'reverseDiffJson': e.reverseDiffJson,
        'timestampMs': e.timestamp.millisecondsSinceEpoch,
      };
    }).toList();

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
      'latestRawJson': currentUser.latestRawJson!,
      'historyEntries': historyEntriesForIsolate,
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

    // 建立查找表，用于将 ID 映射回数据库对象
    final Map<int, FollowUserHistoryEntry> entryById = {
      for (var e in historyEntries) e.id: e,
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

        final dbEntry = entryById[entryId];
        if (dbEntry == null) continue;

        // 在主线程重建 TwitterUser 对象 (这里使用 JSON 构造最稳妥)
        final user = TwitterUser.fromJson(userMap);

        snapshots.add(
          HistorySnapshot(entry: dbEntry, user: user, fullJson: fullJson),
        );
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
