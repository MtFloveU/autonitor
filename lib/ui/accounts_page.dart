import 'package:autonitor/ui/auth/webview_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

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

  Future<String?> _showLoginOptions(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("选择登录方式"),
        content: const Text("请选择获取Cookie的方式。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: const Text("手动输入"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'browser'),
            child: const Text("浏览器获取"),
          ),
        ],
      ),
    );
  }

  Future<String?> _showManualInputDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("手动输入Cookie"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "请在此粘贴Cookie字符串"),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(String cookie) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(accountsProvider.notifier).addAccount(cookie);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("账号添加成功！"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("添加失败: $e"), backgroundColor: Colors.red),
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
    final accounts = ref.watch(accountsProvider);
    final activeAccount = ref.watch(activeAccountProvider);

    return Stack(
      children: [
        ListView.builder(
          itemCount: accounts.length + 1, // +1 for the add button
          itemBuilder: (context, index) {
            if (index == 0) {
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text("添加新账号"),
                  onTap: () => _navigateAndAddAccount(context),
                ),
              );
            }
            final account = accounts[index - 1];
            final bool isActive = activeAccount?.id == account.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
              child: ListTile(
                title: Text("ID: ${account.id}"),
                trailing: TextButton(
                  child: const Text("查看Cookie"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("账号 ${account.id} 的Cookie"),
                        content: SingleChildScrollView(
                          child: SelectableText(account.cookie),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("关闭"),
                          )
                        ],
                      ),
                    );
                  },
                ),
                onTap: () {
                  ref.read(activeAccountProvider.notifier).state = account;
                },
              ),
            );
          },
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("正在保存账号...", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

