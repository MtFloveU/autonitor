import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/ui/main_scaffold.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'services/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  // 4. 添加 WidgetRef ref
  Widget build(BuildContext context, WidgetRef ref) {
    // 5. 监听设置
    final settingsValue = ref.watch(settingsProvider);

    return MaterialApp(
      onGenerateTitle: (context) {
        return AppLocalizations.of(context)?.app_title ?? 'Autonitor';
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settingsValue.when(
        loading: () => ThemeMode.system,
        error: (e, s) => ThemeMode.system,
        data: (settings) => settings.themeMode,
      ),
      home: const MainScaffold(),

      // --- 本地化配置 ---
      localizationsDelegates: const [
        AppLocalizations.delegate, // 你生成的 AppLocalizations 代理
        GlobalMaterialLocalizations.delegate, // Material 组件的默认本地化
        GlobalWidgetsLocalizations.delegate, // Widget 的默认本地化 (如文本方向)
        GlobalCupertinoLocalizations.delegate, // Cupertino 组件的本地化 (如果用到)
      ],
      // 6. 更新 supportedLocales
      supportedLocales: const [
        Locale('en'), // 英语
        Locale('zh', 'CN'), // 简体中文
        Locale('zh', 'TW'), // 繁體中文
        Locale('zh'), // 基础中文 (作为 fallback)
      ],

      // 7. 设置 locale 属性
      locale: settingsValue.when(
        loading: () => null, // 加载中，使用系统默认
        error: (e, s) => null, // 出错，使用系统默认
        data: (settings) =>
            settings.locale, // 使用 Provider 中的 Locale (null 表示 Auto/系统默认)
      ),
    );
  }
}
