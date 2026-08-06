part of 'user_detail_page.dart';

extension _UserDetailPageStatWidgets on _UserDetailPageState {
  Widget _buildChartContent(
    BuildContext context,
    _StatItemData item,
    StatChartViewState viewState,
  ) {
    return _HistoryChartSheet(item: item, viewState: viewState);
  }

  Widget _buildFlexibleStatGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final items = [
      _StatItemData(
        Icons.group_outlined,
        l10n.following,
        widget.user.followingCount.toString(),
        'following_count',
      ),
      _StatItemData(
        Icons.group,
        l10n.followers,
        widget.user.followersCount.toString(),
        'followers_count',
      ),
      _StatItemData(
        Icons.create,
        l10n.tweets,
        widget.user.statusesCount.toString(),
        'statuses_count',
      ),
      _StatItemData(
        Icons.image,
        l10n.media_count,
        widget.user.mediaCount.toString(),
        'media_count',
      ),
      _StatItemData(
        Icons.favorite,
        l10n.likes,
        widget.user.favouritesCount.toString(),
        'favourites_count',
      ),
      _StatItemData(
        Icons.list_alt,
        l10n.listed_count,
        widget.user.listedCount.toString(),
        'listed_count',
      ),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withAlpha(51)),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 16.0,
        alignment: WrapAlignment.spaceEvenly,
        children: items.map((item) => _buildGridItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, _StatItemData item) {
    const double itemWidth = 100;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: itemWidth,
      child: InkWell(
        onTap: widget.isFromHistory
            ? null
            : () => _showHistoryChart(context, item),
        borderRadius: BorderRadius.circular(12), // MD3 standard: larger radius
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.value,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // MD3 Hint Icon: Indicates more data/chart available
                  if (!widget.isFromHistory)
                    Positioned(
                      top: -2,
                      right: 0,
                      child: Icon(
                        Icons.analytics_outlined,
                        size: 10,
                        color: colorScheme.outline,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      colorScheme.onSurfaceVariant, // MD3 secondary text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryChart(BuildContext context, _StatItemData item) {
    final l10n = AppLocalizations.of(context)!;
    final params = StatChartParams(
      ownerId: widget.ownerId,
      userId: widget.user.restId,
      targetKey: item.jsonKey,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final chartAsync = ref.watch(statChartProvider(params));

            return chartAsync.when(
              data: (viewState) => _buildChartContent(ctx, item, viewState),
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SizedBox(
                height: 300,
                child: Center(child: Text(l10n.no_data)),
              ),
            );
          },
        );
      },
    );
  }
}

enum _ChartRange { all, week, month, quarter, year }

class _HistoryChartSheet extends StatefulWidget {
  const _HistoryChartSheet({required this.item, required this.viewState});

  final _StatItemData item;
  final StatChartViewState viewState;

  @override
  State<_HistoryChartSheet> createState() => _HistoryChartSheetState();
}

class _HistoryChartSheetState extends State<_HistoryChartSheet> {
  _ChartRange _range = _ChartRange.all;

  Duration? get _duration => switch (_range) {
    _ChartRange.all => null,
    _ChartRange.week => const Duration(days: 7),
    _ChartRange.month => const Duration(days: 30),
    _ChartRange.quarter => const Duration(days: 90),
    _ChartRange.year => const Duration(days: 365),
  };

  String _rangeLabel(AppLocalizations l10n, _ChartRange range) {
    return switch (range) {
      _ChartRange.all => l10n.chart_time_all,
      _ChartRange.week => l10n.chart_time_7d,
      _ChartRange.month => l10n.chart_time_30d,
      _ChartRange.quarter => l10n.chart_time_90d,
      _ChartRange.year => l10n.chart_time_1y,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final viewState = widget.viewState.forRecent(_duration);
    final first = viewState.spots.first;
    final last = viewState.spots.last;
    final delta = last.y - first.y;
    final valueFormat = NumberFormat.compact();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.76,
        minHeight: 420,
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.label,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.arrow_forward_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.chart_chronological,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _ChartRange.values.map((range) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_rangeLabel(l10n, range)),
                    selected: _range == range,
                    onSelected: (_) => setState(() => _range = range),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ChartSummary(
                label: l10n.chart_start,
                value: valueFormat.format(first.y),
              ),
              _ChartSummary(
                label: l10n.chart_latest,
                value: valueFormat.format(last.y),
              ),
              _ChartSummary(
                label: l10n.chart_change,
                value: '${delta >= 0 ? '+' : ''}${valueFormat.format(delta)}',
                valueColor: delta == 0
                    ? null
                    : delta > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.chart_data_points(viewState.spots.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildChart(theme, viewState)),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme, StatChartViewState viewState) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              return LineTooltipItem(
                '${DateFormat.yMd().add_Hms().format(date)}\n${NumberFormat.decimalPattern().format(spot.y)}',
                TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.dividerColor.withAlpha(50), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: viewState.xInterval,
              getTitlesWidget: (xValue, meta) {
                if (xValue == meta.min || xValue == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.Md().format(
                      DateTime.fromMillisecondsSinceEpoch(xValue.toInt()),
                    ),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: viewState.yInterval,
              getTitlesWidget: (yValue, meta) {
                if (yValue == meta.min || yValue == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  NumberFormat.compact().format(yValue),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: viewState.minX,
        maxX: viewState.maxX,
        minY: viewState.minY,
        maxY: viewState.maxY,
        lineBarsData: [
          LineChartBarData(
            spots: viewState.spots,
            isCurved: false,
            preventCurveOverShooting: true,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: FlDotData(show: viewState.spots.length == 1),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withAlpha(20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSummary extends StatelessWidget {
  const _ChartSummary({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
