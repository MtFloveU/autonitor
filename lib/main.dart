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
import 'package:autonitor/theme/app_theme.dart';

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


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsValue = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final userThemeColorEnum = settingsValue.when(
          data: (s) => s.theme,
          loading: () => ThemeColor.defaultThemeColor,
          error: (_, _) => ThemeColor.defaultThemeColor,
        );

        final lightScheme = AppTheme.getLightScheme(
          userThemeColor: userThemeColorEnum,
          lightDynamic: lightDynamic,
        );

        final darkScheme = AppTheme.getDarkScheme(
          userThemeColor: userThemeColorEnum,
          darkDynamic: darkDynamic,
        );

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
