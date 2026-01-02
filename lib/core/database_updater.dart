import 'dart:convert';
import 'package:autonitor/services/image_history_service.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import 'package:autonitor/models/twitter_user.dart';
import 'package:autonitor/core/media_processor.dart';
import 'package:autonitor/core/network_data_fetcher.dart';
import 'package:autonitor/core/relationship_analyzer.dart';

import '../services/database.dart';
import '../utils/diff_utils.dart';

class DatabaseUpdater {
  final AppDatabase _database;

  DatabaseUpdater({required AppDatabase database}) : _database = database;

  // 同步日志（保持原有接口）
  Future<void> insertSyncLog({
    required String runId,
    required String ownerId,
    required int status,
    required DateTime timestamp,
  }) async {
    await _database
        .into(_database.syncLogs)
        .insert(
          SyncLogsCompanion.insert(
            runId: runId,
            ownerId: Value(ownerId),
            timestamp: timestamp,
            status: status,
          ),
        );
  }

  /// 主入口：保存变化（runId 的实际写入在后面统一做）
  Future<void> saveChanges({
    required String ownerId,
    required NetworkFetchResult networkData,
    required RelationshipAnalysisResult analysisResult,
    required MediaProcessingResult mediaResult,
    required Map<String, FollowUser> oldRelationsMap,
    required String currentRunId,
  }) async {
    // 在 isolate 中准备数据（包含 changedUserIds）
    final prepResult = await compute(
      _prepareDatabaseData,
      _PrepareDataParams(
        ownerId: ownerId,
        networkData: networkData,
        analysisResult: analysisResult,
        mediaResult: mediaResult,
        oldRelationsMap: oldRelationsMap,
        currentRunId: currentRunId,
      ),
    );

    // 在同一事务内完成所有写入操作，并最后统一 update run_id 给 changedUserIds
    await _database.transaction(() async {
      if (prepResult.companionsToUpsert.isNotEmpty) {
        await _database.batchUpsertNetworkRelationships(
          prepResult.companionsToUpsert,
        );
      }

      if (prepResult.historyToInsert.isNotEmpty) {
        await _database.batchInsertFollowUsersHistory(
          prepResult.historyToInsert,
        );
      }

      await _database.replaceChangeReport(ownerId, analysisResult.reports);

      // 最后一步：统一根据 history 收集到的 changedUserIds 打 runId
      if (prepResult.changedUserIds.isNotEmpty) {
        await _updateRunIdForUsers(
          ownerId: ownerId,
          userIds: prepResult.changedUserIds.toList(),
          runId: currentRunId,
        );
      }
    });
  }

  // 使用 customStatement 批量更新 run_id（分块以防参数过多）
  Future<void> _updateRunIdForUsers({
    required String ownerId,
    required List<String> userIds,
    required String runId,
  }) async {
    const int chunkSize = 200; // 安全分块大小（可调整）
    for (var i = 0; i < userIds.length; i += chunkSize) {
      final chunk = userIds.sublist(
        i,
        (i + chunkSize) > userIds.length ? userIds.length : (i + chunkSize),
      );

      final placeholders = List.filled(chunk.length, '?').join(', ');
      final sql =
          'UPDATE follow_users SET run_id = ? WHERE owner_id = ? AND user_id IN ($placeholders)';
      final vars = <Object?>[runId, ownerId] + chunk;
      await _database.customStatement(sql, vars);
    }
  }
}

// ---------------------------------------------------------------------------
// Isolate 参数 / 返回类型
// ---------------------------------------------------------------------------

class _PrepareDataParams {
  final String ownerId;
  final NetworkFetchResult networkData;
  final RelationshipAnalysisResult analysisResult;
  final MediaProcessingResult mediaResult;
  final Map<String, FollowUser> oldRelationsMap;
  final String currentRunId;

  _PrepareDataParams({
    required this.ownerId,
    required this.networkData,
    required this.analysisResult,
    required this.mediaResult,
    required this.oldRelationsMap,
    required this.currentRunId,
  });
}

class _PrepareDataResult {
  final List<FollowUsersCompanion> companionsToUpsert;
  final List<FollowUsersHistoryCompanion> historyToInsert;
  final Set<String> changedUserIds;

  _PrepareDataResult({
    required this.companionsToUpsert,
    required this.historyToInsert,
    required this.changedUserIds,
  });
}

// ---------------------------------------------------------------------------
// 后台 isolate：准备数据（计算 diff、构建 companions、收集 changedUserIds）
// ---------------------------------------------------------------------------

