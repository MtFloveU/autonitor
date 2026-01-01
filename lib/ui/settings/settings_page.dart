import 'package:autonitor/models/app_settings.dart';
import 'package:autonitor/models/graphql_operation.dart';
import 'package:autonitor/providers/x_client_transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/log_provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../services/x_client_transaction_service.dart';
import '../../providers/graphql_queryid_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 引入拆分后的各个部分
part 'settings_widget.dart';
part 'settings_general_page.dart';
part 'settings_logs_page.dart';
part 'settings_network_page.dart';
part 'settings_storage_page.dart';
part 'subpages/graphql_path_page.dart';
part 'subpages/log_viewer.dart';
part 'subpages/xct_generator_page.dart';
part 'subpages/settings_about_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _historyLimitController;

  @override
  void initState() {
    super.initState();
    _historyLimitController = TextEditingController();
  }

  // 页面跳转逻辑保持在主 State 中，或者也可以传参给子组件
  void _openGeneratePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GeneratorPage()),
    );
  }

  void _openGqlPathPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GraphQLPathPage()),
    );
  }

  void _openLogPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogViewerPage()),
    );
  }

  void _handleLimitUpdate(WidgetRef ref, int currentLimit) {
    final n = int.tryParse(_historyLimitController.text) ?? 1;
    final clampedN = n.clamp(1, 500);
    if (clampedN != currentLimit) {
      ref.read(settingsProvider.notifier).updateHistoryLimitN(clampedN);
    }
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsValue = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: settingsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: $error'),
          ),
        ),
        data: (settings) {
          final settingsValue = settings.historyLimitN.toString();
          if (_historyLimitController.text.isEmpty ||
              (_historyLimitController.text != settingsValue &&
                  !_historyLimitController.selection.isValid)) {
            _historyLimitController.text = settingsValue;
          }

          return ListView(
            children: [
              // 1. General Section
              _buildGeneralSection(context, ref, settings, l10n),

              // 2. Network / API Section
              _buildNetworkSection(
                context,
                l10n,
                _openGqlPathPage,
                _openGeneratePage,
              ),

              // 3. Storage Section
              _buildStorageSection(
                context,
                ref,
                settings,
                l10n,
                _historyLimitController,
                _handleLimitUpdate,
              ),

              // 4. Logs / Search Section
              _buildLogsSection(context, l10n, _openLogPage),
              // 5. About Section
              _buildSectionHeader(context, l10n.others),
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.about),
                subtitle: Text("${l10n.about} ${l10n.app_title}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
