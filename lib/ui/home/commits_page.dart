import 'package:autonitor/l10n/app_localizations.dart';
import 'package:autonitor/providers/commits_provider.dart';
import 'package:autonitor/services/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// import 'sync_logs_provider.dart';

class CommitsPage extends ConsumerWidget {
  final String lastRunId;
  final String? lastUpdateTime;
  final String activeAccountId;

  const CommitsPage({
    super.key,
    required this.lastRunId,
    required this.lastUpdateTime,
    required this.activeAccountId,
  });

  String _formatTimestamp(DateTime dt) => DateFormat.yMd().add_Hms().format(dt);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 订阅封装后的数据流
    final logsAsync = ref.watch(syncLogsProvider(activeAccountId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('History Commits'),
            Text(
              activeAccountId,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (logs) {
          if (logs.isEmpty) return _buildEmptyState(colorScheme);

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildLogCard(context, ref, logs[index], colorScheme),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(
    BuildContext context,
    WidgetRef ref,
    SyncLogsEntry log,
    ColorScheme colorScheme,
  ) {
    final isCurrent = log.runId == lastRunId;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isCurrent
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrent
              ? colorScheme.secondary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildStatusIcon(isCurrent, colorScheme),
            const SizedBox(width: 16),
            _buildInfoColumn(context, log, isCurrent, colorScheme),
            // 最新数据不需要三个点（操作菜单）
            if (!isCurrent)
              _buildPopupMenu(context, ref, log.runId, colorScheme)
            else
              const SizedBox(width: 48), // 占位保持布局平衡
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isCurrent, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.secondary
            : colorScheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCurrent ? Icons.check_circle_rounded : Icons.history_rounded,
        color: isCurrent ? colorScheme.onSecondary : colorScheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildInfoColumn(
    BuildContext context,
    SyncLogsEntry log,
    bool isCurrent,
    ColorScheme colorScheme,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                log.runId,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurface,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: log.runId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.copied_to_clipboard,
                      ),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.content_copy_rounded,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _formatTimestamp(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    WidgetRef ref,
    String runId,
    ColorScheme colorScheme,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant),
      onSelected: (value) => _handleRollback(context, ref, runId),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rollback',
          enabled: false,
          child: ListTile(
            leading: const Icon(Icons.settings_backup_restore_rounded),
            title: Text(AppLocalizations.of(context)!.rollback_to_here),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _handleRollback(
    BuildContext context,
    WidgetRef ref,
    String runId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rollback?'),
        content: Text('Delete subsequent logs and restore state to $runId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // 通过 Notifier 执行业务逻辑，UI 层不接触数据库接口
        await ref
            .read(syncLogsProvider(activeAccountId).notifier)
            .rollback(runId);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Rollback successful')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No history records found',
            style: TextStyle(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
