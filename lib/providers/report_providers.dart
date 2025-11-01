import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../models/cache_data.dart';
import '../models/twitter_user.dart';
import '../main.dart';
import 'auth_provider.dart';
import '../repositories/analysis_report_repository.dart';
import 'package:autonitor/services/log_service.dart';

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
    logger.i("cacheProvider: No active account, returning null.");
    return null;
  }

  try {
    final changeTypeCol = database.changeReports.changeType;
    final countExp = changeTypeCol.count();

    final query = database.selectOnly(database.changeReports)
      ..addColumns([changeTypeCol, countExp])
      ..where(database.changeReports.ownerId.equals(activeAccount.id));

    query.groupBy([changeTypeCol]);

    final countsResult = await query.get();
    logger.i(
      "cacheProvider: Fetching counts from database for account ${activeAccount.id}...",
    );

    final Map<String, int> categoryCounts = {
      for (var row in countsResult)
        row.read(changeTypeCol)!: row.read(countExp)!,
    };

    logger.i("cacheProvider: Fetched category counts: $categoryCounts");

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
    logger.e("cacheProvider: Error fetching counts from database: $e\n$s");
    return null;
  }
});

const int _kUserListPageSize = 30;

class UserListNotifier
    extends FamilyAsyncNotifier<List<TwitterUser>, UserListParam> {
  final List<TwitterUser> _users = [];
  bool _hasMore = true;

  @override
  Future<List<TwitterUser>> build(UserListParam arg) async {
    _users.clear();
    _hasMore = true;

    final repository = ref.read(analysisReportRepositoryProvider);
    final newUsers = await repository.getUsersForCategory(
      arg.ownerId,
      arg.categoryKey,
      limit: _kUserListPageSize,
      offset: 0,
    );
    logger.i(
      "UserListNotifier: build() called for owner ${arg.ownerId}, category ${arg.categoryKey}",
    );
    _users.addAll(newUsers);

    if (newUsers.length < _kUserListPageSize) {
      _hasMore = false;
    }

    logger.i(
      "UserListNotifier: build() completed, loaded ${_users.length} users, hasMore=$_hasMore",
    );

    return _users;
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !_hasMore) {
      logger.i(
        "UserListNotifier: fetchMore() skipped, isLoading=${state.isLoading}, hasMore=$_hasMore",
      );
      return;
    }

    logger.i(
      "UserListNotifier: fetchMore() started, current users=${_users.length}",
    );

    state = const AsyncLoading<List<TwitterUser>>().copyWithPrevious(state);

    final repository = ref.read(analysisReportRepositoryProvider);
    final arg = this.arg;

    try {
      final offset = _users.length;

      final newUsers = await repository.getUsersForCategory(
        arg.ownerId,
        arg.categoryKey,
        limit: _kUserListPageSize,
        offset: offset,
      );

      if (newUsers.isEmpty || newUsers.length < _kUserListPageSize) {
        _hasMore = false;
        logger.i(
          "UserListNotifier: fetchMore() fetched less than page size, setting hasMore=false",
        );
      }

      _users.addAll(newUsers);

      state = AsyncData(_users);
      logger.i(
        "UserListNotifier: fetchMore() completed, total users=${_users.length}",
      );
    } catch (e, s) {
      state = AsyncValue<List<TwitterUser>>.error(e, s).copyWithPrevious(state);
      logger.e(
        "UserListNotifier: fetchMore() failed: $e",
        error: e,
        stackTrace: s,
      );
    }
  }

  bool hasMore() {
    return _hasMore;
  }
}

final userListProvider =
    AsyncNotifierProvider.family<
      UserListNotifier,
      List<TwitterUser>,
      UserListParam
    >(() {
      return UserListNotifier();
    });
