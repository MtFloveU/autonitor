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
      List<_ParseParams> paramsList = [];

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

        // --- 修改：应用分页 ---
        final followUsers = await (query..limit(limit, offset: offset)).get();

        logger.i(
          "AnalysisReportRepository: Fetched ${followUsers.length} users.",
        );

        paramsList = followUsers
            .map(
              (user) => _ParseParams(
                userId: user.userId,
                dbScreenName: user.screenName,
                dbName: user.name,
                dbAvatarUrl: user.avatarUrl,
                dbBio: user.bio,
                jsonString: user.latestRawJson,
              ),
            )
            .toList();
      }
      // 逻辑 2: 获取所有其他差异列表 (历史快照)
      else {
        final reportQuery = _database.select(_database.changeReports)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                tbl.changeType.equals(categoryKey),
          );

        // --- 修改：应用分页 ---
        final reportResults = await (reportQuery..limit(limit, offset: offset))
            .get();

        logger.i(
          "AnalysisReportRepository: Fetched ${reportResults.length} user snapshots from ChangeReport for '$categoryKey'.",
        );

        if (reportResults.isEmpty) {
          return [];
        }

        paramsList = reportResults
            .map(
              (report) => _ParseParams(
                userId: report.userId,
                jsonString: report.userSnapshotJson,
              ),
            )
            .toList();
      }

      return await compute(_parseListInCompute, paramsList);
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

// --- 顶层辅助类和函数 (保持不变) ---

class _ParseParams {
  final String userId;
  final String? dbScreenName;
  final String? dbName;
  final String? dbAvatarUrl;
  final String? dbBio;
  final String? jsonString;

  _ParseParams({
    required this.userId,
    this.dbScreenName,
    this.dbName,
    this.dbAvatarUrl,
    this.dbBio,
    this.jsonString,
  });
}

List<TwitterUser> _parseListInCompute(List<_ParseParams> paramsList) {
  return paramsList
      .map((params) => _parseFollowUserToTwitterUser(params))
      .toList();
}

TwitterUser _parseFollowUserToTwitterUser(_ParseParams params) {
  String? screenName = params.dbScreenName;
  String? name = params.dbName;
  String? avatarUrl = params.dbAvatarUrl;
  String? bio = params.dbBio;
  String? location, link, joinTime, bannerUrl;
  int followersCount = 0,
      followingCount = 0,
      statusesCount = 0,
      mediaCount = 0,
      favouritesCount = 0,
      listedCount = 0;
  bool isVerified = false;
  bool isProtected = false;

  if (params.jsonString != null && params.jsonString!.isNotEmpty) {
    try {
      final parsedJson = jsonDecode(params.jsonString!) as Map<String, dynamic>;

      name = parsedJson['name'] as String? ?? name;
      screenName = parsedJson['screen_name'] as String? ?? screenName;
      avatarUrl = parsedJson['profile_image_url_https'] as String? ?? avatarUrl;
      bio = parsedJson['description'] as String? ?? bio;
      location = parsedJson['location'] as String?;
      joinTime = parsedJson['created_at'] as String?;
      bannerUrl = parsedJson['profile_banner_url'] as String?;
      followersCount = parsedJson['followers_count'] as int? ?? 0;
      followingCount =
          parsedJson['friends_count'] as int? ?? 0; // API 1.1 使用 friends_count
      statusesCount = parsedJson['statuses_count'] as int? ?? 0;
      mediaCount = parsedJson['media_count'] as int? ?? 0;
      favouritesCount = parsedJson['favourites_count'] as int? ?? 0;
      listedCount = parsedJson['listed_count'] as int? ?? 0;
      isProtected = parsedJson['protected'] as bool? ?? false;
      isVerified = parsedJson['ext_is_blue_verified'] as bool? ?? false;

      link = parsedJson['url'] as String?; // 默认 t.co 链接
      final entities = parsedJson['entities'] as Map<String, dynamic>?;
      final urlBlock = entities?['url'] as Map<String, dynamic>?;
      final urlsList = urlBlock?['urls'] as List<dynamic>?;
      if (link != null && urlsList != null && urlsList.isNotEmpty) {
        for (final item in urlsList) {
          final urlMap = item as Map<String, dynamic>?;
          if (urlMap != null && urlMap['url'] == link) {
            link = urlMap['expanded_url'] as String?; // 替换为 expanded_url
            break;
          }
        }
      }

      if (avatarUrl != null) {
        avatarUrl = avatarUrl.replaceFirst('_normal', '_400x400');
      }
    } catch (e, s) {
      logger.e(
        "AnalysisReportRepository (compute): Error parsing rawJson for user ${params.userId}",
        error: e,
        stackTrace: s,
      );
    }
  }

  return TwitterUser(
    restId: params.userId,
    id: screenName ?? params.userId, // handle
    name: name ?? 'Unknown Name',
    avatarUrl: avatarUrl ?? '',
    bio: bio,
    location: location,
    link: link,
    joinTime: joinTime ?? '',
    bannerUrl: bannerUrl,
    followersCount: followersCount,
    followingCount: followingCount,
    statusesCount: statusesCount,
    mediaCount: mediaCount,
    favouritesCount: favouritesCount,
    listedCount: listedCount,
    latestRawJson: params.jsonString,
    isVerified: isVerified,
    isProtected: isProtected,
  );
}
