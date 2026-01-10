part of 'user_detail_page.dart';

extension _UserDetailPageStatWidgets on _UserDetailPageState {
  Widget _buildChartContent(
    BuildContext context,
    _StatItemData item,
    StatChartViewState viewState,
  ) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
        minHeight: 300,
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    getTooltipColor: (spot) =>
                        theme.colorScheme.surfaceContainerHighest,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        spot.x.toInt(),
                      );
                      return LineTooltipItem(
                        '${DateFormat.yMd().add_Hms().format(date)}\n${spot.y.toInt()}',
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
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: theme.dividerColor.withAlpha(50),
                    strokeWidth: 1,
                  ),
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
                      getTitlesWidget: (xValue, titleMeta) {
                        if (xValue == titleMeta.min ||
                            xValue == titleMeta.max) {
                          return const SizedBox.shrink();
                        }
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          xValue.toInt(),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat.Md().format(date),
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
                      getTitlesWidget: (yValue, titleMeta) {
                        if (yValue == titleMeta.min ||
                            yValue == titleMeta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          yValue.toInt().toString(),
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
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withAlpha(20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
