import 'package:autonitor/models/app_settings.dart';
import 'package:autonitor/models/graphql_operation.dart';
import 'package:autonitor/providers/auth_provider.dart';
import 'package:autonitor/providers/search_provider.dart';
import 'package:autonitor/providers/x_client_transaction_provider.dart';
import 'package:autonitor/ui/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/log_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../services/x_client_transaction_service.dart';
import '../providers/graphql_queryid_provider.dart';

// Custom InputFormatter to allow only numbers within a given range
class NumberRangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  NumberRangeInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final int? value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }
    if (value < min || value > max) {
      return oldValue;
    }
    return newValue;
  }
}

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

  // --- 页面跳转逻辑 ---
  void _openGeneratePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GeneratorPage()),
    );
  }

  void _openGqlPathPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GraphQLPathPage()),
    );
  }

  void _openLogPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogViewerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsValue = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: settingsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: $error'),
          ),
        ),
        data: (settings) {
          final settingsValue = settings.historyLimitN.toString();
          if (_historyLimitController.text.isEmpty ||
              (_historyLimitController.text != settingsValue &&
                  !_historyLimitController.selection.isValid)) {
            _historyLimitController.text = settingsValue;
          }

          return ListView(
            children: [
              _buildSectionHeader(context, l10n.general),

              _SettingsDropdownTile<String>(
                title: l10n.language,
                icon: Icons.language,
                currentValue: settings.locale?.toLanguageTag() ?? 'Auto',
                options: {
                  'Auto': l10n.follow_system,
                  'en': 'English',
                  'zh-CN': '中文（简体）',
                  'zh-TW': '中文（繁體）',
                },
                onChanged: (newValue) {
                  if (newValue == null) return;
                  Locale? locale;
                  if (newValue == 'en') {
                    locale = const Locale('en');
                  } else if (newValue == 'zh-CN') {
                    locale = const Locale('zh', 'CN');
                  } else if (newValue == 'zh-TW') {
                    locale = const Locale('zh', 'TW');
                  }
                  ref.read(settingsProvider.notifier).updateLocale(locale);
                },
              ),

              // 2. Theme Mode
              _SettingsDropdownTile<ThemeColor>(
                title: l10n.theme,
                icon: Icons.format_color_fill_outlined,
                currentValue: settings.theme,
                options: {
                  ThemeColor.defaultThemeColor: l10n.follow_system,
                  ThemeColor.red: l10n.color_red,
                  ThemeColor.pink: l10n.color_pink,
                  ThemeColor.purple: l10n.color_purple,
                  ThemeColor.deepPurple: l10n.color_deepPurple,
                  ThemeColor.indigo: l10n.color_indigo,
                  ThemeColor.blue: l10n.color_blue,
                  ThemeColor.lightBlue: l10n.color_lightBlue,
                  ThemeColor.cyan: l10n.color_cyan,
                  ThemeColor.teal: l10n.color_teal,
                  ThemeColor.green: l10n.color_green,
                  ThemeColor.lightGreen: l10n.color_lightGreen,
                  ThemeColor.lime: l10n.color_lime,
                  ThemeColor.yellow: l10n.color_yellow,
                  ThemeColor.amber: l10n.color_amber,
                  ThemeColor.orange: l10n.color_orange,
                  ThemeColor.deepOrange: l10n.color_deepOrange,
                  ThemeColor.brown: l10n.color_brown,
                  ThemeColor.grey: l10n.color_grey,
                  ThemeColor.blueGrey: l10n.color_blueGrey,
                },
                onChanged: (newValue) {
                  if (newValue != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateThemeColor(newValue);
                  }
                },
              ),
              _SettingsDropdownTile<ThemeMode>(
                title: l10n.theme_mode,
                icon: Icons.brightness_6_outlined,
                currentValue: settings.themeMode,
                options: {
                  ThemeMode.system: l10n.follow_system,
                  ThemeMode.light: l10n.theme_mode_light,
                  ThemeMode.dark: l10n.theme_mode_dark,
                },
                onChanged: (newValue) {
                  if (newValue != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateThemeMode(newValue);
                  }
                },
              ),

              _buildSectionHeader(context, l10n.api_request_settings),

              ListTile(
                leading: Icon(
                  Icons.api_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.graphql_path_config),
                onTap: _openGqlPathPage,
              ),
              ListTile(
                leading: Icon(
                  Icons.build_circle_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.xclient_generator_title),
                onTap: _openGeneratePage,
              ),

              _buildSectionHeader(context, l10n.storage_settings),

              SwitchListTile(
                secondary: Icon(
                  Icons.person_outline_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.save_avatar_history),
                value: settings.saveAvatarHistory,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .updateSaveAvatarHistory(v),
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
                      ref
                          .read(settingsProvider.notifier)
                          .updateAvatarQuality(v);
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
                controller: _historyLimitController,
              ),
              _buildSectionHeader(context, l10n.search),
              ListTile(
                leading: Icon(
                  Icons.search_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.filter),
                onTap: () {
                  final activeAccount = ref.read(activeAccountProvider);
                  if (activeAccount == null) return;

                  // 这里需要自己创建 SearchParam
                  final initialParam = SearchParam(
                    ownerId: activeAccount.id,
                    query: '',
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SearchFiltersPage(initialParam: initialParam),
                    ),
                  ).then((result) {
                    if (result != null && result is SearchParam) {
                      // 处理返回的筛选结果
                      // 例如传给上层 Provider 或 setState
                    }
                  });
                },
              ),
              _buildSectionHeader(context, l10n.log),

              ListTile(
                leading: Icon(
                  Icons.view_list_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.view_log),
                onTap: _openLogPage,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 辅助方法：Section Header (MD3 Style)
// ---------------------------------------------------------------------------
Widget _buildSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 一体化设置项：_SettingsDropdownTile
// ---------------------------------------------------------------------------
class _SettingsDropdownTile<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final T currentValue;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  const _SettingsDropdownTile({
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_SettingsDropdownTile<T>> createState() =>
      _SettingsDropdownTileState<T>();
}

class _SettingsDropdownTileState<T> extends State<_SettingsDropdownTile<T>>
  with SingleTickerProviderStateMixin {
  final GlobalKey _dropdownKey = GlobalKey();

  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
  super.initState();
  _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  _scaleAnim = Tween<double>(begin: 1.0, end: 1.06)
    .chain(CurveTween(curve: Curves.easeOutBack))
    .animate(_animController);
  }

  @override
  void dispose() {
  _animController.dispose();
  super.dispose();
  }

  // 原始逻辑：触发 Dropdown 的内部 GestureDetector（保持不变）
  void _triggerDropdown() {
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

  // 对外的 open 接口：同时触发原始下拉与文本放大动画（不改变位置/行为）
  void _openDropdown() {
  // 先触发下拉（保持原行为和位置）
  _triggerDropdown();

  // 同步播放文字弹出/放大动画，制造菜单打开感
  _animController
    ..stop()
    ..forward(from: 0.0).then((_) {
    if (mounted) _animController.reverse();
    });
  }

  @override
  void didUpdateWidget(covariant _SettingsDropdownTile<T> oldWidget) {
  super.didUpdateWidget(oldWidget);
  // 当选择发生变化也播放一次弹出动画（像很多开源项目那样）
  if (oldWidget.currentValue != widget.currentValue) {
    _animController
    ..stop()
    ..forward(from: 0.0).then((_) {
      if (mounted) _animController.reverse();
    });
  }
  }

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  // 获取 entries 列表以便使用 index
  final entries = widget.options.entries.toList();

  return ListTile(
    leading: Icon(widget.icon, color: colorScheme.onSurfaceVariant),
    title: Text(widget.title, style: textTheme.bodyLarge),
    onTap: _openDropdown, // 点击整个列表项触发（保持原行为）
    subtitle: Align(
    alignment: Alignment.centerLeft,
    child: IgnorePointer(
      // 忽略 DropdownButton 自身的点击，统一由 ListTile 处理
      child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: _dropdownKey,
        isExpanded: false, // 宽度自适应内容
        isDense: true,
        value: widget.currentValue,
        focusColor: Colors.transparent, // 禁用焦点色
        items: List.generate(entries.length, (index) {
        final entry = entries[index];
        return DropdownMenuItem<T>(
          value: entry.key,
          child: Text(
          entry.value,
          style: textTheme.bodyMedium, // 统一文字大小
          overflow: TextOverflow.ellipsis,
          ),
        );
        }),
        onChanged: widget.onChanged,
        selectedItemBuilder: (context) {
        // 包装成 ScaleTransition，使显示的文字在打开/变更时有弹出效果
        return widget.options.entries.map((entry) {
          return ScaleTransition(
          scale: _scaleAnim,
          child: Text(
            entry.value,
            key: ValueKey<String>(entry.value),
            style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          );
        }).toList();
        },
        icon: const SizedBox.shrink(),
        dropdownColor: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        ),
      ),
      ),
    ),
    ),
  );
  }
}

// ---------------------------------------------------------------------------
// 历史记录策略 Tile (含优化后的输入框逻辑)
// ---------------------------------------------------------------------------
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

    // 获取 entries 列表以便使用 index
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
                  isExpanded: true, // 设置为 true 以限制宽度防止溢出
                  isDense: true,
                  value: widget.settings.historyStrategy,
                  focusColor: Colors.transparent, // 禁用焦点色
                  items: List.generate(entries.length, (index) {
                    final entry = entries[index];
                    return DropdownMenuItem<HistoryStrategy>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: textTheme.bodyMedium, // 统一文字大小
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
                        overflow: TextOverflow.ellipsis, // 防止溢出
                        maxLines: 1, // 限制单行
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

        // 优化后的输入框显示
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
                    ), // 修复: 使用 withValues(alpha: ...)
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

// ---------------------------------------------------------------------------
// 新增页面：GeneratorPage (原 _showGenerateDialog)
// ---------------------------------------------------------------------------
class GeneratorPage extends ConsumerStatefulWidget {
  const GeneratorPage({super.key});

  @override
  ConsumerState<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends ConsumerState<GeneratorPage> {
  late TextEditingController countController;
  late TextEditingController pathController;
  late TextEditingController resultController;
  late ValueNotifier<bool> isGenerating;
  String selectedMethod = "GET";
  bool isCanceled = false;

  @override
  void initState() {
    super.initState();
    countController = TextEditingController(text: '1');
    pathController = TextEditingController(
      text: 'https://api.x.com/graphql/Efm7xwLreAw77q2Fq7rX-Q/Followers',
    );
    resultController = TextEditingController();
    isGenerating = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    countController.dispose();
    pathController.dispose();
    resultController.dispose();
    isGenerating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          isCanceled = true;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.xclient_generator_title)),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l10n.num_ids_to_generate)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: countController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              NumberRangeInputFormatter(min: 1, max: 100),
                            ],
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pathController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelText: 'API Path / URL',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedMethod,
                              borderRadius: BorderRadius.circular(12),
                              items: const [
                                DropdownMenuItem(
                                  value: 'GET',
                                  child: Text('GET'),
                                ),
                                DropdownMenuItem(
                                  value: 'POST',
                                  child: Text('POST'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedMethod = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.maxFinite,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: TextField(
                        controller: resultController,
                        readOnly: true,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.all(12),
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: isGenerating,
                    builder: (context, generating, _) {
                      return FilledButton.tonal(
                        onPressed: generating ? null : _startGeneration,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startGeneration() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final input = countController.text.trim();
    final count = int.tryParse(input);
    final path = pathController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (count == null || count <= 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.please_enter_valid_number),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (Uri.tryParse(path)?.hasScheme != true ||
        Uri.tryParse(path)?.hasAuthority != true ||
        !(Uri.tryParse(path)?.scheme == 'http' ||
            Uri.tryParse(path)?.scheme == 'https')) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.path_must_start_with_slash),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    isGenerating.value = true;
    isCanceled = false;

    setState(() {
      resultController.text = l10n.fetching_resources;
    });

    try {
      final XClientTransactionService service = await ref.read(
        xctServiceProvider.future,
      );

      if (isCanceled) throw Exception("Canceled");

      setState(() {
        resultController.text = "Generating $count IDs (local)...";
      });
      await Future.delayed(const Duration(milliseconds: 50));

      List<String> generatedIds = [];

      for (int i = 0; i < count; i++) {
        if (isCanceled) {
          generatedIds.add("\n--- CANCELED ---");
          break;
        }

        final id = service.generateTransactionId(
          method: selectedMethod,
          url: path,
        );

        generatedIds.add("${i + 1}. $id");

        setState(() {
          resultController.text = generatedIds.join('\n\n');
        });

        if (count > 10 && i % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    } catch (e) {
      final String errorMsg = (e is Exception && isCanceled)
          ? l10n.generation_canceled
          : "ID Generation Failed: $e";

      if (mounted && !isCanceled) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: TextStyle(color: theme.colorScheme.onError),
            ),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (mounted) {
        setState(() {
          resultController.text +=
              "\n\n--- ${errorMsg.replaceAll("\n", " ")} ---";
        });
      }
    } finally {
      if (!isCanceled) {
        isGenerating.value = false;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 新增页面：GraphQLPathPage (原 GraphQLPathDialog)
// ---------------------------------------------------------------------------
class GraphQLPathPage extends ConsumerStatefulWidget {
  const GraphQLPathPage({super.key});

  @override
  ConsumerState<GraphQLPathPage> createState() => _GraphQLPathPageState();
}

class _GraphQLPathPageState extends ConsumerState<GraphQLPathPage> {
  late final Map<String, TextEditingController> _pathControllers;

  @override
  void initState() {
    super.initState();
    final targetOperations = ref
        .read(gqlQueryIdProvider.notifier)
        .targetOperations;
    _pathControllers = {
      for (var name in targetOperations) name: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _pathControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pathState = ref.watch(gqlQueryIdProvider);
    final pathNotifier = ref.read(gqlQueryIdProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCustom = pathState.source == QueryIdSource.custom;
    for (final opName in pathNotifier.targetOperations) {
      final path = isCustom
          ? pathState.customQueryIds[opName] ?? ''
          : pathNotifier.getCurrentQueryIdForDisplay(opName);
      if (_pathControllers.containsKey(opName)) {
        if (_pathControllers[opName]!.text != path) {
          _pathControllers[opName]!.text = path;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.graphql_path_config)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.xclient_generator_source,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<QueryIdSource>(
                            value: pathState.source,
                            borderRadius: BorderRadius.circular(12),
                            items: QueryIdSource.values.map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e == QueryIdSource.apiDocument
                                      ? 'TIAD'
                                      : 'Custom',
                                ),
                              );
                            }).toList(),
                            onChanged: pathState.isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      pathNotifier.setSource(value);
                                    }
                                  },
                          ),
                        ),
                        if (!isCustom)
                          IconButton(
                            icon: const Icon(Icons.link_outlined),
                            tooltip: 'View Source',
                            onPressed: () {
                              launchUrl(
                                Uri.parse(
                                  'https://github.com/fa0311/TwitterInternalAPIDocument/tree/develop',
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  if (pathState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Error: ${pathState.error}',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ...pathNotifier.targetOperations.map((opName) {
                    final isCustom = pathState.source == QueryIdSource.custom;
                    final controller = _pathControllers[opName]!;
                    final bool readOnly = !isCustom || pathState.isLoading;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controller,
                        readOnly: readOnly,
                        onChanged: (newQueryId) {
                          if (isCustom) {
                            pathNotifier.updateCustomQueryId(
                              opName,
                              newQueryId,
                            );
                          }
                        },
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: opName,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(12),
                          filled: readOnly,
                          fillColor: readOnly
                              ? colorScheme.surfaceContainerLow
                              : null,
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: pathState.isLoading
                      ? null
                      : pathState.source == QueryIdSource.apiDocument
                      ? () => pathNotifier.loadApiData(context)
                      : pathNotifier.resetCustomQueryIds,
                  child: pathState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          pathState.source == QueryIdSource.apiDocument
                              ? l10n.refresh
                              : l10n.reset,
                        ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 新增页面：LogViewerPage
// ---------------------------------------------------------------------------
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
              // constraints: BoxConstraints(
              //   maxHeight: MediaQuery.of(context).size.height * 0.7,
              // ), // 页面模式下不需要限制高度
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
