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
    logger.e(
      "cacheProvider: Error fetching counts from database",
      error: e,
      stackTrace: s,
    );
    return null;
  }
});

const int _kUserListPageSize = 10;

class UserListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<TwitterUser>, UserListParam> {
  final List<TwitterUser> _users = [];
  final Set<String> _seenIds = <String>{};
  bool _hasMore = true;
  bool _isFetching = false;
  int _duplicateStreak = 0;
  late UserListParam _param;

  @override
  Future<List<TwitterUser>> build(UserListParam arg) async {
    _param = arg;
    _users.clear();
    _seenIds.clear();
    _hasMore = true;
    _isFetching = false;
    _duplicateStreak = 0;

    final repository = ref.read(analysisReportRepositoryProvider);

    try {
      final newUsers = await repository.getUsersForCategory(
        arg.ownerId,
        arg.categoryKey,
        limit: _kUserListPageSize,
        offset: 0,
      );

      for (var u in newUsers) {
        final id = u.restId;
        if (id.isNotEmpty && !_seenIds.contains(id)) {
          _seenIds.add(id);
          _users.add(u);
        }
      }

      // only stop when server returns empty result (avoid premature stop due to filtering)
      _hasMore = newUsers.isNotEmpty;

      return List<TwitterUser>.from(_users);
    } catch (e, s) {
      logger.e("UserListNotifier.build error", error: e, stackTrace: s);
      throw e;
    }
  }

  Future<void> fetchMore() async {
    if (_isFetching || !_hasMore) return;
    _isFetching = true;

    final repository = ref.read(analysisReportRepositoryProvider);

    try {
      final offset = _users.length;
      logger.i("UserListNotifier: fetchMore() offset=$offset");

      final newUsers = await repository.getUsersForCategory(
        _param.ownerId,
        _param.categoryKey,
        limit: _kUserListPageSize,
        offset: offset,
      );

      if (newUsers.isEmpty) {
        _duplicateStreak += 1;
        logger.w(
          "UserListNotifier: fetchMore() returned empty, duplicateStreak=$_duplicateStreak",
        );
      } else {
        final uniqueNew = <TwitterUser>[];
        for (var u in newUsers) {
          final id = u.restId;
          if (id.isNotEmpty && !_seenIds.contains(id)) {
            _seenIds.add(id);
            uniqueNew.add(u);
          }
        }

        if (uniqueNew.isNotEmpty) {
          _users.addAll(uniqueNew);
          _duplicateStreak = 0;
        } else {
          _duplicateStreak += 1;
          logger.w(
            "UserListNotifier: fetchMore() returned only duplicates, duplicateStreak=$_duplicateStreak",
          );
        }
      }

      // stop when we got several empty/duplicate rounds in a row OR server returned empty
      if (_duplicateStreak >= 3) {
        _hasMore = false;
        logger.w(
          "UserListNotifier: duplicate streak reached, stopping pagination",
        );
      } else {
        // continue unless server returned empty and duplicateStreak triggered stop
        _hasMore = newUsers.isNotEmpty;
      }

      state = AsyncData(List<TwitterUser>.from(_users));
    } catch (e, s) {
      logger.e("UserListNotifier: fetchMore failed", error: e, stackTrace: s);
      state = AsyncValue<List<TwitterUser>>.error(e, s).copyWithPrevious(state);
    } finally {
      _isFetching = false;
    }
  }

  bool hasMore() => _hasMore;
}

final userListProvider = AsyncNotifierProvider.family
    .autoDispose<UserListNotifier, List<TwitterUser>, UserListParam>(
      () => UserListNotifier(),
    );
