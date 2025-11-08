import 'package:autonitor/models/app_settings.dart';
import 'package:autonitor/providers/x_client_transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
// 1. (新) 导入 Service 只是为了类型提示
import '../services/x_client_transaction_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _historyLimitController;

  void _showGenerateDialog() {
    final TextEditingController countController = TextEditingController(
      text: '1',
    );
    // (新) 为 Path 添加 Controller
    final TextEditingController pathController = TextEditingController(
      text: '/i/api/graphql/Efm7xwLreAw77q2Fq7rX-Q/Followers',
    );
    final TextEditingController resultController = TextEditingController();
    final ValueNotifier<bool> isGenerating = ValueNotifier<bool>(false);
    final l10n = AppLocalizations.of(context)!;
    bool _isCanceled = false;

    // 捕获 StatefulBuilder 的 setState 函数
    late StateSetter dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          // 允许通过返回键关闭，并在关闭时设置取消标志
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              _isCanceled = true; // 设置取消标志
            }
          },
          child: StatefulBuilder(
            builder: (context, setState) {
              dialogSetState = setState;

              return AlertDialog(
                title: Text(l10n.xclient_generator_title),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- 数量输入框 ---
                      Row(
                        children: [
                          Expanded(child: Text(l10n.num_ids_to_generate)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: countController,
                              keyboardType: TextInputType.number,
                              // ------------------------------------------------
                              // (关键修改) 1. 添加 InputFormatters
                              // ------------------------------------------------
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                NumberRangeInputFormatter(min: 1, max: 100),
                              ],
                              // ------------------------------------------------
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // (新) Path 输入框
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'https://x.com',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 关键：让输入框在一行内可伸缩
                          Flexible(
                            child: TextField(
                              controller: pathController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: l10n.url_path_label,
                                isDense: true,
                                // 可选：如果想让边框靠近文字一点
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- 结果框 (保持不变) ---
                    Container(
                      width: double.maxFinite,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: resultController,
                          readOnly: true,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                actions: [
                  // 1. 取消/关闭按钮 (保持不变)
                  TextButton(
                    onPressed: () {
                      _isCanceled = true; // 立即设置取消标志
                      Navigator.pop(dialogContext);
                    },
                    child: Text(l10n.close),
                  ),

                  // 2. 生成按钮
                  ValueListenableBuilder<bool>(
                    valueListenable: isGenerating,
                    builder: (context, generating, _) {
                      final theme = Theme.of(context);
                      return ElevatedButton(
                        // (核心逻辑已在上一轮修改)
                        onPressed: generating
                            ? null
                            : () async {
                                final input = countController.text.trim();
                                final count = int.tryParse(input);
                                final path = pathController.text.trim();

                                // --- (校验) ---
                                // 这里的校验仍然是必要的，因为用户可能输入了空字符串
                                if (count == null || count <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.please_enter_valid_number,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (path.isEmpty || !path.startsWith('/')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.path_must_start_with_slash,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                // --- (校验结束) ---

                                isGenerating.value = true;
                                _isCanceled = false; // 重置取消标志

                                dialogSetState(() {
                                  resultController.text =
                                      l10n.fetching_resources;
                                });

                                try {
                                  // 步骤 1: (仅一次网络请求)
                                  final XClientTransactionService service =
                                      await ref.read(xctServiceProvider.future);

                                  if (_isCanceled) throw Exception("Canceled");

                                  dialogSetState(() {
                                    resultController.text =
                                        "Generating $count IDs (local)...";
                                  });
                                  await Future.delayed(
                                    const Duration(milliseconds: 50),
                                  );

                                  List<String> generatedIds = [];

                                  // 步骤 2: (本地循环)
                                  for (int i = 0; i < count; i++) {
                                    if (_isCanceled) {
                                      generatedIds.add("\n--- CANCELED ---");
                                      break;
                                    }

                                    final id = service.generateTransactionId(
                                      method: 'GET',
                                      url: "https://x.com$path",
                                    );

                                    generatedIds.add("${i + 1}. $id");

                                    dialogSetState(() {
                                      resultController.text = generatedIds.join(
                                        '\n\n',
                                      );
                                    });

                                    if (count > 10 && i % 10 == 0) {
                                      await Future.delayed(
                                        const Duration(milliseconds: 1),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  // (错误处理)
                                  final String errorMsg =
                                      (e is Exception && _isCanceled)
                                      ? l10n.generation_canceled
                                      : "ID Generation Failed: $e";

                                  if (mounted && !_isCanceled) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          errorMsg,
                                          style: TextStyle(
                                            color: theme.colorScheme.onError,
                                          ),
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                      ),
                                    );
                                  }

                                  if (context.mounted) {
                                    dialogSetState(() {
                                      resultController.text +=
                                          "\n\n--- ${errorMsg.replaceAll("\n", " ")} ---";
                                    });
                                  }
                                } finally {
                                  if (!_isCanceled) {
                                    isGenerating.value = false;
                                  }
                                  if (context.mounted) {
                                    dialogSetState(() {});
                                  }
                                }
                              },
                        child: generating
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.generating),
                                ],
                              )
                            : Text(l10n.generate),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    ).then((_) {
      // 对话框关闭后释放资源
      countController.dispose();
      pathController.dispose(); // (新) 释放 Path Controller
      resultController.dispose();
      isGenerating.dispose();
    });
  }

  @override
  void initState() {
    super.initState();
    _historyLimitController = TextEditingController();
  }

  @override
  void dispose() {
    _historyLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 获取 l10n
    final l10n = AppLocalizations.of(context)!;

    // 2. 监听 settingsProvider
    final settingsValue = ref.watch(settingsProvider);

    // 3. 返回一个 Scaffold
    return Scaffold(
      // 4. 添加 AppBar
      appBar: AppBar(title: Text(l10n.settings)),
      // 5. body 是 .when() 逻辑
      body: settingsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('加载设置失败: $error'),
          ),
        ),
        data: (settings) {
          // (构建设置列表 UI)
          final currentTextInField = _historyLimitController.text;
          final settingsValue = settings.historyLimitN.toString();
          if (currentTextInField != settingsValue) {
            _historyLimitController.text = settingsValue;
            _historyLimitController.selection = TextSelection.fromPosition(
              TextPosition(offset: _historyLimitController.text.length),
            );
          }

          return ListView(
            children: [
              ListTile(
                title: Text(
                  l10n.general,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                dense: true,
              ),
              ListTile(
                title: Text(l10n.language),
                leading: const Icon(Icons.language),
                trailing: DropdownButton<String>(
                  alignment: Alignment.centerRight,
                  value: settings.locale?.toLanguageTag() ?? 'Auto',
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Auto',
                      child: Text('Auto'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'en',
                      child: Text('English'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'zh-CN',
                      child: Text('中文（中国）'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'zh-TW',
                      child: Text('中文（台灣）'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      Locale? newLocale;
                      if (newValue == 'Auto') {
                        newLocale = null;
                      } else if (newValue == 'en') {
                        newLocale = const Locale('en');
                      } else if (newValue == 'zh-CN') {
                        newLocale = const Locale('zh', 'CN');
                      } else if (newValue == 'zh-TW') {
                        newLocale = const Locale('zh', 'TW');
                      }
                      ref
                          .read(settingsProvider.notifier)
                          .updateLocale(newLocale);
                    }
                  },
                  underline: Container(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(l10n.theme_mode),
                trailing: DropdownButton<ThemeMode>(
                  alignment: Alignment.centerRight,
                  value: settings.themeMode,
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n.theme_mode_system),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n.theme_mode_light),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n.theme_mode_dark),
                    ),
                  ],
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateThemeMode(newValue);
                    }
                  },
                  underline: Container(),
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(
                  l10n.api_request_settings,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                dense: true,
              ),
              ListTile(
                leading: const Icon(Icons.build_circle_outlined),
                title: Text(l10n.xclient_generator_title),
                trailing: const Icon(Icons.open_in_new),
                onTap: _showGenerateDialog,
              ),
              const Divider(),
              ListTile(
                title: Text(
                  l10n.storage_settings,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                dense: true,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.person_outline_outlined),
                title: Text(l10n.save_avatar_history),
                value: settings.saveAvatarHistory,
                onChanged: (bool newValue) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateSaveAvatarHistory(newValue);
                },
              ),
              ListTile(
                enabled: settings.saveAvatarHistory,
                leading: const Icon(null),
                title: Text(l10n.avatar_quality),
                trailing: DropdownButton<AvatarQuality>(
                  value: settings.avatarQuality,
                  items: [
                    DropdownMenuItem(
                      value: AvatarQuality.high,
                      child: Text(l10n.quality_high),
                    ),
                    DropdownMenuItem(
                      value: AvatarQuality.low,
                      child: Text(l10n.quality_low),
                    ),
                  ],
                  onChanged: settings.saveAvatarHistory
                      ? (AvatarQuality? newValue) {
                          if (newValue != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateAvatarQuality(newValue);
                          }
                        }
                      : null,
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.image_outlined),
                title: Text(l10n.save_banner_history),
                value: settings.saveBannerHistory,
                onChanged: (bool newValue) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateSaveBannerHistory(newValue);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.history_strategy,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              RadioListTile<HistoryStrategy>(
                title: Text(l10n.strategy_save_all),
                value: HistoryStrategy.saveAll,
                groupValue: settings.historyStrategy,
                onChanged: (HistoryStrategy? newValue) {
                  if (newValue != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateHistoryStrategy(newValue);
                  }
                },
              ),
              RadioListTile<HistoryStrategy>(
                title: Text(l10n.strategy_save_latest),
                value: HistoryStrategy.saveLatest,
                groupValue: settings.historyStrategy,
                onChanged: (HistoryStrategy? newValue) {
                  if (newValue != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateHistoryStrategy(newValue);
                  }
                },
              ),
              RadioListTile<HistoryStrategy>(
                value: HistoryStrategy.saveLastN,
                groupValue: settings.historyStrategy,
                onChanged: (HistoryStrategy? newValue) {
                  if (newValue != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateHistoryStrategy(newValue);
                  }
                },
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 2.0,
                  runSpacing: 4.0,
                  children: [
                    Text(l10n.strategy_save_last_n),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: _historyLimitController,
                        enabled:
                            settings.historyStrategy ==
                            HistoryStrategy.saveLastN,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 12.0,
                          ),
                          isDense: true,
                        ),
                        onEditingComplete: () {
                          final String value = _historyLimitController.text;
                          int n = int.tryParse(value) ?? 1;
                          if (n < 1) n = 1;
                          if (n > 500) n = 500;
                          ref
                              .read(settingsProvider.notifier)
                              .updateHistoryLimitN(n);
                          FocusScope.of(context).unfocus();
                        },
                        onTapOutside: (event) {
                          final String value = _historyLimitController.text;
                          int n = int.tryParse(value) ?? 1;
                          if (n < 1) n = 1;
                          if (n > 500) n = 500;
                          if (n != settings.historyLimitN) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateHistoryLimitN(n);
                          }
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(l10n.strategy_save_last_n_suffix),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(
                  l10n.log,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                dense: true,
              ),
              ListTile(
                leading: const Icon(Icons.view_list_outlined),
                title: Text(l10n.view_log),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  final logs = ref.read(logHistoryProvider);
                  final theme = Theme.of(context);
                  final logText = logs.join('\n');

                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(l10n.view_log),
                      content: Container(
                        width: double.maxFinite,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: SingleChildScrollView(
                          reverse: true,
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: TextEditingController(text: logText),
                            readOnly: true,
                            maxLines: null,
                            decoration: InputDecoration.collapsed(
                              hintText: null,
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: Text(l10n.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: logText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.copied_to_clipboard,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                              ),
                            );
                            Navigator.pop(dialogContext);
                          },
                        ),
                        TextButton(
                          child: Text(l10n.clear),
                          onPressed: () {
                            ref
                                .read(logHistoryNotifierProvider.notifier)
                                .clearLog();
                            Navigator.pop(dialogContext);
                          },
                        ),
                        TextButton(
                          child: Text(l10n.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ------------------------------------------------
// (关键修改) 2. 在文件末尾添加这个类
// ------------------------------------------------
/// 一个自定义的 [TextInputFormatter]，用于限制输入值为 [min] 和 [max] 之间的整数。
class NumberRangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  NumberRangeInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 允许空字符串（当用户清空输入框时）
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 尝试将新文本解析为整数
    final int? value = int.tryParse(newValue.text);

    // 如果无法解析（例如，只是一个"-")，则保留旧值
    // (虽然 digitsOnly 已经过滤了，但这是个好习惯)
    if (value == null) {
      return oldValue;
    }

    // 检查是否在范围内
    if (value >= min && value <= max) {
      return newValue; // 接受更改
    }

    // 如果值超出范围（例如输入 0 或 101），保留旧值
    return oldValue;
  }
}
