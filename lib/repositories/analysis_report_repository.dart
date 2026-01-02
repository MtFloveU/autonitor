import 'package:autonitor/providers/json_worker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../services/database.dart';
import '../models/twitter_user.dart';
import '../main.dart';
import 'dart:convert';
import 'package:autonitor/services/log_service.dart';
import '../utils/json_parse_worker.dart';

// [Subclass] 携带快照数据，同时保留完整的 TwitterUser 功能
class ProfileSnapshotUser extends TwitterUser {
  final String jsonSnapshot;

  ProfileSnapshotUser({
    required TwitterUser original,
    required this.jsonSnapshot,
  }) : super(
         restId: original.restId,
         screenName: original.screenName,
         name: original.name,
         avatarUrl: original.avatarUrl,
         avatarLocalPath: original.avatarLocalPath,
         bannerUrl: original.bannerUrl,
         bannerLocalPath: original.bannerLocalPath,
         bio: original.bio,
         bioLinks: original.bioLinks,
         location: original.location,
         pinnedTweetIdStr: original.pinnedTweetIdStr,
         parodyCommentaryFanLabel: original.parodyCommentaryFanLabel,
         birthdateYear: original.birthdateYear,
         birthdateMonth: original.birthdateMonth,
         birthdateDay: original.birthdateDay,
         automatedScreenName: original.automatedScreenName,
         joinedTime: original.joinedTime,
         link: original.link,
         status: original.status,
         keptIdsStatus: original.keptIdsStatus,
         isVerified: original.isVerified,
         isProtected: original.isProtected,
         followersCount: original.followersCount,
         followingCount: original.followingCount,
         statusesCount: original.statusesCount,
         listedCount: original.listedCount,
         favouritesCount: original.favouritesCount,
         mediaCount: original.mediaCount,
         isFollowing: original.isFollowing,
         isFollower: original.isFollower,
         canDm: original.canDm,
         canMediaTag: original.canMediaTag,
       );
}

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

  /// [新增] 获取指定类别的用户总数，用于计算分页
  Future<int> getUserCountForCategory(
    String ownerId,
    String categoryKey,
  ) async {
    if (categoryKey == 'followers' || categoryKey == 'following') {
      final bool isFollower = (categoryKey == 'followers');
      final countExp = _database.followUsers.userId.count();

      // [修复] 将 'normal' 状态过滤移至数据库查询层
      // 这样计算的总数才是实际显示的数量
      final query = _database.selectOnly(_database.followUsers)
        ..addColumns([countExp])
        ..where(
          _database.followUsers.ownerId.equals(ownerId) &
              (isFollower
                  ? _database.followUsers.isFollower.equals(true)
                  : _database.followUsers.isFollowing.equals(true)) &
              (_database.followUsers.followerSort.isNotNull() |
                  _database.followUsers.followingSort.isNotNull()),
        );
      final result = await query.getSingle();
      return result.read(countExp) ?? 0;
    } else {
      final countExp = _database.changeReports.id.count();
      final query = _database.selectOnly(_database.changeReports)
        ..addColumns([countExp])
        ..where(
          _database.changeReports.ownerId.equals(ownerId) &
              _database.changeReports.changeType.equals(categoryKey),
        );
      final result = await query.getSingle();
      return result.read(countExp) ?? 0;
    }
  }

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

        // [修复] 将 'normal' 状态过滤移至数据库查询层
        // 确保 fetch 的 limit 条数都是有效数据，避免因为内存过滤导致分页数据量不足
        final query = _database.select(_database.followUsers)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                (isFollower
                    ? tbl.isFollower.equals(true)
                    : tbl.isFollowing.equals(true)) &
                (tbl.followerSort.isNotNull() | tbl.followingSort.isNotNull()),
          );

        if (isFollower) {
          query.orderBy([
            (t) => OrderingTerm(
              expression: t.followerSort,
              mode: OrderingMode.asc,
            ),
          ]);
        } else {
          query.orderBy([
            (t) => OrderingTerm(
              expression: t.followingSort,
              mode: OrderingMode.asc,
            ),
          ]);
        }

        final followUsers = await (query..limit(limit, offset: offset)).get();

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
        // 其他报告类型按时间倒序
        final reportQuery = _database.select(_database.changeReports)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                tbl.changeType.equals(categoryKey),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]);

        final reportResults = await (reportQuery..limit(limit, offset: offset))
            .get();

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
          // [核心修改] 针对 profile_update 构建包含完整用户数据的复合 JSON
          if (categoryKey == 'profile_update') {
            final user = userMap[report.userId];

            Map<String, dynamic> diffMap = {};
            if (report.userSnapshotJson != null &&
                report.userSnapshotJson!.isNotEmpty) {
              try {
                diffMap = jsonDecode(report.userSnapshotJson!);
              } catch (e) {
                logger.w("Failed to decode snapshot json: $e");
              }
            }

            // [重要] 尝试获取完整的 User JSON
            // 这样我们构建的 baseUser 就是完整的，拥有 isVerified, isProtected 等所有字段
            Map<String, dynamic> fullUserMap = {};
            if (user?.latestRawJson != null) {
              try {
                fullUserMap = jsonDecode(user!.latestRawJson!);
              } catch (_) {}
            } else {
              // 降级：如果数据库没有该用户记录（极少见），构造最小集合
              fullUserMap = {
                'rest_id': report.userId,
                'name': user?.name ?? 'Unknown',
                'screen_name': user?.screenName ?? 'unknown',
                'avatar_url': user?.avatarUrl,
              };
            }

            // 构造复合 JSON：Diff + Full User + Timestamp
            final Map<String, dynamic> compositeJson = {
              'diff': diffMap['diff'] ?? diffMap,
              'user': fullUserMap, // 放入完整 Map
              'timestamp': report.timestamp.toIso8601String(),
            };

            paramsList.add(
              ParseParams(
                userId: report.userId,
                // 这里传入复合 JSON
                jsonString: jsonEncode(compositeJson),
                // 传入 DB 路径以便在主线程解析时注入
                dbAvatarLocalPath: user?.avatarLocalPath,
                dbBannerLocalPath: user?.bannerLocalPath,
              ),
            );
            continue;
          }

          // 其他类型报告的处理...
          if (report.userSnapshotJson != null &&
              report.userSnapshotJson!.isNotEmpty) {
            paramsList.add(
              ParseParams(
                userId: report.userId,
                jsonString: report.userSnapshotJson,
                dbAvatarLocalPath: userMap[report.userId]?.avatarLocalPath,
                dbBannerLocalPath: userMap[report.userId]?.bannerLocalPath,
              ),
            );
          } else {
            final user = userMap[report.userId];
            if (user != null) {
              paramsList.add(
                ParseParams(
                  userId: user.userId,
                  jsonString: user.latestRawJson,
                  dbAvatarLocalPath: user.avatarLocalPath,
                  dbBannerLocalPath: user.bannerLocalPath,
                ),
              );
            } else {
              paramsList.add(
                ParseParams(userId: report.userId, dbName: 'Unknown'),
              );
            }
          }
        }
      }

      List<TwitterUser> parsedUsers = [];

      if (categoryKey == 'profile_update') {
        for (var p in paramsList) {
          try {
            // 1. 解析复合 JSON
            final compositeData = jsonDecode(p.jsonString ?? '{}');

            // 2. 提取完整的 user map
            final userMap =
                compositeData['user'] as Map<String, dynamic>? ?? {};

            // 3. 注入本地路径（如果 Map 里没有但 params 里有）
            if (p.dbAvatarLocalPath != null) {
              userMap['avatar_local_path'] = p.dbAvatarLocalPath;
            }
            if (p.dbBannerLocalPath != null) {
              userMap['banner_local_path'] = p.dbBannerLocalPath;
            }

            // 4. 使用 TwitterUser.fromJson 进行**完整**解析
            final baseUser = TwitterUser.fromJson(userMap);

            parsedUsers.add(
              ProfileSnapshotUser(
                original: baseUser,
                jsonSnapshot: p.jsonString ?? '{}',
              ),
            );
          } catch (e) {
            logger.e(
              "Error constructing ProfileSnapshotUser for ${p.userId}: $e",
            );
            parsedUsers.add(
              ProfileSnapshotUser(
                original: TwitterUser(restId: p.userId, screenName: 'Error'),
                jsonSnapshot: '{}',
              ),
            );
          }
        }
      } else {
        // 标准 Worker 解析逻辑
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

        try {
          final parsedMaps = await _worker.parseBatch(items);
          for (int i = 0; i < parsedMaps.length; i++) {
            parsedUsers.add(TwitterUser.fromJson(parsedMaps[i]));
          }
        } catch (e) {
          logger.w("Worker parsing failed: $e");
          parsedUsers = paramsList
              .map((p) => parseFollowUserToTwitterUser(p))
              .toList();
        }
      }

      // [修复] 移除内存过滤，因为已经在 DB 层过滤了
      // if (categoryKey == 'followers' || categoryKey == 'following') {
      //   return parsedUsers.where((u) => u.status == 'normal').toList();
      // }

      return parsedUsers;
    } catch (e, s) {
      logger.e(
        "Error in getUsersForCategory '$categoryKey'",
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
        "AnalysisReportRepository (fallback): Error parsing JSON for user ${params.userId}",
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
