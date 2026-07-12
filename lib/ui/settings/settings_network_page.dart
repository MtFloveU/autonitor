part of 'settings_page.dart';

Widget _buildNetworkSection(
  BuildContext context,
  AppLocalizations l10n,
  VoidCallback onGqlPathTap,
  VoidCallback onGeneratorTap,
  WidgetRef ref,
  AppSettings settings,
  TextEditingController remoteFastApiUrlController,
  TextEditingController fastApiApiKeyController,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  String? validateRemoteFastApiUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    final isValid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    return isValid ? null : l10n.invalid_fastapi_url;
  }

  bool isValidRemoteFastApiUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  if (remoteFastApiUrlController.text != settings.remoteFastApiUrl) {
    remoteFastApiUrlController.text = settings.remoteFastApiUrl;
  }
  if (fastApiApiKeyController.text != settings.fastApiApiKey) {
    fastApiApiKeyController.text = settings.fastApiApiKey;
  }

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
      _SettingsDropdownTile<String>(
        title: l10n.api_request_mode,
        icon: Icons.code_outlined,
        currentValue: settings.apiRequestMode,
        helpText: "",
        options: {
          "dio": "dio",
          "curl_cffi": "curl_cffi",
        },
        onChanged: (newValue) {
          if (newValue == null) return;
          ref.read(settingsProvider.notifier).updateApiRequestMode(newValue);
        },
      ),
      if (settings.apiRequestMode == "curl_cffi") ...[
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.remote_fastapi_service_url,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: remoteFastApiUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: l10n.remote_fastapi_service_url,
                    hintText: 'https://example.com',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: validateRemoteFastApiUrl,
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (isValidRemoteFastApiUrl(trimmed)) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateRemoteFastApiUrl(trimmed);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.fastapi_api_key,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: fastApiApiKeyController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.fastapi_api_key,
                    hintText: l10n.fastapi_api_key_optional,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateFastApiApiKey(value.trim());
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}
