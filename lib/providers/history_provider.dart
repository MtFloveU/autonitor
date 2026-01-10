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

    // ... (Transfer the coordinate calculation logic from UI to here) ...
    // Calculate minX, maxX, xInterval, yInterval based on user's original logic
    validData.map((entry) {
      return FlSpot(
        (entry['timestamp'] as int).toDouble(),
        (entry['value'] as num).toDouble(),
      );
    }).toList();

    final double minX = spots.first.x;
    final double maxX = spots.last.x;
    final double timeRange = maxX - minX;

    // Calculate X Axis Interval
    double xInterval = timeRange / 5;
    if (xInterval < 86400000) {
      xInterval = 86400000; // Minimum 1 day interval
    }

    // Calculate Y Axis Range and Padding
    final Iterable<double> yIterable = spots.map((s) => s.y);
    double minYValue = yIterable.reduce((a, b) => a < b ? a : b);
    double maxYValue = yIterable.reduce((a, b) => a > b ? a : b);

    double paddingY;
    if ((maxYValue - minYValue).abs() < 0.000001) {
      paddingY = maxYValue == 0 ? 1.0 : maxYValue.abs() * 0.1;
    } else {
      paddingY = (maxYValue - minYValue) * 0.1;
    }

    // Minimalist change:
    // If the minimum value is non-negative, force the axis to start exactly at 0.
    // This ensures the line touches the bottom when the value is 0.
    final double chartMinY = minYValue == 0
        ? 0.0
        : (minYValue > 0
              ? (minYValue - paddingY).clamp(0.0, minYValue)
              : minYValue - paddingY);

    final double chartMaxY = maxYValue + paddingY;

    // Recalculate interval based on the dynamic range
    double leftInterval = (chartMaxY - chartMinY) / 4;
    if (leftInterval <= 0) leftInterval = 1;
    return StatChartViewState(
      spots: spots,
      minX: minX,
      maxX: maxX,
      minY: chartMinY,
      maxY: chartMaxY,
      xInterval: xInterval,
      yInterval: leftInterval,
    );
  }
}

// Define the provider
final statChartProvider = AsyncNotifierProvider.family
    .autoDispose<StatChartNotifier, StatChartViewState, StatChartParams>(
      StatChartNotifier.new,
    );
