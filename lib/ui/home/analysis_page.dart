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
    final isRunning = ref.watch(analysisIsRunningProvider);
    // final isRunning = true;
    final logs = ref.watch(analysisLogProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !isRunning,
      child: Scaffold(
        // MD3: 使用更加明显的 AppBar 设计
        appBar: AppBar(
          title: Text(l10n.run),
          centerTitle: true,
          automaticallyImplyLeading: !isRunning,
        ),
        body: Column(
          children: [
            // MD3: 线性进度条颜色会自动匹配主题
            if (isRunning) const LinearProgressIndicator(minHeight: 4),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  // MD3: 使用 surfaceContainer 或 surfaceContainerHighest
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: logs.isEmpty && !isRunning
                    ? Center(
                        child: Text(
                          "准备中...",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
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
                  // 新增：右下角控制按钮组 (Pause & Stop)
                  if (isRunning)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 12.0, // 按钮之间的水平间距
                          runSpacing: 12.0, // 换行后的垂直间距
                          alignment: WrapAlignment.end,
                          children: [
                            // --- Stop 按钮 ---
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Stop Action
                              },
                              icon: const Icon(Icons.close),
                              label: const Text("Stop"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                // 颜色：背景使用 errorContainer 的极浅色，文字图标使用 onErrorContainer
                                backgroundColor: colorScheme.errorContainer
                                    .withValues(alpha: 0.3),
                                foregroundColor: colorScheme.onErrorContainer,
                                // 边框：显式的 error 颜色边框
                                side: BorderSide(
                                  color: colorScheme.error.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),

                            // --- Pause 按钮 ---
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Pause Action
                              },
                              icon: const Icon(Icons.pause_rounded),
                              label: const Text("Pause"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                backgroundColor: colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                foregroundColor: colorScheme.onPrimaryContainer,
                                side: BorderSide(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
