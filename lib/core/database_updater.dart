import 'dart:convert';
import 'package:autonitor/models/twitter_user.dart';
import 'package:autonitor/utils/runid_generator.dart';
import 'package:flutter/foundation.dart';
import 'media_processor.dart';
import 'network_data_fetcher.dart';
import 'relationship_analyzer.dart';
import 'package:drift/drift.dart';
import '../services/database.dart';
import '../utils/diff_utils.dart';
import '../services/image_history_service.dart';

typedef LogCallback = void Function(String message);

class DatabaseUpdater {
  final AppDatabase _database;
  final LogCallback _log;

  DatabaseUpdater({required AppDatabase database, required LogCallback log})
    : _database = database,
      _log = log;

  Future<void> insertSyncLog({
    required String ownerId,
    required int status,
    required DateTime timestamp,
  }) async {
    final runId = generateRunId();

    await _database
        .into(_database.syncLogs)
        .insert(
          SyncLogsCompanion.insert(
            runId: runId,
            ownerId: Value(ownerId), // 在这里将 String 包装为 Value<String>
            timestamp: timestamp,
            status: status,
          ),
        );
    _log("Sync log recorded: $runId, status: $status");
  }

  Future<void> saveChanges({
    required String ownerId,
    required NetworkFetchResult networkData,
    required RelationshipAnalysisResult analysisResult,
    required MediaProcessingResult mediaResult,
    required Map<String, FollowUser> oldRelationsMap,
  }) async {
    _log("Preparing database data in background isolate...");

    // [核心修改] 将繁重的 JSON 序列化和 Diff 计算移至后台 Isolate
    final prepResult = await compute(
      _prepareDatabaseData,
      _PrepareDataParams(
        ownerId: ownerId,
        networkData: networkData,
        analysisResult: analysisResult,
        mediaResult: mediaResult,
        oldRelationsMap: oldRelationsMap,
        categorizedRemovals: analysisResult.categorizedRemovals,
        keptUserStatusUpdates: analysisResult.keptUserStatusUpdates,
      ),
    );

    _log("Background preparation done. Writing to database...");

    // 4. Run Database Transaction (在主线程执行写入)
    await _database.transaction(() async {
      if (prepResult.companionsToUpsert.isNotEmpty) {
        await _database.batchUpsertNetworkRelationships(
          prepResult.companionsToUpsert,
        );
        _log(
          "Upserted ${prepResult.companionsToUpsert.length} relationships into NetworkRelationships.",
        );
      }

      if (prepResult.historyToInsert.isNotEmpty) {
        await _database.batchInsertFollowUsersHistory(
          prepResult.historyToInsert,
        );
        _log(
          "Inserted ${prepResult.historyToInsert.length} profile history records.",
        );
      }

      // ChangeReports 已经在 analyzer 中生成好了，直接写入
      await _database.replaceChangeReport(ownerId, analysisResult.reports);
      _log(
        "Replaced ChangeReport with ${analysisResult.reports.length} new entries.",
      );
    });
  }
}

// --- 辅助类：用于传递参数给 compute ---
class _PrepareDataParams {
  final String ownerId;
  final NetworkFetchResult networkData;
  final RelationshipAnalysisResult analysisResult;
  final MediaProcessingResult mediaResult;
  final Map<String, FollowUser> oldRelationsMap;
  final Map<String, String> categorizedRemovals;
  final Map<String, String> keptUserStatusUpdates;

  _PrepareDataParams({
    required this.categorizedRemovals,
    required this.ownerId,
    required this.networkData,
    required this.analysisResult,
    required this.mediaResult,
    required this.oldRelationsMap,
    required this.keptUserStatusUpdates,
  });
}

// --- 辅助类：用于返回结果 ---
class _PrepareDataResult {
  final List<FollowUsersCompanion> companionsToUpsert;
  final List<FollowUsersHistoryCompanion> historyToInsert;
  final Map<String, String> categorizedRemovals;
  final Map<String, String> keptUserStatusUpdates;

  _PrepareDataResult({
    required this.companionsToUpsert,
    required this.historyToInsert,
    required this.categorizedRemovals,
    required this.keptUserStatusUpdates,
  });
}

