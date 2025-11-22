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

  // ... (getUsersForCategory 方法保持不变) ...
  Future<List<TwitterUser>> getUsersForCategory(
    String ownerId,
    String categoryKey, {
    required int limit,
    required int offset,
  }) async {
    // ... (保持原有的查询和分页逻辑不变) ...
    // 代码省略，与你提供的原文件一致
    logger.i(
      "AnalysisReportRepository: Getting users for category '$categoryKey' for owner '$ownerId' (Limit: $limit, Offset: $offset)...",
    );
    try {
      List<ParseParams> paramsList = [];

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
      } else {
        final reportQuery = _database.select(_database.changeReports)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                tbl.changeType.equals(categoryKey),
          );

        final reportResults = await (reportQuery..limit(limit, offset: offset))
            .get();

        if (reportResults.isEmpty) return [];

        final userIds = reportResults.map((r) => r.userId).toList();

        final usersQuery = _database.select(_database.followUsers)
          ..where(
            (tbl) => tbl.ownerId.equals(ownerId) & tbl.userId.isIn(userIds),
          );

        final userResults = await usersQuery.get();

        final userMap = {for (var u in userResults) u.userId: u};

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

      return await compute(parseListInCompute, paramsList);
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

// --- 顶层辅助类和函数 ---

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

/// 核心修改：使用 TwitterUser.fromJson 进行解析，并合并本地路径
TwitterUser parseFollowUserToTwitterUser(ParseParams params) {
  // 1. 优先尝试解析标准化的 JSON
  if (params.jsonString != null && params.jsonString!.isNotEmpty) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(params.jsonString!);

      // 2. 关键步骤：将数据库中的本地文件路径合并到 Map 中
      // 因为 DatabaseUpdater 存入 JSON 时对象可能还没包含下载后的路径
      // 而数据库列 (follow_users.avatar_local_path) 是文件系统的 Source of Truth
      if (params.dbAvatarLocalPath != null) {
        jsonMap['avatar_local_path'] = params.dbAvatarLocalPath;
      }
      if (params.dbBannerLocalPath != null) {
        jsonMap['banner_local_path'] = params.dbBannerLocalPath;
      }

      // 3. 直接使用 fromJson (它已经包含了所有字段类型转换逻辑)
      return TwitterUser.fromJson(jsonMap);
    } catch (e, s) {
      logger.e(
        "AnalysisReportRepository (compute): Error parsing standardized JSON for user ${params.userId}",
        error: e,
        stackTrace: s,
      );
      // 如果解析失败，降级到下方的 fallback
    }
  }

  // 4. Fallback: 如果 JSON 缺失或损坏，使用 ParseParams 中的数据库列构建最小可用对象
  return TwitterUser(
    restId: params.userId,
    screenName: params.dbScreenName,
    name: params.dbName,
    avatarUrl: params.dbAvatarUrl,
    avatarLocalPath: params.dbAvatarLocalPath,
    bannerLocalPath: params.dbBannerLocalPath,
    bio: params.dbBio,
    // 其他字段将使用 TwitterUser 构造函数的默认值 (0, false, null)
  );
}
