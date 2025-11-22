import 'dart:convert';
import 'package:autonitor/models/twitter_user.dart';
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

  Future<void> saveChanges({
    required String ownerId,
    required NetworkFetchResult networkData,
    required RelationshipAnalysisResult analysisResult,
    required MediaProcessingResult mediaResult,
    required Map<String, FollowUser> oldRelationsMap,
  }) async {
    _log("Preparing database data in background isolate...");

    // [核心修改] 将繁重的 JSON 序列化和 Diff 计算移至后台 Isolate
    // 我们创建一个 Map 传递参数，因为 compute 只能传递一个参数
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

    // 4. Run Database Transaction (在主线程执行写入，这通常很快)
    await _database.transaction(() async {
      if (prepResult.companionsToUpsert.isNotEmpty) {
        await _database.batchUpsertNetworkRelationships(
          prepResult.companionsToUpsert,
        );
        _log(
          "Upserted ${prepResult.companionsToUpsert.length} relationships into NetworkRelationships.",
        );
      }

      if (prepResult.companionsToUpsert.isNotEmpty) {
        // Drift 的 batch insert 性能很好
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

  // 1. 构建统一的“待更新用户”集合
  // 这里的 Key 是 UserId, Value 是 TwitterUser 对象
  final Map<String, TwitterUser> allUsersToUpdate = {};

  // A. 添加网络获取的活跃用户 (状态默认为空或 active)
  allUsersToUpdate.addAll(params.networkData.uniqueUsers);

  // B. 添加被移除的用户 (设置特定的 status)
  // 这些用户不在 networkData 里，我们需要从 oldRelationsMap 恢复并打上标记
  for (final removedId in params.categorizedRemovals.keys) {
    final oldRel = params.oldRelationsMap[removedId];
    if (oldRel != null) {
      // 尝试从旧 JSON 恢复对象，如果失败则创建一个基础对象
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

      // [关键] 更新状态，并标记为非关注/非粉丝
      // 这样它就变成了和普通用户一样的 TwitterUser 对象
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

  // 2. 统一遍历处理 (Diff 计算 + Companion 构建)
  for (final userId in allUsersToUpdate.keys) {
    var newUserObj = allUsersToUpdate[userId]!;
    final oldRelation = params.oldRelationsMap[userId];

    if (params.keptUserStatusUpdates.containsKey(userId)) {
      newUserObj = newUserObj.copyWith(
        keptIdsStatus: params.keptUserStatusUpdates[userId],
      );
    }

    // --- A. JSON 序列化 & 历史记录 (Diff) ---
    // 序列化新的对象 (包含 status)
    final newJsonString = jsonEncode(newUserObj.toJson());

    // 只有当用户依然存在于 KeptIds (即活跃用户) 时，我们才通常记录详细的 Profile History
    // 但如果你希望连 "Removed" 状态的改变也记录进历史，这里就不需要 if 判断
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
    // 统一处理本地路径，无论是活跃用户下载的新图，还是移除用户保留的旧图
    final downloadedAvatar =
        params.mediaResult.downloadedPaths[userId]?[MediaType.avatar];
    final downloadedBanner =
        params.mediaResult.downloadedPaths[userId]?[MediaType.banner];

    String? finalAvatarPath = downloadedAvatar;
    // 如果没有新下载，且 URL 没变 (或者这是个被移除的用户)，保留旧路径
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
        // 存入带有 status 的最新 JSON
        latestRawJson: Value(newJsonString),
        isFollower: Value(newUserObj.isFollower),
        isFollowing: Value(newUserObj.isFollowing),
        avatarLocalPath: finalAvatarPath == null
            ? const Value.absent()
            : Value(finalAvatarPath),
        bannerLocalPath: finalBannerPath == null
            ? const Value.absent()
            : Value(finalBannerPath),
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
