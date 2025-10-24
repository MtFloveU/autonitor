import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
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
          return ListView(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.general,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              ListTile(
                title: Text(l10n.language),
                leading: Icon(Icons.language),
                trailing: DropdownButton<String>(
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
                      String displaySelected = 'Auto';
                      // Default
                      if (newValue == 'en') displaySelected = 'English';
                      if (newValue == 'zh-CN') displaySelected = '中文（中国）';
                      if (newValue == 'zh-TW') displaySelected = '中文（台灣）';
                    }
                  },

                  // 4. (可选) 移除下拉按钮下划线，让它更简洁
                  underline: Container(),
                ),
                // 从加载的设置中获取语言并显示
              ),
              // 未来可以在这里添加其他设置项...
            ],
          );
        },
      ),
    );
  }
}
