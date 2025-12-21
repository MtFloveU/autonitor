import 'dart:convert';
import 'package:drift/drift.dart';
import '../services/database.dart';
import '../models/twitter_user.dart';
import '../providers/search_provider.dart'; // Import for SearchParam & Enums

class SearchRepository {
  final AppDatabase _database;

  SearchRepository(this._database);

  /// Search users with complex filters down-pushed to SQL
  Future<List<TwitterUser>> searchUsersInContext(
    String ownerId,
    SearchParam param, {
    int? limit,
    int offset = 0,
  }) async {
    final cleanQuery = param.query.trim();

    final query = _database.select(_database.followUsers)
      ..where((t) {
        // 1. Base Owner Constraint
        Expression<bool> predicate = t.ownerId.equals(ownerId);

        // 2. Dynamic Field Search (Group OR)
        if (cleanQuery.isNotEmpty) {
          // [修复] 如果未选任何字段，默认搜索所有字段 (Empty Set -> All Fields)
          final Set<SearchField> effectiveFields = param.searchFields.isEmpty
              ? {SearchField.screenName, SearchField.name, SearchField.bio}
              : param.searchFields;

          final List<Expression<bool>> fieldExpressions = [];

          if (effectiveFields.contains(SearchField.restId)) {
            fieldExpressions.add(t.userId.equals(cleanQuery));
          }

          if (effectiveFields.contains(SearchField.screenName)) {
            fieldExpressions.add(
              t.screenName.lower().contains(cleanQuery.toLowerCase()),
            );
          }
          if (effectiveFields.contains(SearchField.name)) {
            fieldExpressions.add(
              t.name.lower().contains(cleanQuery.toLowerCase()),
            );
          }
          if (effectiveFields.contains(SearchField.bio)) {
            fieldExpressions.add(
              t.bio.lower().contains(cleanQuery.toLowerCase()),
            );
          }
          if (effectiveFields.contains(SearchField.location)) {
            final clean = cleanQuery.toLowerCase();
            fieldExpressions.add(
              t.latestRawJson.lower().like('%"location":"%$clean%"%'),
            );
          }
          if (effectiveFields.contains(SearchField.link)) {
            final clean = cleanQuery.toLowerCase();
            fieldExpressions.add(
              t.latestRawJson.lower().like('%"link":"%$clean%"%'),
            );
          }

          // 将所有字段条件用 OR 连接
          if (fieldExpressions.isNotEmpty) {
            predicate = predicate & fieldExpressions.reduce((a, b) => a | b);
          } else {
            // [防御性逻辑] 如果有查询词但无字段可搜 (理论上上面修复后不会进入)，
            // 强制返回 false (无结果)，而不是返回全部。
            predicate = predicate & const Constant(false);
          }
        }

        // 3. Relation Filters (Database Columns)
        if (param.isFollower != FilterState.all) {
          predicate =
              predicate &
              t.isFollower.equals(param.isFollower == FilterState.yes);
        }
        if (param.isFollowing != FilterState.all) {
          predicate =
              predicate &
              t.isFollowing.equals(param.isFollowing == FilterState.yes);
        }

        // 4. JSON Attribute Filters (LIKE Mocking)

        // Verified
        if (param.isVerified != FilterState.all) {
          final bool target = param.isVerified == FilterState.yes;
          predicate =
              predicate & t.latestRawJson.like('%"is_verified":$target%');
        }

        // Protected
        if (param.isProtected != FilterState.all) {
          final bool target = param.isProtected == FilterState.yes;
          // Note: JSON key might be "protected" or "is_protected" depending on API/Model
          // Using both checks via OR if schema is uncertain, or assume standard 'protected'
          // Based on Account model, it maps 'protected'.
          predicate =
              predicate & t.latestRawJson.like('%"is_protected":$target%');
        }

        // 5. Status Filters
        // ... (inside searchUsersInContext)

        // 5. Status Filters
        if (param.statuses.isNotEmpty) {
          final List<Expression<bool>> statusExprs = [];

          for (final s in param.statuses) {
            if (s == AccountStatus.normal) {
              // [修复 1] Normal 用户可能是 "status":"normal" 也可能是 "status":null
              // 务必同时匹配这两种情况
              statusExprs.add(t.latestRawJson.like('%"status":"normal"%'));
              statusExprs.add(t.latestRawJson.like('%"status":null%'));
            } else if (s == AccountStatus.temporarilyRestricted) {
              // [修复 2] 暂时受限存储在 'kept_ids_status' 字段，而非 'status'
              statusExprs.add(
                t.latestRawJson.like(
                  '%"kept_ids_status":"temporarily_restricted"%',
                ),
              );
              statusExprs.add(
                t.latestRawJson.like('%"status":"temporarily_restricted"%'),
              );
            } else {
              // Suspended / Deactivated 正常存储在 'status' 字段
              // 枚举名转字符串: AccountStatus.suspended -> "suspended"
              final statusStr = s.name;
              statusExprs.add(t.latestRawJson.like('%"status":"$statusStr"%'));
            }
          }

          // 将所有状态条件用 OR 连接 (只要满足其中一种状态即可)
          if (statusExprs.isNotEmpty) {
            predicate = predicate & statusExprs.reduce((a, b) => a | b);
          }
        }

        return predicate;
      });

    // 6. Deterministic Ordering
    query.orderBy([(t) => OrderingTerm(expression: t.userId)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    final results = await query.get();

    if (results.isEmpty) return [];

    final List<TwitterUser> users = [];
    for (final match in results) {
      TwitterUser? user;
      if (match.latestRawJson != null) {
        try {
          user = TwitterUser.fromJson(jsonDecode(match.latestRawJson!));
          user = user.copyWith(
            avatarLocalPath: match.avatarLocalPath,
            bannerLocalPath: match.bannerLocalPath,
          );
        } catch (_) {}
      }

      user ??= TwitterUser(
        restId: match.userId,
        screenName: match.screenName,
        name: match.name,
        avatarUrl: match.avatarUrl,
        avatarLocalPath: match.avatarLocalPath,
        bannerLocalPath: match.bannerLocalPath,
        bio: match.bio,
        isFollower: match.isFollower,
        isFollowing: match.isFollowing,
        isVerified: false,
      );

      users.add(user);
    }

    return users;
  }
}
