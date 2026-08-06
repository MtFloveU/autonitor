part of '../settings_page.dart';

class LogViewerPage extends ConsumerWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final logs = ref.watch(logHistoryProvider);
    final logText = logs.join('\n');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.view_log)),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: logs.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.article_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Scrollbar(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: logs.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(
                                  '${index + 1}',
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SelectableText(
                                  logs[index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.35,
                                    fontFamily: 'monospace',
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: logText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.copied_to_clipboard,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: colorScheme.primaryContainer,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(l10n.clear),
                  onPressed: () {
                    ref.read(logHistoryNotifierProvider.notifier).clearLog();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
