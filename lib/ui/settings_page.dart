import 'package:autonitor/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _historyLimitController;
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

  Widget build(BuildContext context) {
    // 1. 获取 l10n (您可能需要导入 'l10n/app_localizations.dart')
    final l10n = AppLocalizations.of(context)!;

    // 2. 监听 settingsProvider
    final settingsValue = ref.watch(settingsProvider);

    // 3. 返回一个 Scaffold
    return Scaffold(
      // 4. 添加 AppBar
      appBar: AppBar(title: Text(l10n.settings)),
      // 5. body 是之前的 .when() 逻辑
      body: settingsValue.when(
        // 加载中状态：显示一个加载指示器
        loading: () => const Center(child: CircularProgressIndicator()),
        // 错误状态：显示错误信息
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('加载设置失败: $error'),
          ),
        ),
        // 数据加载成功状态
        data: (settings) {
          // 构建设置列表 UI
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
                  l10n.general, // (From l10n)
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                dense: true,
              ),
              ListTile(
                title: Text(l10n.language),
                leading: Icon(Icons.language),
                trailing: DropdownButton<String>(
                  alignment: Alignment.centerRight,
                  // 1. 当前选中的值：从 Provider 读取
                  value: settings.locale?.toLanguageTag() ?? 'Auto',

                  // 2. 下拉菜单的选项：创建一个包含所有可选语言的列表
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
                    ), // value 是 'zh-CN'
                    DropdownMenuItem<String>(
                      value: 'zh-TW',
                      child: Text('中文（台灣）'),
                    ), // value 是 'zh-TW'
                  ],

                  // 3. 当用户选择了新选项时的回调函数
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      Locale? newLocale; // 声明 newLocale
                      if (newValue == 'Auto') {
                        newLocale = null; // Auto 对应 null Locale
                      } else if (newValue == 'en') {
                        newLocale = const Locale('en');
                      } else if (newValue == 'zh-CN') {
                        newLocale = const Locale(
                          'zh',
                          'CN',
                        ); // 创建 Locale('zh', 'CN')
                      } else if (newValue == 'zh-TW') {
                        newLocale = const Locale('zh', 'TW');
                      }

                      // 调用 updateLocale 传入 Locale?
                      ref
                          .read(settingsProvider.notifier)
                          .updateLocale(newLocale);
                      // 更新提示文本（查找显示名称）
                      // Removed unused variable 'displaySelected'
                    }
                  },

                  // 4. (可选) 移除下拉按钮下划线，让它更简洁
                  underline: Container(),
                ),
                // 从加载的设置中获取语言并显示
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
                  l10n.storage_settings, // (From l10n)
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.history_strategy,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              // (Radio button 1: Save All)
              // (单选按钮 1: 全部保存)
              RadioListTile<HistoryStrategy>(
                title: Text(l10n.strategy_save_all),
                value: HistoryStrategy.saveAll,
                groupValue:
                    settings.historyStrategy, // (The currently selected value)
                // (当前选中的值)
                onChanged: (HistoryStrategy? newValue) {
                  if (newValue != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateHistoryStrategy(newValue);
                  }
                },
              ),

              // (Radio button 2: Save Latest)
              // (单选按钮 2: 仅保存最新)
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

              // (Radio button 3: Save Last N)
              // (单选按钮 3: 保存 N 个)
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

                // --- MODIFICATION: Title is now a complex Row ---
                // (修改：标题现在是一个复杂的 Row)
                title: Wrap(
                  // <--- This is the solution
                  // (Align items vertically in the middle, in case of wrapping)
                  // (如果换行，保持垂直居中)
                  crossAxisAlignment: WrapCrossAlignment.center,

                  // (Set horizontal spacing between elements)
                  // (设置元素之间的水平间距)
                  spacing: 2.0,

                  // (Set vertical spacing if it wraps to a new line)
                  // (如果换行，设置垂直间距)
                  runSpacing: 4.0,
                  children: [
                    // 1. The Prefix Text ("Save Last")
                    // (1. 前缀文本 ("保存最近"))
                    Text(
                      l10n.strategy_save_last_n,
                      // (This text never turns grey)
                      // (这个文本永远不会变灰)
                    ),

                    const SizedBox(width: 8), // (Spacing)
                    // 2. The Input Box
                    // (2. 输入框)
                    SizedBox(
                      width: 60, // (Adjust width)
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
                          isDense: true, // (Makes it shorter)
                        ),

                        // (Save logic remains the same)
                        // (保存逻辑保持不变)
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

                    const SizedBox(width: 6), // (Spacing)
                    // 3. The Suffix Text ("Changes")
                    // (3. 后缀文本 ("次更改"))
                    Text(l10n.strategy_save_last_n_suffix),
                  ],
                ),
              ),
              // 未来可以在这里添加其他设置项...
            ],
          );
        },
      ),
    );
  }
}
