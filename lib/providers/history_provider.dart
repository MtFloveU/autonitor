import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/models/history_snapshot.dart';
import 'package:autonitor/providers/settings_provider.dart';
import 'package:autonitor/repositories/history_repository.dart';

@immutable
class StatChartParams {
  final String ownerId;
  final String userId;
  final String targetKey;

  const StatChartParams({
    required this.ownerId,
    required this.userId,
    required this.targetKey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatChartParams &&
          runtimeType == other.runtimeType &&
          ownerId == other.ownerId &&
          userId == other.userId &&
          targetKey == other.targetKey;

  @override
  int get hashCode => ownerId.hashCode ^ userId.hashCode ^ targetKey.hashCode;
}

// Pre-calculated data structure for UI rendering
class StatChartViewState {
  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double xInterval;
  final double yInterval;

  StatChartViewState({
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.xInterval,
    required this.yInterval,
  });

  factory StatChartViewState.fromSpots(List<FlSpot> spots) {
    assert(spots.isNotEmpty);
    final minX = spots.first.x;
    final rawMaxX = spots.last.x;
    // fl_chart needs a non-zero drawing domain for a single observation.
    final maxX = rawMaxX == minX ? minX + Duration.millisecondsPerDay : rawMaxX;
    final timeRange = maxX - minX;
    final xInterval = (timeRange / 5).clamp(
      Duration.millisecondsPerDay.toDouble(),
      double.infinity,
    );

    final values = spots.map((spot) => spot.y);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue).abs() < 0.000001
        ? (maxValue == 0 ? 1.0 : maxValue.abs() * 0.1)
        : (maxValue - minValue) * 0.1;
    final minY = minValue == 0
        ? 0.0
        : (minValue > 0
                  ? (minValue - padding).clamp(0.0, minValue)
                  : minValue - padding)
              .toDouble();
    final maxY = maxValue + padding;
    final yInterval = ((maxY - minY) / 4).clamp(1.0, double.infinity);

    return StatChartViewState(
      spots: spots,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      xInterval: xInterval,
      yInterval: yInterval,
    );
  }

  /// Filters relative to the most recent observation and retains one point
  /// immediately before the range so the visible trend starts continuously.
  StatChartViewState forRecent(Duration? range) {
    if (range == null || spots.length < 2) return this;
    final cutoff = spots.last.x - range.inMilliseconds;
    final firstInRange = spots.indexWhere((spot) => spot.x >= cutoff);
    if (firstInRange <= 0) return this;
    return StatChartViewState.fromSpots(spots.sublist(firstInRange - 1));
  }
}

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

class StatChartNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<StatChartViewState, StatChartParams> {
  @override
  Future<StatChartViewState> build(StatChartParams arg) async {
    final repo = ref.read(historyRepositoryProvider);
    final rawData = await repo.getFieldHistory(
      ownerId: arg.ownerId,
      userId: arg.userId,
      targetKey: arg.targetKey,
    );

    // Filter and sort raw data
    final validData =
        rawData.where((e) {
          final t = e['timestamp'];
          return t != null && t != 0;
        }).toList()..sort(
          (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
        );

    if (validData.isEmpty) throw Exception('No valid data');

    // Logic migration: Perform all math calculations here
    final spots = validData
        .map(
          (e) => FlSpot(
            (e['timestamp'] as int).toDouble(),
            (e['value'] as num).toDouble(),
          ),
        )
        .toList();

    return StatChartViewState.fromSpots(spots);
  }
}

// Define the provider
final statChartProvider = AsyncNotifierProvider.family
    .autoDispose<StatChartNotifier, StatChartViewState, StatChartParams>(
      StatChartNotifier.new,
    );
