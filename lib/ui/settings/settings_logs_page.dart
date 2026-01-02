part of 'settings_page.dart';

Widget _buildLogsSection(
  BuildContext context,
  AppLocalizations l10n,
  VoidCallback onLogTap,
) {
  final colorScheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(context, l10n.log),
      ListTile(
        leading: Icon(
          Icons.view_list_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(l10n.view_log),
        onTap: onLogTap,
      ),
    ],
  );
}
