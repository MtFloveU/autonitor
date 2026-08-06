import 'package:autonitor/ui/home/commits_page.dart';
import 'package:autonitor/ui/subpages/user/user_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:autonitor/models/twitter_user.dart';
import 'package:autonitor/models/cache_data.dart';
import 'package:autonitor/providers/auth_provider.dart';
import 'package:autonitor/providers/report_providers.dart';
import 'package:autonitor/providers/media_provider.dart';
import 'package:autonitor/ui/subpages/user/profile/user_detail_page.dart';
import 'package:autonitor/ui/components/user_avatar.dart';
import 'package:autonitor/models/app_settings.dart';
import 'package:autonitor/providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';
import 'analysis_page.dart';

// Declare parts
part 'home_widgets.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToAccounts;
  const HomePage({super.key, required this.onNavigateToAccounts});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeAccount = ref.watch(activeAccountProvider);
    final authState = ref.watch(activeAccountStateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.app_title)),
      body: !authState.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : activeAccount != null
          ? _buildAccountView(context)
          : _buildNoAccountState(context, widget.onNavigateToAccounts),
      floatingActionButton: activeAccount == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _chooseSyncMode,
              label: Text(l10n.run),
              icon: const Icon(Icons.sync_outlined),
            ),
    );
  }

  Future<void> _chooseSyncMode() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null) return;
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<SyncFetchMode>(
      context: context,
      builder: (dialogContext) {
        var selectedMode = settings.effectiveSyncFetchMode;
        final usesCurlCffi = settings.apiRequestMode == 'curl_cffi';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.sync_mode_title),
            content: RadioGroup<SyncFetchMode>(
              groupValue: selectedMode,
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() => selectedMode = value);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: SyncFetchMode.values.map((mode) {
                  final requiresCurlCffi = mode != SyncFetchMode.fast;
                  final enabled = !requiresCurlCffi || usesCurlCffi;
                  return RadioListTile<SyncFetchMode>(
                    value: mode,
                    enabled: enabled,
                    title: Text(_syncModeTitle(l10n, mode)),
                    subtitle: Text(
                      enabled
                          ? _syncModeDescription(l10n, mode)
                          : l10n.sync_mode_requires_curl_cffi,
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, selectedMode),
                child: Text(l10n.run),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;

    await ref.read(settingsProvider.notifier).updateSyncFetchMode(selected);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalysisPage(syncFetchMode: selected)),
    );
  }

  String _syncModeTitle(AppLocalizations l10n, SyncFetchMode mode) {
    return switch (mode) {
      SyncFetchMode.fast => l10n.sync_mode_fast,
      SyncFetchMode.expert => l10n.sync_mode_expert,
      SyncFetchMode.fastest => l10n.sync_mode_fastest,
    };
  }

  String _syncModeDescription(AppLocalizations l10n, SyncFetchMode mode) {
    return switch (mode) {
      SyncFetchMode.fast => l10n.sync_mode_fast_description,
      SyncFetchMode.expert => l10n.sync_mode_expert_description,
      SyncFetchMode.fastest => l10n.sync_mode_fastest_description,
    };
  }

  // Navigation logic
  Future<void> _navigateToUserList(
    BuildContext context,
    String categoryKey,
  ) async {
    final activeAccount = ref.read(activeAccountProvider);
    if (activeAccount == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserListPage(ownerId: activeAccount.id, categoryKey: categoryKey),
      ),
    );
  }
}
