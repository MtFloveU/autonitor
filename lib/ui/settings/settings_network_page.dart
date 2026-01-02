part of 'settings_page.dart';

Widget _buildNetworkSection(
  BuildContext context,
  AppLocalizations l10n,
  VoidCallback onGqlPathTap,
  VoidCallback onGeneratorTap,
) {
  final colorScheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(context, l10n.api_request_settings),
      ListTile(
        leading: Icon(Icons.api_outlined, color: colorScheme.onSurfaceVariant),
        title: Text(l10n.graphql_path_config),
        onTap: onGqlPathTap,
      ),
      ListTile(
        leading: Icon(
          Icons.build_circle_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(l10n.xclient_generator_title),
        onTap: onGeneratorTap,
      ),
    ],
  );
}
