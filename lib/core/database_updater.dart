import 'dart:convert';
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

  DatabaseUpdater({
    required AppDatabase database,
    required LogCallback log,
  })  : _database = database,
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
      ),
    );

    _log("Background preparation done. Writing to database...");

    // 4. Run Database Transaction (在主线程执行写入，这通常很快)
    await _database.transaction(() async {
      if (analysisResult.removedIds.isNotEmpty) {
        await _database.deleteNetworkRelationships(
          ownerId,
          analysisResult.removedIds.toList(),
        );
        _log(
          "Deleted ${analysisResult.removedIds.length} relationships from NetworkRelationships.",
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
        await _database.batchInsertFollowUsersHistory(prepResult.historyToInsert);
        _log("Inserted ${prepResult.historyToInsert.length} profile history records.");
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

  _PrepareDataParams({
    required this.ownerId,
    required this.networkData,
    required this.analysisResult,
    required this.mediaResult,
    required this.oldRelationsMap,
  });
}

// --- 辅助类：用于返回结果 ---
class _PrepareDataResult {
  final List<FollowUsersCompanion> companionsToUpsert;
  final List<FollowUsersHistoryCompanion> historyToInsert;

  _PrepareDataResult({
    required this.companionsToUpsert,
    required this.historyToInsert,
  });
}

// --- 顶层函数：在后台 Isolate 运行 ---
// 所有的 CPU 密集型操作（JSON 序列化、Diff 计算）都在这里
_PrepareDataResult _prepareDatabaseData(_PrepareDataParams params) {
  final List<FollowUsersHistoryCompanion> historyToInsert = [];
  final List<FollowUsersCompanion> companionsToUpsertRaw = [];

  // 1. Prepare JSON History Diffs
  for (final userId in params.analysisResult.keptIds) {
    final oldRelation = params.oldRelationsMap[userId];
    final newUserObj = params.networkData.uniqueUsers[userId];

    if (oldRelation != null && newUserObj != null) {
      final oldJsonString = oldRelation.latestRawJson;
      
      // [CPU 密集] 序列化
      final newJsonString = jsonEncode(newUserObj.toJson());
      
      // [CPU 密集] Diff 计算
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
  }

  // 2. Prepare User Companions (Initial)
  for (final userId in params.networkData.uniqueUsers.keys) {
    final userObj = params.networkData.uniqueUsers[userId]!;
    
    companionsToUpsertRaw.add(
      FollowUsersCompanion(
        ownerId: Value(params.ownerId),
        userId: Value(userId),
        name: Value(userObj.name),
        screenName: Value(userObj.screenName),
        avatarUrl: Value(userObj.avatarUrl),
        bannerUrl: Value(userObj.bannerUrl),
        bio: Value(userObj.bio),
        // [CPU 密集] 序列化
        latestRawJson: Value(jsonEncode(userObj.toJson())),
        isFollower: Value(params.networkData.followerIds.contains(userId)),
        isFollowing: Value(params.networkData.followingIds.contains(userId)),
        // 初始路径设为 absent，稍后合并
        avatarLocalPath: const Value.absent(),
        bannerLocalPath: const Value.absent(),
      ),
    );
  }

  // 3. Merge Downloaded Paths (Logic Logic)
  final List<FollowUsersCompanion> finalCompanions = [];
  for (final companion in companionsToUpsertRaw) {
    final userId = companion.userId.value;
    final oldRelation = params.oldRelationsMap[userId];

    final downloadedAvatar =
        params.mediaResult.downloadedPaths[userId]?[MediaType.avatar];
    final downloadedBanner =
        params.mediaResult.downloadedPaths[userId]?[MediaType.banner];

    String? finalAvatarPath = downloadedAvatar;
    if (finalAvatarPath == null &&
        oldRelation?.avatarUrl == companion.avatarUrl.value) {
      finalAvatarPath = oldRelation?.avatarLocalPath;
    }

    String? finalBannerPath = downloadedBanner;
    if (finalBannerPath == null &&
        oldRelation?.bannerUrl == companion.bannerUrl.value) {
      finalBannerPath = oldRelation?.bannerLocalPath;
    }

    finalCompanions.add(
      companion.copyWith(
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
    companionsToUpsert: finalCompanions,
    historyToInsert: historyToInsert,
  );
}