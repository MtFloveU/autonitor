part of 'settings_page.dart';

Widget _buildStorageSection(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
  AppLocalizations l10n,
  TextEditingController historyController,
  void Function(WidgetRef, int) onLimitUpdate,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(context, l10n.storage_settings),
      SwitchListTile(
        secondary: Icon(
          Icons.person_outline_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(l10n.save_avatar_history),
        value: settings.saveAvatarHistory,
        onChanged: (v) =>
            ref.read(settingsProvider.notifier).updateSaveAvatarHistory(v),
      ),
      if (settings.saveAvatarHistory)
        _SettingsDropdownTile<AvatarQuality>(
          title: l10n.avatar_quality,
          icon: Icons.high_quality,
          currentValue: settings.avatarQuality,
          options: {
            AvatarQuality.high: l10n.quality_high,
            AvatarQuality.low: l10n.quality_low,
          },
          onChanged: (v) {
            if (v != null) {
              ref.read(settingsProvider.notifier).updateAvatarQuality(v);
            }
          },
        ),
      SwitchListTile(
        secondary: Icon(
          Icons.image_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(l10n.save_banner_history),
        value: settings.saveBannerHistory,
        onChanged: (bool newValue) {
          ref
              .read(settingsProvider.notifier)
              .updateSaveBannerHistory(newValue);
        },
      ),
      
      _HistoryStrategyTile(
        l10n: l10n,
        settings: settings,
        controller: historyController,
      ),
    ],
  );
}

class _HistoryStrategyTile extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  final AppSettings settings;
  final TextEditingController controller;

  const _HistoryStrategyTile({
    required this.l10n,
    required this.settings,
    required this.controller,
  });

  @override
  ConsumerState<_HistoryStrategyTile> createState() =>
      _HistoryStrategyTileState();
}

class _HistoryStrategyTileState extends ConsumerState<_HistoryStrategyTile> {
  final GlobalKey _dropdownKey = GlobalKey();

  void _openDropdown() {
    final context = _dropdownKey.currentContext;
    if (context == null) return;

    void findGestureDetector(Element element) {
      if (element.widget is GestureDetector) {
        final gd = element.widget as GestureDetector;
        if (gd.onTap != null) {
          gd.onTap!();
          return;
        }
      }
      element.visitChildElements(findGestureDetector);
    }

    context.visitChildElements(findGestureDetector);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final Map<HistoryStrategy, String> options = {
      HistoryStrategy.saveAll: widget.l10n.strategy_save_all,
      HistoryStrategy.saveLatest: widget.l10n.strategy_save_latest,
      HistoryStrategy.saveLastN: widget.l10n.strategy_save_last_n,
    };

    final entries = options.entries.toList();

    final bool showInput =
        widget.settings.historyStrategy == HistoryStrategy.saveLastN;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            Icons.history_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          title: Text(widget.l10n.history_strategy, style: textTheme.bodyLarge),
          onTap: _openDropdown,
          subtitle: Align(
            alignment: Alignment.centerLeft,
            child: IgnorePointer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<HistoryStrategy>(
                  key: _dropdownKey,
                  isExpanded: false, 
                  isDense: true,
                  value: widget.settings.historyStrategy,
                  focusColor: Colors.transparent, 
                  items: List.generate(entries.length, (index) {
                    final entry = entries[index];
                    return DropdownMenuItem<HistoryStrategy>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: textTheme.bodyMedium, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateHistoryStrategy(value);
                    }
                  },
                  selectedItemBuilder: (context) {
                    return options.entries.map((entry) {
                      return Text(
                        entry.value,
                        key: ValueKey<String>(entry.value),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis, 
                        maxLines: 1, 
                      );
                    }).toList();
                  },
                  icon: const SizedBox.shrink(),
                  dropdownColor: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        if (showInput)
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 24, bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ), 
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                    ),
                    onEditingComplete: () {
                      _updateLimit(ref, widget.settings.historyLimitN);
                      FocusScope.of(context).unfocus();
                    },
                    onTapOutside: (event) {
                      _updateLimit(ref, widget.settings.historyLimitN);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.l10n.strategy_save_last_n_suffix,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _updateLimit(WidgetRef ref, int currentLimit) {
    final value = widget.controller.text;
    int n = int.tryParse(value) ?? 1;
    if (n < 1) n = 1;
    if (n > 500) n = 500;
    if (n != currentLimit) {
      ref.read(settingsProvider.notifier).updateHistoryLimitN(n);
    }
  }
}