_PrepareDataResult _prepareDatabaseData(_PrepareDataParams params) {
  final List<FollowUsersCompanion> companionsToUpsert = [];
  final List<FollowUsersHistoryCompanion> historyToInsert = [];
  final Set<String> changedUserIds = {};

  // follower / following 排序索引（API 返回顺序）
  final Map<String, int> followerIndexMap = {
    for (var i = 0; i < params.networkData.followerIds.length; i++)
      params.networkData.followerIds.elementAt(i): i,
  };

  final Map<String, int> followingIndexMap = {
    for (var i = 0; i < params.networkData.followingIds.length; i++)
      params.networkData.followingIds.elementAt(i): i,
  };

  // 构建统一用户集合（包括网络返回用户）
  final Map<String, TwitterUser> allUsers = {};
  allUsers.addAll(params.networkData.uniqueUsers);

  // 添加被移除 / categorizedRemovals 的用户（保持原来旧逻辑）
  for (final id in params.analysisResult.categorizedRemovals.keys) {
    final oldRel = params.oldRelationsMap[id];
    if (oldRel == null) continue;

    TwitterUser user;
    try {
      user = oldRel.latestRawJson != null
          ? TwitterUser.fromJson(jsonDecode(oldRel.latestRawJson!))
          : TwitterUser(
              restId: id,
              screenName: oldRel.screenName,
              name: oldRel.name,
            );
    } catch (_) {
      user = TwitterUser(
        restId: id,
        screenName: oldRel.screenName,
        name: oldRel.name,
      );
    }

    final status = params.analysisResult.categorizedRemovals[id];
    if (status == 'suspended' || status == 'deactivated') {
      user = user.copyWith(
        status: status,
        isFollowing: oldRel.isFollowing,
        isFollower: oldRel.isFollower,
      );
    } else {
      user = user.copyWith(
        status: status,
        isFollowing: false,
        isFollower: false,
      );
    }

    allUsers[id] = user;
  }

  // -------------------------------------------------------------------------
  // 主处理循环：计算 diff、收集 changedUserIds、构建 companions / history
  // -------------------------------------------------------------------------
  for (final id in allUsers.keys) {
    final newUser = allUsers[id]!;
    final oldRel = params.oldRelationsMap[id];

    final newJson = jsonEncode(newUser.toJson());
    final diff = oldRel != null
        ? calculateReverseDiff(newJson, oldRel.latestRawJson)
        : null;

    // dataChanged：显式只与语义变化相关（不包含 media/localPath）
    final bool dataChanged =
        oldRel == null ||
        (diff != null && diff.isNotEmpty) ||
        oldRel.isFollowing != newUser.isFollowing ||
        oldRel.isFollower != newUser.isFollower;

    final bool sortChanged =
        oldRel != null &&
        (oldRel.followerSort != followerIndexMap[id] ||
            oldRel.followingSort != followingIndexMap[id]);

    // 1) 什么都没变：跳过
    if (!dataChanged && !sortChanged) {
      continue;
    }

    // 2) 如果 dataChanged 为 true，则这是“语义变化”，将 userId 收入 changedUserIds
    if (dataChanged) {
      changedUserIds.add(id);
    }

    // 3) 如果仅为排序变化（不影响 runId），我们仍需要最小化更新（只写排序）
    if (!dataChanged && sortChanged) {
      companionsToUpsert.add(
        FollowUsersCompanion(
          ownerId: Value(params.ownerId),
          userId: Value(id),
          followerSort: Value(followerIndexMap[id]),
          followingSort: Value(followingIndexMap[id]),
        ),
      );
      continue;
    }

    // 4) dataChanged == true：构建完整的 companion，并写 history（历史记录的 runId 保存 oldRel.runId）
    if (dataChanged) {
      if (oldRel != null) {
        final diffString = diff ?? '';
        if (diffString.isNotEmpty) {
          historyToInsert.add(
            FollowUsersHistoryCompanion(
              ownerId: Value(params.ownerId),
              userId: Value(id),
              reverseDiffJson: Value(diffString),
              timestamp: Value(DateTime.now()),
              runId: Value(oldRel.runId),
            ),
          );
        }
      }

      // media（旧逻辑：路径复用）
      final downloadedAvatar =
          params.mediaResult.downloadedPaths[id]?[MediaType.avatar];
      final downloadedBanner =
          params.mediaResult.downloadedPaths[id]?[MediaType.banner];

      String? finalAvatarPath = downloadedAvatar;
      if (finalAvatarPath == null && oldRel?.avatarUrl == newUser.avatarUrl) {
        finalAvatarPath = oldRel?.avatarLocalPath;
      }

      String? finalBannerPath = downloadedBanner;
      if (finalBannerPath == null && oldRel?.bannerUrl == newUser.bannerUrl) {
        finalBannerPath = oldRel?.bannerLocalPath;
      }

      companionsToUpsert.add(
        FollowUsersCompanion(
          ownerId: Value(params.ownerId),
          userId: Value(id),
          name: Value(newUser.name),
          screenName: Value(newUser.screenName),
          avatarUrl: Value(newUser.avatarUrl),
          bannerUrl: Value(newUser.bannerUrl),
          bio: Value(newUser.bio),
          latestRawJson: Value(newJson),
          isFollower: Value(newUser.isFollower),
          isFollowing: Value(newUser.isFollowing),
          followerSort: Value(followerIndexMap[id]),
          followingSort: Value(followingIndexMap[id]),
          avatarLocalPath: finalAvatarPath == null
              ? const Value.absent()
              : Value(finalAvatarPath),
          bannerLocalPath: finalBannerPath == null
              ? const Value.absent()
              : Value(finalBannerPath),
          // 注意：此处**不写 runId**（由统一步骤写入）
        ),
      );
    }
  }

  return _PrepareDataResult(
    companionsToUpsert: companionsToUpsert,
    historyToInsert: historyToInsert,
    changedUserIds: changedUserIds,
  );
}
