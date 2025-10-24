import 'package:autonitor/ui/auth/webview_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/account.dart';

// [已更新]
// 核心改动：
// 1. 移除了 AppBar。
// 2. 在列表顶部新增了一个带"+"图标的“添加新账号”按钮。
// 3. 将登录流程（浏览器/手动）的触发逻辑直接整合到了这个页面中。
// 4. 增加了 `_isLoading` 状态，用于在保存账号时显示全屏加载动画。

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  bool _isLoading = false;

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

    // 弹出确认对话框
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // --- 恢复：使用您提供的 l10n key ---
        title: Text(l10n.delete),
        // --- 恢复：使用您提供的 l10n key ---
        content: Text(l10n.confirm_delete_account(account.id)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel), // 使用 "取消"
          ),
          // 为破坏性操作使用红色按钮
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            // --- 恢复：使用您提供的 l10n key ---
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    // 如果用户确认了，则调用 provider
    if (confirmed == true && context.mounted) {
      ref.read(accountsProvider.notifier).removeAccount(account.id);
    }
  }
  // --- ↑↑↑ 新方法添加完毕 ↑↑↑ ---

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
    // --- 1. 在 try 之前获取 theme ---
    final theme = Theme.of(context);

    setState(() => _isLoading = true);

    try {
      await ref.read(accountsProvider.notifier).addAccount(cookie);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // --- 2. 修改成功 SnackBar ---
            content: Text(
              l10n.account_added_successfully,
              // 使用 'onPrimaryContainer' 颜色，它保证在 'primaryContainer' 上清晰可见
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
            // 使用 'primaryContainer' 作为背景色
            // 它在亮色模式下是浅色，在暗色模式下是深色
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e, s) {
      // 捕获错误 (e) 和堆栈 (s)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // --- 3. 修改错误 SnackBar ---
            content: Text(
              "$e",
              // 使用 'onError' 颜色，它保证在 'error' 色上清晰可见
              style: TextStyle(color: theme.colorScheme.onError),
            ),
            // 使用 'error' 颜色，它会自动适应深浅色模式
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(accountsProvider);
    final activeAccount = ref.watch(activeAccountProvider);

    // 1. 返回一个 Scaffold
    return Scaffold(
      // 2. 添加 AppBar，并使用 l10n 获取标题
      appBar: AppBar(title: Text(l10n.accounts)),
      // 3. body 是之前返回的 Stack
      body: Stack(
        children: [
          ListView.builder(
            itemCount: accounts.length + 1, // +1 for the add button
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
              final bool isActive = activeAccount?.id == account.id;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  title: Text("ID: ${account.id}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // 保证 Row 不会溢出
                    children: [
                      // 1. "查看 Cookie" 按钮
                      IconButton(
                        icon: const Icon(Icons.cookie_outlined), // 饼干图标
                        tooltip: l10n.view_cookie, // "view_cookie" 作为描述
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: SingleChildScrollView(
                                child: SelectableText(account.cookie),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  // --- 恢复：使用 l10n.ok ---
                                  child: Text(l10n.ok),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // 2. "删除" 按钮
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          // 添加红色以示警告
                          color: Theme.of(context).colorScheme.error,
                        ),
                        // --- 恢复：使用硬编码的 tooltip ---
                        tooltip: "删除账号",
                        onPressed: () {
                          // 调用我们刚创建的确认方法
                          _confirmAndDelete(account);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // --- 保持逻辑修复：使用 .setActive() ---
                    ref.read(activeAccountProvider.notifier).setActive(account);
                  },
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      l10n.saving_account,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

