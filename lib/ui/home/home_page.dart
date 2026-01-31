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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalysisPage()),
              ),
              label: Text(l10n.run),
              icon: const Icon(Icons.sync_outlined),
            ),
    );
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
