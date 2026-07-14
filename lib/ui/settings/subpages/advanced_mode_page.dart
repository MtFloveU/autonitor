part of '../settings_page.dart';

class AdvancedModePage extends ConsumerWidget {
  const AdvancedModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).valueOrNull ?? AppSettings();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advanced_mode)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.advanced_mode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.advanced_mode_description),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      Icons.insights_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: Text("Enable new data fetching strategy"),
                    value: settings.enableDataFetchingStrategy,
                    onChanged: (bool newValue) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateEnableDataFetchingStrategy(newValue);
                    },
                  ),
                  const SizedBox(height: 8), // 添加一点间距让视觉更透气
                  Text(
                    "", // 建议替换为 l10n 变量
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4, // 增加行高提升多行文本的可读性
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
}
