part of '../settings_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Autonitor',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  );
                }
                return const SizedBox(height: 20);
              },
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                l10n.app_description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildAboutLink(
                    context,
                    icon: Icons.alternate_email,
                    title: l10n.author_on_twitter,
                    subtitle: '@Ak1raQ_love',
                    onTap: () =>
                        _openTwitterProfile(context, screenName: 'Ak1raQ_love'),
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: colorScheme.outlineVariant,
                  ),
                  _buildAboutLink(
                    context,
                    icon: Icons.code_outlined,
                    title: l10n.source_code,
                    subtitle: l10n.view_on_github,
                    url: 'https://github.com/MtFloveU/autonitor',
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: colorScheme.outlineVariant,
                  ),
                  _buildAboutLink(
                    context,
                    icon: Icons.bug_report_outlined,
                    title: l10n.report_an_issue,
                    subtitle: l10n.feedback_and_suggestions,
                    url: 'https://github.com/MtFloveU/autonitor/issues/new',
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: colorScheme.outlineVariant,
                  ),
                  _buildAboutLink(
                    context,
                    icon: Icons.description_outlined,
                    title: l10n.license,
                    subtitle: l10n.open_source_licenses,
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l10n.app_title,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(
              '© 2026 阿弃喵. All rights reserved.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutLink(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? url,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha((0.4 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: colorScheme.outlineVariant,
      ),
      onTap: onTap ?? (url != null ? () => launchUrl(Uri.parse(url)) : null),
    );
  }
}

Future<void> _openTwitterProfile(
  BuildContext context, {
  required String screenName,
}) async {
  if (screenName.isEmpty) return;

  final appUrl = Uri.parse('twitter://user?screen_name=$screenName');
  final webUrl = Uri.parse('https://x.com/$screenName');

  if (await canLaunchUrl(appUrl)) {
    await launchUrl(appUrl);
  } else {
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }
}
