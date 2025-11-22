// lib/repositories/analysis_report_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../services/database.dart';
import '../models/twitter_user.dart';
import '../main.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:autonitor/services/log_service.dart';

final analysisReportRepositoryProvider = Provider<AnalysisReportRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return AnalysisReportRepository(db);
});

class AnalysisReportRepository {
  final AppDatabase _database;

  AnalysisReportRepository(this._database);

  Future<List<TwitterUser>> getUsersForCategory(
    String ownerId,
    String categoryKey, {
    required int limit,
    required int offset,
  }) async {
    logger.i(
      "AnalysisReportRepository: Getting users for category '$categoryKey' for owner '$ownerId' (Limit: $limit, Offset: $offset)...",
    );
    try {
      List<ParseParams> paramsList = [];

      // 逻辑 1: 关注者/正在关注 (直接查 FollowUsers)
      if (categoryKey == 'followers' || categoryKey == 'following') {
        final bool isFollower = (categoryKey == 'followers');
        final query = _database.select(_database.followUsers)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                (isFollower
                    ? tbl.isFollower.equals(true)
                    : tbl.isFollowing.equals(true)),
          );

        final followUsers = await (query..limit(limit, offset: offset)).get();

        logger.i(
          "AnalysisReportRepository: Fetched ${followUsers.length} users.",
        );

        paramsList = followUsers
            .map(
              (user) => ParseParams(
                userId: user.userId,
                dbScreenName: user.screenName,
                dbName: user.name,
                dbAvatarUrl: user.avatarUrl,
                dbAvatarLocalPath: user.avatarLocalPath,
                dbBannerLocalPath: user.bannerLocalPath,
                dbBio: user.bio,
                jsonString: user.latestRawJson,
              ),
            )
            .toList();
      } 
      // 逻辑 2: 其他分类 (先查 ChangeReports，再反查 FollowUsers)
      else {
        final reportQuery = _database.select(_database.changeReports)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                tbl.changeType.equals(categoryKey),
          );

        final reportResults = await (reportQuery..limit(limit, offset: offset))
            .get();

        logger.i(
          "AnalysisReportRepository: Fetched ${reportResults.length} user snapshots from ChangeReport for '$categoryKey'.",
        );

        if (reportResults.isEmpty) {
          return []; 
        }

        final userIds = reportResults.map((r) => r.userId).toList();

        // 关键：去 followUsers 表查询最新数据（此时包含 Removed 用户）
        final usersQuery = _database.select(_database.followUsers)
          ..where(
            (tbl) => tbl.ownerId.equals(ownerId) & tbl.userId.isIn(userIds),
          );

        final userResults = await usersQuery.get();

        // 创建 Map 方便匹配
        final userMap = {for (var u in userResults) u.userId: u};

        // 保持 Report 的顺序组装结果
        for (var report in reportResults) {
          final user = userMap[report.userId];
          if (user != null) {
            paramsList.add(
              ParseParams(
                userId: user.userId,
                dbScreenName: user.screenName,
                dbName: user.name,
                dbAvatarUrl: user.avatarUrl,
                dbAvatarLocalPath: user.avatarLocalPath,
                dbBannerLocalPath: user.bannerLocalPath,
                dbBio: user.bio,
                jsonString: user.latestRawJson,
              ),
            );
          } else {
            logger.w(
              "User ${report.userId} found in ChangeReport but not in followUsers table.",
            );
          }
        }
      }

      // [解析步骤]
      final List<TwitterUser> parsedUsers = await compute(parseListInCompute, paramsList);

      // [过滤逻辑] 仅在 "关注/粉丝" 列表隐藏非 normal 用户
      // 其他列表（如 Suspended, Deactivated）不受影响，依然显示所有状态
      if (categoryKey == 'followers' || categoryKey == 'following') {
        return parsedUsers.where((u) => u.status == 'normal').toList();
      }

      return parsedUsers;

    } catch (e, s) {
      logger.e(
        "AnalysisReportRepository: Error in getUsersForCategory '$categoryKey'",
        error: e,
        stackTrace: s,
      );
      throw Exception('Failed to load user list: $e');
    }
  }
}

// --- 辅助类和函数 (解析逻辑，包含我们之前修复的本地路径注入) ---

class ParseParams {
  final String userId;
  final String? dbScreenName;
  final String? dbName;
  final String? dbAvatarUrl;
  final String? dbAvatarLocalPath;
  final String? dbBannerLocalPath;
  final String? dbBio;
  final String? jsonString;

  ParseParams({
    required this.userId,
    this.dbScreenName,
    this.dbName,
    this.dbAvatarUrl,
    this.dbAvatarLocalPath,
    this.dbBannerLocalPath,
    this.dbBio,
    this.jsonString,
  });
}

List<TwitterUser> parseListInCompute(List<ParseParams> paramsList) {
  return paramsList
      .map((params) => parseFollowUserToTwitterUser(params))
      .toList();
}

TwitterUser parseFollowUserToTwitterUser(ParseParams params) {
  if (params.jsonString != null && params.jsonString!.isNotEmpty) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(params.jsonString!);

      // [关键] 注入本地路径 (使用 snake_case)
      if (params.dbAvatarLocalPath != null) {
        jsonMap['avatar_local_path'] = params.dbAvatarLocalPath;
      }
      if (params.dbBannerLocalPath != null) {
        jsonMap['banner_local_path'] = params.dbBannerLocalPath;
      }

      return TwitterUser.fromJson(jsonMap);
    } catch (e, s) {
      logger.e(
        "AnalysisReportRepository (compute): Error parsing standardized JSON for user ${params.userId}",
        error: e,
        stackTrace: s,
      );
    }
  }

  // Fallback: 仅当 JSON 损坏时使用数据库列构建最小对象
  return TwitterUser(
    restId: params.userId,
    screenName: params.dbScreenName,
    name: params.dbName,
    avatarUrl: params.dbAvatarUrl,
    avatarLocalPath: params.dbAvatarLocalPath,
    bannerLocalPath: params.dbBannerLocalPath,
    bio: params.dbBio,
  );
}