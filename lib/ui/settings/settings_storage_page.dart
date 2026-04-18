part of 'settings_page.dart';

Widget _buildStorageSection(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
  AppLocalizations l10n,
  TextEditingController historyController,
  void Function(WidgetRef, int) onLimitUpdate,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(context, l10n.storage_settings),
      SwitchListTile(
        secondary: Icon(
          Icons.person_outline_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(l10n.save_avatar_history),
        value: settings.saveAvatarHistory,
        onChanged: (v) =>
            ref.read(settingsProvider.notifier).updateSaveAvatarHistory(v),
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
              ref.read(settingsProvider.notifier).updateAvatarQuality(v);
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
          ref.read(settingsProvider.notifier).updateSaveBannerHistory(newValue);
        },
      ),

    ],
  );
}