import 'dart:convert';
import 'package:drift/drift.dart';
import '../services/database.dart';
import '../models/twitter_user.dart';
import '../services/log_service.dart';

class SearchRepository {
  final AppDatabase _database;

  SearchRepository(this._database);

  /// 在当前账号(ownerId)的上下文中查找用户 (关注者/正在关注/自己)
  Future<TwitterUser?> searchUserInContext(String ownerId, String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    // 1. 在当前账号的关注/粉丝列表 (FollowUsers) 中查找
    final followMatch =
        await (_database.select(_database.followUsers)
              ..where((t) {
                // 确保 ownerId 约束同时也作用于 screenName/userId
                return t.ownerId.equals(ownerId) &
                    (t.userId.equals(cleanQuery) |
                        t.screenName.lower().equals(cleanQuery.toLowerCase()));
              })
              ..limit(1))
            .getSingleOrNull();

    // 如果在关注列表中找到了，且不是自己，直接返回
    if (followMatch != null && followMatch.userId != ownerId) {
      if (followMatch.latestRawJson != null) {
        try {
          final user = TwitterUser.fromJson(
            jsonDecode(followMatch.latestRawJson!),
          );
          return user.copyWith(
            avatarLocalPath: followMatch.avatarLocalPath,
            bannerLocalPath: followMatch.bannerLocalPath,
          );
        } catch (e) {
          logger.w("Failed to parse JSON for user ${followMatch.userId}: $e");
        }
      }
      return TwitterUser(
        restId: followMatch.userId,
        screenName: followMatch.screenName,
        name: followMatch.name,
        avatarUrl: followMatch.avatarUrl,
        avatarLocalPath: followMatch.avatarLocalPath,
        bannerUrl: followMatch.bannerUrl,
        bannerLocalPath: followMatch.bannerLocalPath,
        bio: followMatch.bio,
        isFollowing: followMatch.isFollowing,
        isFollower: followMatch.isFollower,
      );
    }

    // 2. 检查是否是当前登录账号自己 (LoggedAccounts)
    if (cleanQuery == ownerId ||
        (followMatch != null && followMatch.userId == ownerId)) {
      return _fetchSelfFromDB(ownerId);
    }

    // 按 screen_name 查找当前账号
    final accountMatch =
        await (_database.select(_database.loggedAccounts)
              ..where(
                (t) =>
                    t.id.equals(ownerId) &
                    t.screenName.lower().equals(cleanQuery.toLowerCase()),
              )
              ..limit(1))
            .getSingleOrNull();

    if (accountMatch != null) {
      return _fetchSelfFromDB(ownerId);
    }

    return null;
  }

  Future<TwitterUser?> _fetchSelfFromDB(String id) async {
    final account = await (_database.select(
      _database.loggedAccounts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (account == null) return null;

    if (account.latestRawJson != null) {
      try {
        final user = TwitterUser.fromJson(jsonDecode(account.latestRawJson!));
        return user.copyWith(
          avatarLocalPath: account.avatarLocalPath,
          bannerLocalPath: account.bannerLocalPath,
        );
      } catch (_) {}
    }
    return TwitterUser(
      restId: account.id,
      screenName: account.screenName,
      name: account.name,
      avatarUrl: account.avatarUrl,
      avatarLocalPath: account.avatarLocalPath,
      bannerUrl: account.bannerUrl,
      bannerLocalPath: account.bannerLocalPath,
      bio: account.bio,
      isVerified: account.isVerified ?? false,
      isProtected: account.isProtected ?? false,
    );
  }
}
