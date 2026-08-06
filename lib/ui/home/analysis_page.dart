import 'package:autonitor/providers/analysis_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/providers/auth_provider.dart';
import 'package:autonitor/providers/report_providers.dart';
import 'package:autonitor/models/sync_progress.dart';
import 'package:autonitor/models/app_settings.dart';
import '../../l10n/app_localizations.dart';

enum _StageState { pending, active, complete }

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({super.key, required this.syncFetchMode});

  final SyncFetchMode syncFetchMode;

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _startAnalysis() {
    final state = ref.read(analysisServiceProvider);
    if (state.status == AnalysisStatus.paused) {
      return;
    }
    final account = ref.read(activeAccountProvider);
    if (account != null) {
      ref
          .read(analysisServiceProvider.notifier)
          .runAnalysis(account, widget.syncFetchMode)
          .then((_) {
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

    // 只有在处理中（Running/Pause/Stopping）时才阻止退出，Completed/Failed 允许退出
    final bool isProcessing = analysisState.isProcessing;

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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _buildVisualProgress(analysisState, colorScheme, l10n),
                  _buildStatusBanner(status, colorScheme, context),
                  const SizedBox(height: 16),
                  _buildLogPanel(analysisState.log, colorScheme, l10n),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildBottomButtons(status, colorScheme, context),
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

  Widget _buildVisualProgress(
    AnalysisState analysisState,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    const stages = [
      SyncStage.preparing,
      SyncStage.refreshingProfile,
      SyncStage.initializingServices,
      SyncStage.loadingExistingData,
      SyncStage.fetchingNetwork,
      SyncStage.analyzingChanges,
      SyncStage.downloadingMedia,
      SyncStage.savingResults,
      SyncStage.finalizing,
    ];
    final progress =
        analysisState.progress ??
        const SyncProgress(stage: SyncStage.preparing);
    final currentIndex = stages.indexOf(progress.stage);
    final isTerminal =
        progress.stage == SyncStage.completed ||
        progress.stage == SyncStage.failed ||
        progress.stage == SyncStage.stopped;
    final completedStages = isTerminal
        ? stages.length
        : (currentIndex < 0 ? 0 : currentIndex);
    final overallValue = isTerminal
        ? 1.0
        : ((completedStages + (progress.itemFraction ?? 0)) / stages.length);
    final isError = analysisState.status == AnalysisStatus.failed;
    final progressColor = isError ? colorScheme.error : colorScheme.primary;
    final stepValue = progress.itemFraction ?? (isTerminal ? 1.0 : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBorderColor(analysisState.status, colorScheme),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_stageIcon(progress.stage), color: progressColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stageLabel(progress.stage, l10n),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (progress.step != null ||
                        progress.currentItemName != null)
                      Text(
                        [
                          if (progress.step != null)
                            _stepLabel(progress.step!, l10n),
                          if (progress.currentItemName != null)
                            progress.currentItemName!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (analysisState.rateLimitResetAt != null) ...[
            const SizedBox(height: 16),
            _buildRateLimitNotice(
              analysisState.rateLimitResetAt!,
              analysisState.status,
              colorScheme,
              l10n,
            ),
          ],
          const SizedBox(height: 20),
          _buildProgressLine(
            label: l10n.sync_overall_progress,
            value: overallValue,
            color: progressColor,
            trailing:
                '${completedStages.clamp(0, stages.length)}/${stages.length}',
          ),
          const SizedBox(height: 14),
          _buildProgressLine(
            label: l10n.sync_step_progress,
            value: stepValue,
            color: progressColor,
            trailing: progress.hasItemProgress
                ? '${progress.completedItems}/${progress.totalItems}'
                : progress.completedItems != null &&
                      progress.currentBatch != null
                ? l10n.sync_accounts_processed(
                    progress.completedItems!,
                    progress.currentBatch!,
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < stages.length; index++)
                _buildStageChip(
                  stage: stages[index],
                  state: index < completedStages
                      ? _StageState.complete
                      : index == currentIndex && !isTerminal
                      ? _StageState.active
                      : _StageState.pending,
                  colorScheme: colorScheme,
                  l10n: l10n,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitNotice(
    DateTime resetAt,
    AnalysisStatus status,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final remaining = resetAt.difference(DateTime.now());
    final isReady = remaining <= Duration.zero;
    final duration = remaining > Duration.zero ? remaining : Duration.zero;
    final text = isReady && status == AnalysisStatus.paused
        ? l10n.sync_rate_limit_ready
        : l10n.sync_rate_limit_waiting(
            MaterialLocalizations.of(
              context,
            ).formatTimeOfDay(TimeOfDay.fromDateTime(resetAt)),
            '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
          );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine({
    required String label,
    required double? value,
    required Color color,
    String? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            if (trailing != null)
              Text(trailing, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: value,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
      ],
    );
  }

  Widget _buildStageChip({
    required SyncStage stage,
    required _StageState state,
    required ColorScheme colorScheme,
    required AppLocalizations l10n,
  }) {
    final active = state == _StageState.active;
    final complete = state == _StageState.complete;
    final color = active || complete
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? colorScheme.primaryContainer
            : complete
            ? colorScheme.primary.withValues(alpha: 0.10)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check_circle : _stageIcon(stage),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            _stageLabel(stage, l10n),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel(
    List<String> logs,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.article_outlined),
        title: Text(l10n.sync_show_logs),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l10n.sync_logs_empty),
            )
          else
            SizedBox(
              height: 280,
              child: Scrollbar(
                controller: _logScrollController,
                child: ListView.separated(
                  controller: _logScrollController,
                  primary: false,
                  // Show the most recent record first. The panel remains a
                  // bounded scroll area instead of expanding the sync page.
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: SelectableText(
                      logs[logs.length - 1 - index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _stageIcon(SyncStage stage) {
    return switch (stage) {
      SyncStage.preparing => Icons.rocket_launch_outlined,
      SyncStage.refreshingProfile => Icons.person_outline,
      SyncStage.initializingServices => Icons.settings_suggest_outlined,
      SyncStage.loadingExistingData => Icons.storage_outlined,
      SyncStage.fetchingNetwork => Icons.cloud_download_outlined,
      SyncStage.analyzingChanges => Icons.manage_search_outlined,
      SyncStage.downloadingMedia => Icons.image_outlined,
      SyncStage.savingResults => Icons.save_outlined,
      SyncStage.finalizing => Icons.task_alt_outlined,
      SyncStage.completed => Icons.check_circle_outline,
      SyncStage.failed => Icons.error_outline,
      SyncStage.stopped => Icons.cancel_outlined,
    };
  }

  String _stageLabel(SyncStage stage, AppLocalizations l10n) {
    return switch (stage) {
      SyncStage.preparing => l10n.sync_stage_preparing,
      SyncStage.refreshingProfile => l10n.sync_stage_refreshing_profile,
      SyncStage.initializingServices => l10n.sync_stage_initializing_services,
      SyncStage.loadingExistingData => l10n.sync_stage_loading_existing_data,
      SyncStage.fetchingNetwork => l10n.sync_stage_fetching_network,
      SyncStage.analyzingChanges => l10n.sync_stage_analyzing_changes,
      SyncStage.downloadingMedia => l10n.sync_stage_downloading_media,
      SyncStage.savingResults => l10n.sync_stage_saving_results,
      SyncStage.finalizing => l10n.sync_stage_finalizing,
      SyncStage.completed => l10n.sync_stage_completed,
      SyncStage.failed => l10n.sync_stage_failed,
      SyncStage.stopped => l10n.sync_stage_stopped,
    };
  }

  String _stepLabel(SyncStep step, AppLocalizations l10n) {
    return switch (step) {
      SyncStep.generatingRunId => l10n.sync_step_generating_run_id,
      SyncStep.refreshingOwnerProfile =>
        l10n.sync_step_refreshing_owner_profile,
      SyncStep.initializingTransactionId =>
        l10n.sync_step_initializing_transaction_id,
      SyncStep.loadingQueryIds => l10n.sync_step_loading_query_ids,
      SyncStep.loadingExistingRelations =>
        l10n.sync_step_loading_existing_relations,
      SyncStep.fetchingFollowers => l10n.sync_step_fetching_followers,
      SyncStep.fetchingFollowing => l10n.sync_step_fetching_following,
      SyncStep.enrichingProfiles => l10n.sync_step_enriching_profiles,
      SyncStep.checkingRemovedRelations =>
        l10n.sync_step_checking_removed_relations,
      SyncStep.comparingProfiles => l10n.sync_step_comparing_profiles,
      SyncStep.checkingMedia => l10n.sync_step_checking_media,
      SyncStep.downloadingMedia => l10n.sync_step_downloading_media,
      SyncStep.preparingDatabaseChanges =>
        l10n.sync_step_preparing_database_changes,
      SyncStep.writingDatabaseChanges =>
        l10n.sync_step_writing_database_changes,
      SyncStep.recordingSyncLog => l10n.sync_step_recording_sync_log,
    };
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
