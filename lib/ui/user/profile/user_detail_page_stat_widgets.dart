part of 'user_detail_page.dart';

extension _UserDetailPageStatWidgets on _UserDetailPageState {
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
    return SizedBox(
      width: itemWidth,
      child: InkWell(
        onTap: widget.isFromHistory
            ? null
            : () => _showHistoryChart(context, item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryChart(BuildContext context, _StatItemData item) async {
    final rawData = await ref
        .read(historyRepositoryProvider)
        .getFieldHistory(
          ownerId: widget.ownerId,
          userId: widget.user.restId,
          targetKey: item.jsonKey,
        );

    if (!context.mounted || rawData.isEmpty) return;

    final validData = rawData.where((e) {
      final t = e['timestamp'];
      return t != null && t != 0;
    }).toList();

    if (validData.isEmpty) return;

    validData.sort(
      (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );

    final List<FlSpot> spots = [];
    for (var entry in validData) {
      spots.add(
        FlSpot(
          (entry['timestamp'] as int).toDouble(),
          (entry['value'] as num).toDouble(),
        ),
      );
    }

    final double minX = spots.first.x;
    final double maxX = spots.last.x;
    final double timeRange = maxX - minX;

    double xInterval = timeRange / 5;
    if (xInterval < 86400000) {
      xInterval = 86400000;
    }

    final Iterable<double> yIterable = spots.map((s) => s.y);
    double minYValue = yIterable.reduce((a, b) => a < b ? a : b);
    double maxYValue = yIterable.reduce((a, b) => a > b ? a : b);

    double paddingY;
    if ((maxYValue - minYValue).abs() < 0.000001) {
      paddingY = maxYValue == 0 ? 1.0 : maxYValue.abs() * 0.1;
    } else {
      paddingY = (maxYValue - minYValue) * 0.1;
    }

    final double chartMinY = minYValue == 0 ? 0 : minYValue - paddingY;
    final double chartMaxY = maxYValue + paddingY;
    double leftInterval = (chartMaxY - chartMinY) / 4;
    if (leftInterval <= 0) leftInterval = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            minHeight: 300,
          ),
          padding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.label, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 24),
              Expanded(
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        getTooltipColor: (spot) =>
                            Theme.of(ctx).colorScheme.surfaceContainerHighest,
                        getTooltipItems: (touchedSpots) => touchedSpots.map((
                          spot,
                        ) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            spot.x.toInt(),
                          );
                          return LineTooltipItem(
                            '${DateFormat.yMd().add_Hms().format(date)}\n${spot.y.toInt()}',
                            TextStyle(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(ctx).dividerColor.withAlpha(50),
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
                          interval: xInterval,
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
                          interval: leftInterval,
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
                    minX: minX,
                    maxX: maxX,
                    minY: chartMinY,
                    maxY: chartMaxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        color: Theme.of(ctx).colorScheme.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(
                            ctx,
                          ).colorScheme.primary.withAlpha(20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
