import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/models/history_snapshot.dart';
import 'package:autonitor/providers/settings_provider.dart';
import 'package:autonitor/repositories/history_repository.dart';

@immutable
class ProfileHistoryParams {
  final String ownerId;
  final String userId;

  const ProfileHistoryParams({required this.ownerId, required this.userId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileHistoryParams &&
          runtimeType == other.runtimeType &&
          ownerId == other.ownerId &&
          userId == other.userId;

  @override
  int get hashCode => ownerId.hashCode ^ userId.hashCode;
}

class ProfileHistoryPagedState {
  final List<HistorySnapshot> snapshots;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const ProfileHistoryPagedState({
    this.snapshots = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });
}

class ProfileHistoryNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<
          ProfileHistoryPagedState,
          ProfileHistoryParams
        > {
  static const int _pageSize = 20;

  @override
  Future<ProfileHistoryPagedState> build(ProfileHistoryParams arg) async {
    return _fetchPage(1);
  }

  Future<ProfileHistoryPagedState> _fetchPage(int page) async {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null) return const ProfileHistoryPagedState();

    final repository = ref.read(historyRepositoryProvider);

    // 调用 Repository，它现在返回 HistoryPagedResult
    final result = await repository.getFilteredHistory(
      arg.ownerId,
      arg.userId,
      settings,
      page: page,
      pageSize: _pageSize,
    );

    // 计算总页数
    final totalPages = (result.totalCount / _pageSize).ceil();
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;

    return ProfileHistoryPagedState(
      snapshots: result.snapshots,
      totalCount: result.totalCount,
      currentPage: page,
      totalPages: safeTotalPages,
    );
  }

  Future<void> setPage(int page) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(page));
  }
}

final profileHistoryProvider = AsyncNotifierProvider.family
    .autoDispose<
      ProfileHistoryNotifier,
      ProfileHistoryPagedState,
      ProfileHistoryParams
    >(ProfileHistoryNotifier.new);
