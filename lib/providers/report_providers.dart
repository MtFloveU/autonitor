import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../models/cache_data.dart';
import '../models/twitter_user.dart';
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

// --- START OF PAGINATION REFACTOR ---
// (分页重构开始)

const int _kUserListPageSize = 30; // 每次加载 30 条

// 1. The Notifier class
// This class will manage the state for a *single* user list (one family instance)
class UserListNotifier
    extends FamilyAsyncNotifier<List<TwitterUser>, UserListParam> {
  // This will store the list of users *outside* the AsyncValue state
  // to make pagination easier.
  final List<TwitterUser> _users = [];

  // Track if we have fetched *all* users
  bool _hasMore = true;

  // The 'build' method is called to get the *initial* state (first page)
  @override
  Future<List<TwitterUser>> build(UserListParam arg) async {
    // 'arg' is the UserListParam (ownerId, categoryKey)

    // Reset state for this family instance
    _users.clear();
    _hasMore = true;

    // Fetch the first page
    final repository = ref.read(analysisReportRepositoryProvider);
    final newUsers = await repository.getUsersForCategory(
      arg.ownerId,
      arg.categoryKey,
      limit: _kUserListPageSize,
      offset: 0,
    );

    _users.addAll(newUsers);

    // If we fetched fewer users than the page size, we've reached the end
    if (newUsers.length < _kUserListPageSize) {
      _hasMore = false;
    }

    return _users;
  }

  // 2. The method to fetch the next page
  Future<void> fetchMore() async {
    // Don't fetch if we're already loading or if there are no more pages
    if (state.isLoading || !_hasMore) {
      return;
    }

    // Set state to loading (while keeping existing data)
    state = const AsyncLoading<List<TwitterUser>>().copyWithPrevious(state);

    // Get parameters and repository
    final repository = ref.read(analysisReportRepositoryProvider);
    final arg = this.arg; // 'this.arg' gives access to the family parameter

    try {
      // Calculate the next offset
      final offset = _users.length;

      // Fetch the next page
      final newUsers = await repository.getUsersForCategory(
        arg.ownerId,
        arg.categoryKey,
        limit: _kUserListPageSize,
        offset: offset,
      );

      // If we got no new users, or fewer than the limit, we're done
      if (newUsers.isEmpty || newUsers.length < _kUserListPageSize) {
        _hasMore = false;
      }

      // Add new users to the list
      _users.addAll(newUsers);

      // Set state to data (with the new combined list)
      state = AsyncData(_users);
    } catch (e, s) {
      // In fetchMore's catch block
      state = AsyncValue<List<TwitterUser>>.error(e, s).copyWithPrevious(state);
    }
  }

  // 3. A helper to check if there is more data
  bool hasMore() {
    return _hasMore;
  }
}

// 4. The new provider definition
final userListProvider =
    AsyncNotifierProvider.family<
      UserListNotifier,
      List<TwitterUser>,
      UserListParam
    >(() {
      return UserListNotifier();
    });
