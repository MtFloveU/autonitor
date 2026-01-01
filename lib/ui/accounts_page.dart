import 'dart:io';
import 'package:autonitor/providers/media_provider.dart';
import 'package:autonitor/ui/auth/webview_login_page.dart';
import 'package:autonitor/ui/components/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../services/log_service.dart';

class AccountsPage extends ConsumerStatefulWidget {
  final bool useSideNav;
  const AccountsPage({super.key, this.useSideNav = false});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  bool _isRefreshing = false;

  Future<void> _navigateAndAddAccount(BuildContext context) async {
    final source = await _showLoginOptions(context);

    // Fix: Guard against using context across async gap
    if (source == null || !context.mounted) return;

    String? cookie;

    if (source == 'browser') {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const WebViewLoginPage()),
      );

      if (!context.mounted) return;

      cookie = result;
    } else if (source == 'manual') {
      String? result;
      if (mounted) {
        result = await _showManualInputDialog(context);
      }

      if (!mounted || result == null) return;

      cookie = result;
    }

    if (cookie != null && cookie.isNotEmpty) {
      await _handleLogin(cookie);
    }
  }

  Future<void> _confirmAndDelete(Account account) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirm_delete_account(account.id)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(accountsProvider.notifier).removeAccount(account.id);
    }
  }

  Future<String?> _showLoginOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;

    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.choose_login_method),
        children: [
          if (Platform.isAndroid || Platform.isIOS)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'browser'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.web, color: iconColor),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        l10n.browser_login,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: iconColor),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      l10n.manual_cookie,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showManualInputDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.manual_cookie),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'auth_token=...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(String cookie) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.saving_account),
            ],
          ),
        ),
      ),
    );

    try {
      await ref.read(accountsProvider.notifier).addAccount(cookie);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.account_added_successfully,
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
            backgroundColor: theme.colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              "$e",
              style: TextStyle(color: theme.colorScheme.onError),
            ),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        navigator.pop();
      }
    }
  }

  Future<void> _refreshAllAccounts() async {
    if (_isRefreshing) return;

    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isRefreshing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Refreshing accounts...'),
            ],
          ),
        ),
      ),
    );

    try {
      final accountsToRefresh = ref.read(accountsProvider);
      if (accountsToRefresh.isEmpty) {
        if (mounted) navigator.pop();
        setState(() => _isRefreshing = false);
        return;
      }

      final results = await ref
          .read(accountsProvider.notifier)
          .refreshAllAccountProfiles(accountsToRefresh);

      if (mounted) {
        await ref.read(accountsProvider.notifier).loadAccounts();
      }

      int successCount = results.where((r) => r.success).length;
      int failureCount = results.length - successCount;
      String summary = 'Refresh complete: $successCount succeeded';
      bool hasFailures = failureCount > 0;

      if (hasFailures) {
        summary += ', $failureCount failed.';
        for (var r in results.where((r) => !r.success)) {
          logger.e("Refresh failed for ${r.accountId}: ${r.error}");
        }
      }

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              summary,
              style: TextStyle(
                color: hasFailures
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSecondaryContainer,
              ),
            ),
            backgroundColor: hasFailures
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, s) {
      logger.e("Error during refresh: $e", error: e, stackTrace: s);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        navigator.pop();
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(accountsProvider);
    final mediaDir = ref.watch(appSupportDirProvider).value;
    final theme = Theme.of(context);

    final bool useSideNav =
        widget.useSideNav || MediaQuery.of(context).size.width >= 640;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accounts),
        actions: [
          if (accounts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh All Profiles',
              onPressed: _isRefreshing ? null : _refreshAllAccounts,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.no_accounts_outlined,
                    size: 64,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.no_accounts_added,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount;
                if (!useSideNav) {
                  crossAxisCount = 1;
                } else {
                  crossAxisCount = (width ~/ 320).clamp(2, 4);
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 160,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return _AccountCard(
                      account: account,
                      mediaDir: mediaDir,
                      onViewCookie: () => _showCookieDialog(account),
                      onDelete: () => _confirmAndDelete(account),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndAddAccount(context),
        tooltip: l10n.new_account,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCookieDialog(Account account) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cookie),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: SelectableText(
              account.cookie,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l10n.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: account.cookie));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.copied_to_clipboard,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final String? mediaDir;
  final VoidCallback onViewCookie;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.mediaDir,
    required this.onViewCookie,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      avatarUrl: account.avatarUrl,
                      avatarLocalPath: account.avatarLocalPath,
                      mediaDir: mediaDir,
                      radius: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            "@${account.screenName ?? account.id}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "ID: ${account.id}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontFamily: 'monospace',
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    onPressed: onViewCookie,
                    tooltip: l10n.view_cookie,
                    iconSize: 20,
                    icon: const Icon(Icons.cookie_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onDelete,
                    tooltip: l10n.delete,
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      backgroundColor: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.3),
                    ),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
