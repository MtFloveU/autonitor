import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../services/database.dart';
import '../models/twitter_user.dart';
import '../main.dart';
import 'dart:convert';

final analysisReportRepositoryProvider =
    Provider<AnalysisReportRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AnalysisReportRepository(db);
});

class AnalysisReportRepository {
  final AppDatabase _database;

  AnalysisReportRepository(this._database);

Future<List<TwitterUser>> getUsersForCategory(
    String ownerId,
    String categoryKey,
  ) async {
    print(
      "AnalysisReportRepository: Getting users for category '$categoryKey' for owner '$ownerId'...",
    );
    try {
      List<TwitterUser> twitterUsers = [];

      // 逻辑 1: 获取 'followers' / 'following' (当前状态)
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
        final followUsers = await query.get();
        print(
          "AnalysisReportRepository: Fetched ${followUsers.length} users directly from FollowUsers for '$categoryKey'.",
        );

        // 解析 FollowUsers 记录
        for (final followUser in followUsers) {
          twitterUsers.add(
            _parseFollowUserToTwitterUser(
              followUser.userId,
              followUser.screenName,
              followUser.name,
              followUser.avatarUrl,
              followUser.bio,
              followUser.latestRawJson,
            ),
          );
        }
      }
      // 逻辑 2: 获取所有其他差异列表 (历史快照)
      else {
        final reportQuery = _database.select(_database.changeReports)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                tbl.changeType.equals(categoryKey),
          );
        final reportResults = await reportQuery.get();
        print(
          "AnalysisReportRepository: Fetched ${reportResults.length} user snapshots from ChangeReport for '$categoryKey'.",
        );

        if (reportResults.isEmpty) {
          return [];
        }

        // --- 修正：直接从 reportResults 解析快照 ---
        for (final report in reportResults) {
          if (report.userSnapshotJson == null ||
              report.userSnapshotJson!.isEmpty) {
            print(
              "AnalysisReportRepository: Warning - No snapshot JSON found for user ${report.userId} in category $categoryKey",
            );
            continue;
          }
          // 使用辅助方法从快照 JSON 中解析 TwitterUser
          twitterUsers.add(
            _parseFollowUserToTwitterUser(
              report.userId,
              null, // dbScreenName (从 JSON 解析)
              null, // dbName (从 JSON 解析)
              null, // dbAvatarUrl (从 JSON 解析)
              null, // dbBio (从 JSON 解析)
              report.userSnapshotJson, // 传入快照 JSON
            ),
          );
        }
        // --- 修正结束 ---
      }
      return twitterUsers;
    } catch (e, s) {
      print(
        "AnalysisReportRepository: Error in getUsersForCategory '$categoryKey': $e\n$s",
      );
      throw Exception('Failed to load user list: $e');
    }
  }

  // --- 新增：统一的 API 1.1 JSON 解析辅助方法 ---
  TwitterUser _parseFollowUserToTwitterUser(
    String userId,
    String? dbScreenName,
    String? dbName,
    String? dbAvatarUrl,
    String? dbBio,
    String? jsonString,
  ) {
    // 默认值（来自 FollowUsers 表的缓存）
    String? screenName = dbScreenName;
    String? name = dbName;
    String? avatarUrl = dbAvatarUrl;
    String? bio = dbBio;
    String? location, link, joinTime, bannerUrl;
    int followersCount = 0,
        followingCount = 0,
        statusesCount = 0,
        mediaCount = 0,
        favouritesCount = 0,
        listedCount = 0;

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;

        // 覆盖或填充来自 JSON 的数据
        name = parsedJson['name'] as String? ?? name;
        screenName = parsedJson['screen_name'] as String? ?? screenName;
        avatarUrl =
            parsedJson['profile_image_url_https'] as String? ?? avatarUrl;
        bio = parsedJson['description'] as String? ?? bio;
        location = parsedJson['location'] as String?;
        joinTime = parsedJson['created_at'] as String?;
        bannerUrl = parsedJson['profile_banner_url'] as String?;
        followersCount = parsedJson['followers_count'] as int? ?? 0;
        followingCount =
            parsedJson['friends_count'] as int? ??
            0; // API 1.1 使用 friends_count
        statusesCount = parsedJson['statuses_count'] as int? ?? 0;
        mediaCount = parsedJson['media_count'] as int? ?? 0;
        favouritesCount = parsedJson['favourites_count'] as int? ?? 0;
        listedCount = parsedJson['listed_count'] as int? ?? 0;

        // --- 实现：API 1.1 expanded_url 逻辑 ---
        link = parsedJson['url'] as String?; // 默认 t.co 链接
        final entities = parsedJson['entities'] as Map<String, dynamic>?;
        final urlBlock = entities?['url'] as Map<String, dynamic>?;
        final urlsList = urlBlock?['urls'] as List<dynamic>?;
        if (link != null && urlsList != null && urlsList.isNotEmpty) {
          // 遍历 'urls' 列表
          for (final item in urlsList) {
            final urlMap = item as Map<String, dynamic>?;
            // 找到与 'url' (t.co) 匹配的条目
            if (urlMap != null && urlMap['url'] == link) {
              link = urlMap['expanded_url'] as String?; // 替换为 expanded_url
              break;
            }
          }
        }
        // --- 实现结束 ---

        // --- 实现：_400x400 替换 ---
        if (avatarUrl != null) {
          avatarUrl = avatarUrl.replaceFirst('_normal', '_400x400');
        }
        // --- 实现结束 ---
      } catch (e) {
        print("AnalysisReportRepository: Error parsing rawJson for user $userId: $e");
        // 即使解析失败，也继续使用数据库中的缓存数据
      }
    }

    return TwitterUser(
      restId: userId,
      id: screenName ?? userId, // handle
      name: name ?? 'Unknown Name',
      avatarUrl: avatarUrl ?? '',
      bio: bio,
      location: location,
      link: link,
      joinTime: joinTime ?? '', // <-- 修复：添加 '?? ''' 来处理 null
      bannerUrl: bannerUrl,
      followersCount: followersCount,
      followingCount: followingCount,
      statusesCount: statusesCount,
      mediaCount: mediaCount ?? 0,
      favouritesCount: favouritesCount,
      listedCount: listedCount,
      latestRawJson: jsonString,
    );
  }
  // --- We will move getUsersForCategory and 
  // --- _parseFollowUserToTwitterUser here in the next step ---

}