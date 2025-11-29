import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:autonitor/ui/main_scaffold.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'services/database.dart';

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
  }
}
