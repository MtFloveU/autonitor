import 'package:autonitor/providers/analysis_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/providers/auth_provider.dart';
import 'package:autonitor/providers/report_providers.dart';
import '../../l10n/app_localizations.dart';

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({super.key});

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  void _startAnalysis() {
    final state = ref.read(analysisServiceProvider);
    if (state.status == AnalysisStatus.paused) {
      return;
    }
    final account = ref.read(activeAccountProvider);
    if (account != null) {
      ref.read(analysisServiceProvider.notifier).runAnalysis(account).then((_) {
        if (mounted) {
          ref.invalidate(cacheProvider);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analysisState = ref.watch(analysisServiceProvider);
    final status = analysisState.status;
    final logs = analysisState.log;

    // 只有在处理中（Running/Pause/Stopping）时才阻止退出，Completed/Failed 允许退出
    final bool isProcessing = analysisState.isProcessing;

    // 是否显示任意形式的进度条（处理中、完成、失败）
    final bool showProgressBar =
        status != AnalysisStatus.idle && status != AnalysisStatus.stopped;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !isProcessing || status == AnalysisStatus.paused,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.run),
          centerTitle: true,
          automaticallyImplyLeading:
              !isProcessing || status == AnalysisStatus.paused,
        ),
        body: Column(
          children: [
            // --- 进度条区域 ---
            if (showProgressBar) _buildProgressBar(status, colorScheme),
            _buildStatusBanner(status, colorScheme, context),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getBorderColor(status, colorScheme),
                  ),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    logs.join('\n'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // 底部操作区
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildBottomButtons(status, colorScheme, context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI 构建辅助方法 ---

  Color _getBorderColor(AnalysisStatus status, ColorScheme colorScheme) {
    if (status == AnalysisStatus.failed) {
      return colorScheme.error.withValues(alpha: 0.5);
    } else if (status == AnalysisStatus.completed) {
      return colorScheme.primary;
    }
    return colorScheme.outlineVariant.withValues(alpha: 0.5);
  }

  Widget _buildProgressBar(AnalysisStatus status, ColorScheme colorScheme) {
    // 1. 完成状态：绿色满条
    if (status == AnalysisStatus.completed) {
      return LinearProgressIndicator(
        value: 1.0,
        minHeight: 4,
        color: colorScheme.primary,
        backgroundColor: colorScheme.primary.withAlpha(50),
      );
    }

    // 2. 失败状态：红色满条
    if (status == AnalysisStatus.failed) {
      return LinearProgressIndicator(
        value: 1.0,
        minHeight: 4,
        color: colorScheme.error,
        backgroundColor: colorScheme.errorContainer,
      );
    }

    // 3. 暂停/暂停中状态：变淡的进度条 (符合你的需求)
    if (status == AnalysisStatus.paused || status == AnalysisStatus.pausing) {
      return LinearProgressIndicator(
        minHeight: 4,
        valueColor: AlwaysStoppedAnimation<Color>(
          colorScheme.secondary.withValues(alpha: 0.5),
        ),
      );
    }

    // 4. 正常运行中：默认 indeterminate
    return const LinearProgressIndicator(minHeight: 4);
  }

  Widget _buildBottomButtons(
    AnalysisStatus status,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    // 情况 A: 完成或失败 -> 显示“完成/关闭”按钮
    if (status == AnalysisStatus.completed ||
        status == AnalysisStatus.failed ||
        status == AnalysisStatus.stopped) {
      return FilledButton.icon(
        onPressed: () {
          ref.read(analysisServiceProvider.notifier).resetState();
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.check),
        label: Text(AppLocalizations.of(context)!.ok),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: status == AnalysisStatus.completed
              ? colorScheme.primary
              : colorScheme.error,
        ),
      );
    }

    // 情况 B: 运行中 (Running/Paused/Stopping) -> 显示 Stop/Pause
    if (status != AnalysisStatus.idle) {
      return Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.end,
        children: [
          // --- Stop 按钮 ---
          OutlinedButton.icon(
            onPressed: status == AnalysisStatus.stopping
                ? null
                : () {
                    _showStopConfirmDialog(context);
                  },

            icon: const Icon(Icons.close),
            label: Text(AppLocalizations.of(context)!.stop),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: colorScheme.errorContainer.withValues(
                alpha: 0.3,
              ),
              foregroundColor: colorScheme.onErrorContainer,
              side: BorderSide(
                color: colorScheme.error.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // --- Pause/Resume 按钮 ---
          OutlinedButton.icon(
            onPressed: status == AnalysisStatus.stopping
                ? null
                : () {
                    ref.read(analysisServiceProvider.notifier).togglePause();
                  },
            icon: _buildPauseIcon(status, colorScheme),
            label: Text(_getPauseLabel(status)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: colorScheme.primaryContainer.withValues(
                alpha: 0.3,
              ),
              foregroundColor: colorScheme.onPrimaryContainer,
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    }

    // 情况 C: Idle -> 不显示按钮 (或显示开始)
    return const SizedBox.shrink();
  }

  Widget _buildPauseIcon(AnalysisStatus status, ColorScheme colorScheme) {
    if (status == AnalysisStatus.pausing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
    } else if (status == AnalysisStatus.paused) {
      return const Icon(Icons.play_arrow_rounded);
    } else {
      return const Icon(Icons.pause_rounded);
    }
  }

  Widget _buildStatusBanner(
    AnalysisStatus status,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final account = ref.watch(activeAccountProvider);
    final l10n = AppLocalizations.of(context)!;

    IconData? icon;
    String? text;
    Color? background;
    Color? foreground;

    switch (status) {
      case AnalysisStatus.paused:
        icon = Icons.pause_circle_outline;
        text = l10n.paused;
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
        break;

      case AnalysisStatus.completed:
        icon = Icons.check_circle_outline;
        text = l10n.sync_completed_notification_text(
          account?.screenName ?? 'Unknown',
        );
        background = colorScheme.tertiaryContainer;
        foreground = colorScheme.onTertiaryContainer;
        break;

      case AnalysisStatus.failed:
        icon = Icons.error_outline;
        text = l10n.sync_failed_notification_text(
          account?.screenName ?? 'Unknown',
        );
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        break;

      case AnalysisStatus.stopped:
        icon = Icons.cancel_outlined;
        text = l10n.stopped_by_user;
        background = colorScheme.surfaceContainerHighest;
        foreground = colorScheme.onSurfaceVariant;
        break;

      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  String _getPauseLabel(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.paused:
        return AppLocalizations.of(context)!.resume;
      default:
        return AppLocalizations.of(context)!.pause;
    }
  }

  Future<void> _showStopConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.comfirm_stop_sync_title),
          content: Text(l10n.comfirm_stop_sync_text),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.stop),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      ref.read(analysisServiceProvider.notifier).stopAnalysis();
    }
  }
}
