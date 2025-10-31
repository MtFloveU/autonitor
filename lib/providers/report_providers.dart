import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../models/cache_data.dart';
import '../models/twitter_user.dart';
import '../services/database.dart';
import '../main.dart';
import 'auth_provider.dart';
import '../repositories/analysis_report_repository.dart';

@immutable
class UserListParam {
  final String ownerId;
  final String categoryKey;
  const UserListParam({required this.ownerId, required this.categoryKey});
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserListParam &&
          runtimeType == other.runtimeType &&
          ownerId == other.ownerId &&
          categoryKey == other.categoryKey;
  @override
  int get hashCode => ownerId.hashCode ^ categoryKey.hashCode;
}

final cacheProvider = FutureProvider.autoDispose<CacheData?>((ref) async {
  final database = ref.watch(databaseProvider);
  final activeAccount = ref.watch(activeAccountProvider);
  if (activeAccount == null) {
    print("cacheProvider: No active account, returning null.");
    return null;
  }
  print(
    "cacheProvider: Fetching counts from database for account ${activeAccount.id}...",
  );
  try {
    // --- Corrected Drift GroupBy Query ---
    final changeTypeCol = database.changeReports.changeType;
    final countExp = changeTypeCol.count();

    // 1. 创建查询
    final query = database.selectOnly(database.changeReports)
      ..addColumns([changeTypeCol, countExp])
      ..where(database.changeReports.ownerId.equals(activeAccount.id));

    // 2. 应用 groupBy
    query.groupBy([changeTypeCol]);

    // 3. 获取结果
    final countsResult = await query.get();

    // 4. 读取结果
    final Map<String, int> categoryCounts = {
      for (var row in countsResult)
        row.read(changeTypeCol)!: row.read(countExp)!,
    };
    // --- Correction End ---

    print("cacheProvider: Fetched category counts: $categoryCounts");
    final accountDetails = await (database.select(
      database.loggedAccounts,
    )..where((tbl) => tbl.id.equals(activeAccount.id))).getSingleOrNull();
    return CacheData(
      accountId: activeAccount.id,
      accountName: activeAccount.name ?? 'N/A',
      lastUpdateTime: DateTime.now().toIso8601String(),
      followersCount: accountDetails?.followersCount ?? 0,
      followingCount: accountDetails?.followingCount ?? 0,
      unfollowedCount: categoryCounts['normal_unfollowed'] ?? 0,
      mutualUnfollowedCount: categoryCounts['mutual_unfollowed'] ?? 0,
      singleUnfollowedCount: categoryCounts['oneway_unfollowed'] ?? 0,
      frozenCount: categoryCounts['suspended'] ?? 0,
      deactivatedCount: categoryCounts['deactivated'] ?? 0,
      refollowedCount: categoryCounts['be_followed_back'] ?? 0,
      newFollowersCount: categoryCounts['new_followers_following'] ?? 0,
      temporarilyRestrictedCount: categoryCounts['temporarily_restricted'] ?? 0,
    );
  } catch (e, s) {
    print("cacheProvider: Error fetching counts from database: $e\n$s");
    return null;
  }
});

final userListProvider = FutureProvider.family
    .autoDispose<List<TwitterUser>, UserListParam>((ref, param) async {
      final repository= ref.watch(analysisReportRepositoryProvider);
      try {
        return await repository.getUsersForCategory(
          param.ownerId,
          param.categoryKey,
        );
      } catch (e) {
        print("userListProvider Error: $e");
        throw Exception('Failed to load user list');
      }
});