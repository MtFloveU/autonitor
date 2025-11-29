// lib/repositories/analysis_report_repository.dart
import 'package:autonitor/providers/json_worker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../services/database.dart';
import '../models/twitter_user.dart';
import '../main.dart';
import 'dart:convert';
import 'package:autonitor/services/log_service.dart';
import '../utils/json_parse_worker.dart';

final analysisReportRepositoryProvider = Provider<AnalysisReportRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final worker = ref.watch(jsonParseWorkerProvider);
  return AnalysisReportRepository(db, worker);
});

class AnalysisReportRepository {
  final AppDatabase _database;
  final JsonParseWorker _worker;

  AnalysisReportRepository(this._database, this._worker);

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

        logger.i(
          "AnalysisReportRepository: Fetched ${reportResults.length} user snapshots from ChangeReport for '$categoryKey'.",
        );

        if (reportResults.isEmpty) {
          return [];
        }

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

      final items = paramsList.map((p) {
        return {
          'userId': p.userId,
          'dbScreenName': p.dbScreenName,
          'dbName': p.dbName,
          'dbAvatarUrl': p.dbAvatarUrl,
          'dbAvatarLocalPath': p.dbAvatarLocalPath,
          'dbBannerLocalPath': p.dbBannerLocalPath,
          'dbBio': p.dbBio,
          'jsonString': p.jsonString ?? '',
        };
      }).toList();

      List<TwitterUser> parsedUsers;
      try {
        final parsedMaps = await _worker.parseBatch(items);
        parsedUsers = parsedMaps.map((m) => TwitterUser.fromJson(m)).toList();
      } catch (e) {
        parsedUsers = paramsList
            .map((p) => parseFollowUserToTwitterUser(p))
            .toList();
      }

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
