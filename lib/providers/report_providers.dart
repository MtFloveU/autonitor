// lib/providers/report_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../models/cache_data.dart';
import '../models/twitter_user.dart';
import '../main.dart';
import '../repositories/analysis_report_repository.dart';
import 'auth_provider.dart';
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
    final countExp = drift.countAll();

    final query = database.selectOnly(database.changeReports)
      ..addColumns([changeTypeCol, countExp])
      ..where(database.changeReports.ownerId.equals(activeAccount.id));

    query.groupBy([changeTypeCol]);

    final countsResult = await query.get();

    final Map<String, int> categoryCounts = {
      for (var row in countsResult)
        row.read(changeTypeCol)!: row.read(countExp)!,
    };

    final accountDetails = await (database.select(
      database.loggedAccounts,
    )..where((tbl) => tbl.id.equals(activeAccount.id))).getSingleOrNull();

    final latestLog =
        await (database.select(database.syncLogs)
              ..where(
                (tbl) =>
                    tbl.ownerId.equals(activeAccount.id) & tbl.status.equals(1),
              )
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.timestamp,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    // Use DB time if available, otherwise fallback to "N/A" (empty string) to indicate never updated
    final lastUpdateTimeStr = latestLog?.timestamp.toIso8601String() ?? '';

    return CacheData(
      accountId: activeAccount.id,
      accountName: activeAccount.name ?? 'N/A',
      lastUpdateTime: lastUpdateTimeStr,
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
      recoveredCount: categoryCounts['recovered'] ?? 0,
      profileUpdatedCount: categoryCounts['profile_update'] ?? 0,
      lastRunId: latestLog?.runId ?? '',
    );
  } catch (e, s) {
    logger.e(
      "cacheProvider: Error fetching counts from database",
      error: e,
      stackTrace: s,
    );
    return null;
  }
});

// [修改] 定义每页大小
const int _kUserListPageSize = 20;

// [新增] 分页状态类
@immutable
class UserPagedListState {
  final List<TwitterUser> users;
  final int totalCount;
  final int currentPage; // 1-based
  final int pageSize;

  const UserPagedListState({
    this.users = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.pageSize = _kUserListPageSize,
  });

  int get totalPages => (totalCount / pageSize).ceil();

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < totalPages;

  UserPagedListState copyWith({
    List<TwitterUser>? users,
    int? totalCount,
    int? currentPage,
    int? pageSize,
  }) {
    return UserPagedListState(
      users: users ?? this.users,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

// [修改] 使用 StateNotifier 来管理 UserPagedListState
class UserListNotifier
    extends AutoDisposeFamilyAsyncNotifier<UserPagedListState, UserListParam> {
  late UserListParam _param;

  @override
  Future<UserPagedListState> build(UserListParam arg) async {
    _param = arg;
    return _fetchPage(1); // 初始化加载第一页
  }

  Future<UserPagedListState> _fetchPage(int page) async {
    final repository = ref.read(analysisReportRepositoryProvider);
    final offset = (page - 1) * _kUserListPageSize;

    // 并行获取总数和当页数据
    final results = await Future.wait([
      repository.getUserCountForCategory(_param.ownerId, _param.categoryKey),
      repository.getUsersForCategory(
        _param.ownerId,
        _param.categoryKey,
        limit: _kUserListPageSize,
        offset: offset,
      ),
    ]);

    final totalCount = results[0] as int;
    final users = results[1] as List<TwitterUser>;

    return UserPagedListState(
      users: users,
      totalCount: totalCount,
      currentPage: page,
      pageSize: _kUserListPageSize,
    );
  }

  Future<void> setPage(int page) async {
    if (page < 1) return;
    // 如果当前已经是这一页，且不需强制刷新，可直接返回 (这里选择重新加载以防数据变动)
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(page));
  }

  Future<void> refresh() async {
    final currentPage = state.value?.currentPage ?? 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(currentPage));
  }
}

final userListProvider = AsyncNotifierProvider.family
    .autoDispose<UserListNotifier, UserPagedListState, UserListParam>(
      () => UserListNotifier(),
    );