// --- 顶层函数：在后台 Isolate 运行 ---
// 所有的 CPU 密集型操作（JSON 序列化、Diff 计算）都在这里
_PrepareDataResult _prepareDatabaseData(_PrepareDataParams params) {
  final List<FollowUsersHistoryCompanion> historyToInsert = [];
  final List<FollowUsersCompanion> companionsToUpsert = [];

  // [新增] 1. 构建索引映射，以便根据 API 返回顺序进行 O(1) 查找
  // params.networkData.followerIds/followingIds (LinkedHashSet) 保留了插入顺序（即 API 返回顺序）
  final Map<String, int> followerIndexMap = {
    for (var i = 0; i < params.networkData.followerIds.length; i++)
      params.networkData.followerIds.elementAt(i): i,
  };

  final Map<String, int> followingIndexMap = {
    for (var i = 0; i < params.networkData.followingIds.length; i++)
      params.networkData.followingIds.elementAt(i): i,
  };

  // 2. 构建统一的“待更新用户”集合
  final Map<String, TwitterUser> allUsersToUpdate = {};

  // A. 添加网络获取的活跃用户
  allUsersToUpdate.addAll(params.networkData.uniqueUsers);

  // B. 添加被移除的用户
  for (final removedId in params.categorizedRemovals.keys) {
    final oldRel = params.oldRelationsMap[removedId];
    if (oldRel != null) {
      TwitterUser userObj;
      try {
        if (oldRel.latestRawJson != null) {
          userObj = TwitterUser.fromJson(jsonDecode(oldRel.latestRawJson!));
        } else {
          userObj = TwitterUser(
            restId: removedId,
            screenName: oldRel.screenName,
            name: oldRel.name,
          );
        }
      } catch (_) {
        userObj = TwitterUser(
          restId: removedId,
          screenName: oldRel.screenName,
          name: oldRel.name,
        );
      }

      final status = params.categorizedRemovals[removedId];
      if (status == 'suspended' || status == 'deactivated') {
        userObj = userObj.copyWith(
          status: status,
          isFollowing: oldRel.isFollowing,
          isFollower: oldRel.isFollower,
        );
      } else {
        userObj = userObj.copyWith(
          status: status,
          isFollowing: false,
          isFollower: false,
        );
      }

      allUsersToUpdate[removedId] = userObj;
    }
  }

  // 3. 统一遍历处理
  for (final userId in allUsersToUpdate.keys) {
    var newUserObj = allUsersToUpdate[userId]!;
    final oldRelation = params.oldRelationsMap[userId];

    if (params.keptUserStatusUpdates.containsKey(userId)) {
      newUserObj = newUserObj.copyWith(
        keptIdsStatus: params.keptUserStatusUpdates[userId],
      );
    }

    // [新增] 确定排序索引
    final int? fSort = followerIndexMap[userId];
    final int? fingSort = followingIndexMap[userId];

    // --- A. JSON 序列化 & 历史记录 (Diff) ---
    final newJsonString = jsonEncode(newUserObj.toJson());

    if (oldRelation != null) {
      final oldJsonString = oldRelation.latestRawJson;
      final diffString = calculateReverseDiff(newJsonString, oldJsonString);

      if (diffString != null && diffString.isNotEmpty) {
        historyToInsert.add(
          FollowUsersHistoryCompanion(
            ownerId: Value(params.ownerId),
            userId: Value(userId),
            reverseDiffJson: Value(diffString),
            timestamp: Value(DateTime.now()),
          ),
        );
      }
    }

    // --- B. 路径合并逻辑 ---
    final downloadedAvatar =
        params.mediaResult.downloadedPaths[userId]?[MediaType.avatar];
    final downloadedBanner =
        params.mediaResult.downloadedPaths[userId]?[MediaType.banner];

    String? finalAvatarPath = downloadedAvatar;
    if (finalAvatarPath == null &&
        oldRelation?.avatarUrl == newUserObj.avatarUrl) {
      finalAvatarPath = oldRelation?.avatarLocalPath;
    }

    String? finalBannerPath = downloadedBanner;
    if (finalBannerPath == null &&
        oldRelation?.bannerUrl == newUserObj.bannerUrl) {
      finalBannerPath = oldRelation?.bannerLocalPath;
    }

    // --- C. 构建 Companion ---
    companionsToUpsert.add(
      FollowUsersCompanion(
        ownerId: Value(params.ownerId),
        userId: Value(userId),
        name: Value(newUserObj.name),
        screenName: Value(newUserObj.screenName),
        avatarUrl: Value(newUserObj.avatarUrl),
        bannerUrl: Value(newUserObj.bannerUrl),
        bio: Value(newUserObj.bio),
        latestRawJson: Value(newJsonString),
        isFollower: Value(newUserObj.isFollower),
        isFollowing: Value(newUserObj.isFollowing),
        avatarLocalPath: finalAvatarPath == null
            ? const Value.absent()
            : Value(finalAvatarPath),
        bannerLocalPath: finalBannerPath == null
            ? const Value.absent()
            : Value(finalBannerPath),
        // [新增] 保存排序字段
        followerSort: Value(fSort),
        followingSort: Value(fingSort),
      ),
    );
  }

  return _PrepareDataResult(
    companionsToUpsert: companionsToUpsert,
    historyToInsert: historyToInsert,
    categorizedRemovals: params.categorizedRemovals,
    keptUserStatusUpdates: params.keptUserStatusUpdates,
  );
}
