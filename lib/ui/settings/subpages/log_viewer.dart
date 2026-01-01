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
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                reverse: true,
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  logText,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
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
                TextButton(
                  child: Text(l10n.copy),
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