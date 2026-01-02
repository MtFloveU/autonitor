part of 'settings_page.dart';

Widget _buildGeneralSection(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
  AppLocalizations l10n,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
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
            ref.read(settingsProvider.notifier).updateThemeColor(newValue);
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
            ref.read(settingsProvider.notifier).updateThemeMode(newValue);
          }
        },
      ),
    ],
  );
}
