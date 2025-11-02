import 'package:autonitor/ui/auth/webview_login_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/account.dart';
import 'package:flutter/services.dart';

import '../services/log_service.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  bool _isRefreshing = false;

  Future<void> _navigateAndAddAccount(BuildContext context) async {
    final source = await _showLoginOptions(context);
    if (source == null) return;

    String? cookie;
    if (source == 'browser') {
      cookie = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const WebViewLoginPage()),
      );
    } else if (source == 'manual') {
      cookie = await _showManualInputDialog(context);
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
        title: Text(
          l10n.delete,
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
        content: Text(l10n.confirm_delete_account(account.id)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
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
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.choose_login_method),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: Text(l10n.manual_cookie),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'browser'),
            child: Text(l10n.browser_login),
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
        content: TextField(controller: controller, maxLines: 5),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
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
    final currentContext = context;
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(l10n.saving_account),
            ],
          ),
        ),
      ),
    );
    try {
      await ref.read(accountsProvider.notifier).addAccount(cookie);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.account_added_successfully,
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "$e",
              style: TextStyle(color: theme.colorScheme.onError),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(currentContext);
      }
    }
  }

  Future<void> _refreshAllAccounts() async {
    if (_isRefreshing) return;

    // --- 获取 Theme 和 l10n ---
    final theme = Theme.of(context);
    // final l10n = AppLocalizations.of(context)!; // Keep if you add l10n later

    setState(() => _isRefreshing = true);
    final currentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(currentContext);

    // --- 新增：显示模态加载对话框 ---
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Refreshing accounts...'), // Add l10n later
            ],
          ),
        ),
      ),
    );

    try {
      final accountsToRefresh = ref.read(accountsProvider);
      if (accountsToRefresh.isEmpty) {
        if (mounted) {
        // --- 修改 SnackBar 样式 ---
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'No accounts to refresh.', // Add l10n later
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
              ), // 信息文本颜色
            ),
            backgroundColor: theme.colorScheme.secondaryContainer, // 信息背景颜色
          ),
        );
        }
        // 注意：因为没有异步操作，需要在这里手动关闭对话框
        if (mounted) Navigator.pop(currentContext);
        setState(() => _isRefreshing = false); // 别忘了重置状态
        return;
      }

      final results = await ref
          .read(accountsProvider.notifier)
          .refreshAllAccountProfiles(accountsToRefresh);

      // 刷新完成后，先重新加载数据
      if (mounted) {
        await ref.read(accountsProvider.notifier).loadAccounts();
      }

      // 处理结果并显示总结 SnackBar
      int successCount = results.where((r) => r.success).length;
      int failureCount = results.length - successCount;
      String summary =
          'Refresh complete: $successCount succeeded'; // Add l10n later
      bool hasFailures = failureCount > 0;
      if (hasFailures) {
        summary += ', $failureCount failed.'; // Add l10n later
        results.where((r) => !r.success).forEach((failure) {
          logger.e("Refresh failed for ${failure.accountId}: ${failure.error}", error: Exception(failure.error), stackTrace: StackTrace.current);
        });
      }
      // --- 修改 SnackBar 样式 ---
      if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            summary,
            // 根据是否有失败使用不同颜色
            style: TextStyle(
              color: hasFailures
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
          backgroundColor: hasFailures
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.secondaryContainer,
        ),
      );
      }
    } catch (e, s) {
      logger.e("Error during _refreshAllAccounts UI call: $e", error: e, stackTrace: s);
      // --- 修改 SnackBar 样式 ---
      if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'An unexpected error occurred during refresh.', // Add l10n later
            style: TextStyle(color: theme.colorScheme.onError), // 错误文本颜色
          ),
          backgroundColor: theme.colorScheme.error, // 错误背景颜色
        ),
      );
      }
    } finally {
      // 确保无论如何都重置状态并关闭对话框
      if (mounted) {
        // 关闭模态对话框
        Navigator.pop(currentContext);
        // 重置刷新状态
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accounts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh All Profiles', // Add l10n later
            onPressed: _isRefreshing ? null : _refreshAllAccounts,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: accounts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(l10n.new_account),
                onTap: () => _navigateAndAddAccount(context),
              ),
            );
          }
          final account = accounts[index - 1];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.person, size: 24),
                    if (account.avatarUrl != null &&
                        account.avatarUrl!.isNotEmpty)
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: account.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeOutDuration: const Duration(milliseconds: 100),
                          errorWidget: (context, url, error) =>
                              const SizedBox(),
                        ),
                      ),
                  ],
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.name ?? 'Unknown Name',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "@${account.screenName ?? account.id}",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    "ID: ${account.id}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.cookie_outlined),
                    tooltip: l10n.view_cookie,
                    onPressed: () {
                      final theme = Theme.of(context);
                      final l10n = AppLocalizations.of(context)!;
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.cookie),
                          content: Container(
                            width: double.maxFinite,
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: TextEditingController(
                                  text: account.cookie,
                                ),
                                readOnly: true,
                                maxLines: null,
                                decoration: InputDecoration.collapsed(
                                  hintText: null,
                                ),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text(l10n.copy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: account.cookie),
                                );
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.copied_to_clipboard,
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                  ),
                                );
                              },
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(l10n.ok),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: l10n.delete,
                    onPressed: () {
                      _confirmAndDelete(account);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
