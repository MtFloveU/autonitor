import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:autonitor/models/app_settings.dart';
import 'package:autonitor/ui/main_scaffold.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'services/database.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // [Helper] 将 ThemeColor 枚举转换为 Flutter Color
  Color? _getSeedColor(ThemeColor colorEnum) {
    switch (colorEnum) {
      case ThemeColor.defaultThemeColor:
        return null; // 返回 null 以指示使用系统/动态颜色
      case ThemeColor.red:
        return Colors.red;
      case ThemeColor.pink:
        return Colors.pink;
      case ThemeColor.purple:
        return Colors.purple;
      case ThemeColor.deepPurple:
        return Colors.deepPurple;
      case ThemeColor.indigo:
        return Colors.indigo;
      case ThemeColor.blue:
        return Colors.blue;
      case ThemeColor.lightBlue:
        return Colors.lightBlue;
      case ThemeColor.cyan:
        return Colors.cyan;
      case ThemeColor.teal:
        return Colors.teal;
      case ThemeColor.green:
        return Colors.green;
      case ThemeColor.lightGreen:
        return Colors.lightGreen;
      case ThemeColor.lime:
        return Colors.lime;
      case ThemeColor.yellow:
        return Colors.yellow;
      case ThemeColor.amber:
        return Colors.amber;
      case ThemeColor.orange:
        return Colors.orange;
      case ThemeColor.deepOrange:
        return Colors.deepOrange;
      case ThemeColor.brown:
        return Colors.brown;
      case ThemeColor.grey:
        return Colors.grey;
      case ThemeColor.blueGrey:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsValue = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 1. 获取用户设置的主题颜色
        final userThemeColorEnum = settingsValue.when(
          data: (s) => s.theme,
          loading: () => ThemeColor.defaultThemeColor,
          error: (_, _) => ThemeColor.defaultThemeColor,
        );

        // 2. 将枚举转换为实际的 Color 对象
        final Color? userSeedColor = _getSeedColor(userThemeColorEnum);

        ColorScheme lightScheme;
        ColorScheme darkScheme;

        // [逻辑更新]
        // 如果用户选择了特定颜色 (userSeedColor != null)，则强制使用该颜色生成 Scheme。
        // 如果用户选择 "Follow System" (userSeedColor == null):
        //    - Android 且支持动态取色 -> 使用 lightDynamic/darkDynamic (混合策略)
        //    - 其他情况 -> 使用默认的 deepPurple

        if (userSeedColor != null) {
          // A. 用户指定了颜色 -> 强制使用
          lightScheme = ColorScheme.fromSeed(
            seedColor: userSeedColor,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: userSeedColor,
            brightness: Brightness.dark,
          );
        } else {
          // B. 用户选择跟随系统 (默认)
          bool useDynamicColor = false;
          if (!kIsWeb && Platform.isAndroid) {
            useDynamicColor = true;
          }

          // ------------------ Light Theme ------------------
          if (useDynamicColor && lightDynamic != null) {
            // [混合策略]
            // 1. 先用系统主色生成一套标准的 Flutter MD3 色盘 (保证灰色系对比度)
            final baseScheme = ColorScheme.fromSeed(
              seedColor: lightDynamic.primary,
              brightness: Brightness.light,
            );

            // 2. 覆盖关键品牌色，确保与系统一致
            lightScheme = baseScheme.copyWith(
              primary: lightDynamic.primary,
              onPrimary: lightDynamic.onPrimary,
              primaryContainer: lightDynamic.primaryContainer,
              onPrimaryContainer: lightDynamic.onPrimaryContainer,
              secondary: lightDynamic.secondary,
              onSecondary: lightDynamic.onSecondary,
              secondaryContainer: lightDynamic.secondaryContainer,
              onSecondaryContainer: lightDynamic.onSecondaryContainer,
              tertiary: lightDynamic.tertiary,
              onTertiary: lightDynamic.onTertiary,
              tertiaryContainer: lightDynamic.tertiaryContainer,
              onTertiaryContainer: lightDynamic.onTertiaryContainer,
              error: lightDynamic.error,
              onError: lightDynamic.onError,
              errorContainer: lightDynamic.errorContainer,
              onErrorContainer: lightDynamic.onErrorContainer,
            );
          } else {
            // 默认 fallback
            lightScheme = ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            );
          }

          // ------------------ Dark Theme ------------------
          if (useDynamicColor && darkDynamic != null) {
            // [混合策略] - Dark
            final baseScheme = ColorScheme.fromSeed(
              seedColor: darkDynamic.primary,
              brightness: Brightness.dark,
            );

            darkScheme = baseScheme.copyWith(
              primary: darkDynamic.primary,
              onPrimary: darkDynamic.onPrimary,
              primaryContainer: darkDynamic.primaryContainer,
              onPrimaryContainer: darkDynamic.onPrimaryContainer,
              secondary: darkDynamic.secondary,
              onSecondary: darkDynamic.onSecondary,
              secondaryContainer: darkDynamic.secondaryContainer,
              onSecondaryContainer: darkDynamic.onSecondaryContainer,
              tertiary: darkDynamic.tertiary,
              onTertiary: darkDynamic.onTertiary,
              tertiaryContainer: darkDynamic.tertiaryContainer,
              onTertiaryContainer: darkDynamic.onTertiaryContainer,
              error: darkDynamic.error,
              onError: darkDynamic.onError,
              errorContainer: darkDynamic.errorContainer,
              onErrorContainer: darkDynamic.onErrorContainer,
            );
          } else {
            darkScheme = ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            );
          }
        }

        const pageTransitionsTheme = PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        );

        return MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateTitle: (context) {
            return AppLocalizations.of(context)?.app_title ?? 'Autonitor';
          },

          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            pageTransitionsTheme: pageTransitionsTheme,
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: darkScheme,
            useMaterial3: true,
            pageTransitionsTheme: pageTransitionsTheme,
          ),

          themeMode: settingsValue.when(
            loading: () => ThemeMode.system,
            error: (e, s) => ThemeMode.system,
            data: (settings) => settings.themeMode,
          ),

          builder: (context, child) {
            return CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () {
                  navigatorKey.currentState?.maybePop();
                },
              },
              child: child ?? const SizedBox(),
            );
          },

          home: const MainScaffold(),

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [
            Locale('en'),
            Locale('zh', 'CN'),
            Locale('zh', 'TW'),
            Locale('zh'),
          ],

          locale: settingsValue.when(
            loading: () => null,
            error: (e, s) => null,
            data: (settings) => settings.locale,
          ),
        );
      },
    );
  }
}
