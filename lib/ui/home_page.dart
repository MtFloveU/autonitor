import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/core/data_processor.dart';
import 'package:autonitor/models/cache_data.dart';
import 'package:autonitor/providers/auth_provider.dart';
import 'package:autonitor/ui/user_list_page.dart';

// [已更新]
// 核心改动：
// 1. 在顶部信息栏右侧，恢复了“切换账号”的IconButton。
// 2. 新增了 `_showAccountSwitcher` 方法，用于弹出账号选择对话框。
// 3. 在页面右下角，新增了一个FloatingActionButton，用于触发“运行分析”操作。
// 4. “运行分析”会调用 `ref.refresh(cacheProvider)`，这是Riverpod中重新执行Provider逻辑的标准方式。

final dataProcessorProvider = Provider.autoDispose<DataProcessor?>((ref) {
  final activeAccount = ref.watch(activeAccountProvider);
  if (activeAccount == null) return null;
  return DataProcessor(account: activeAccount);
});

final cacheProvider = FutureProvider.autoDispose<CacheData?>((ref) async {
  final dataProcessor = ref.watch(dataProcessorProvider);
  if (dataProcessor == null) return null;
  
  // 启动时，先尝试加载现有缓存
  final initialCache = await dataProcessor.getCacheData();
  if (initialCache != null) return initialCache;
  
  // 如果没有缓存，则自动运行一次分析
  await dataProcessor.runProcess();
  return await dataProcessor.getCacheData();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// [新增] 弹出账号切换对话框
  void _showAccountSwitcher(BuildContext context, WidgetRef ref) {
    final allAccounts = ref.read(accountsProvider);
    final activeAccount = ref.read(activeAccountProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("切换账号", style: Theme.of(context).textTheme.titleLarge),
            ),
            ...allAccounts.map((account) {
              return ListTile(
                leading: Icon(
                  account.id == activeAccount?.id ? Icons.check_circle : Icons.person_outline,
                  color: account.id == activeAccount?.id ? Colors.green : null,
                ),
                title: Text("ID: ${account.id}"),
                onTap: () {
                  // 更新活动账号
                  ref.read(activeAccountProvider.notifier).state = account;
                  Navigator.pop(context); // 关闭对话框
                },
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _navigateToUserList(BuildContext context, WidgetRef ref, String category) async {
    final dataProcessor = ref.read(dataProcessorProvider);
    if (dataProcessor == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final users = await dataProcessor.getUsers(category);
      if (context.mounted) {
        Navigator.pop(context); 
        if (users.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$category 列表当前为空')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserListPage(title: category, users: users),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取列表失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccount = ref.watch(activeAccountProvider);

    if (activeAccount == null) {
      return _buildNoAccountState(context);
    }
    
    return Scaffold( // [新增] 添加Scaffold以容纳FloatingActionButton
      body: _buildAccountView(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 显示加载指示器
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          // 重新运行分析
          await ref.read(dataProcessorProvider)?.runProcess();
          // 刷新UI
          ref.invalidate(cacheProvider);
          if (context.mounted) {
            Navigator.pop(context); // 关闭加载指示器
          }
        },
        label: const Text("运行分析"),
        icon: const Icon(Icons.sync),
      ),
    );
  }

  Widget _buildNoAccountState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text("没有活动的账号", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text("请前往 'Accounts' 页面添加或选择一个账号。", textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountView(BuildContext context, WidgetRef ref) {
    final cacheAsyncValue = ref.watch(cacheProvider);

    return cacheAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载缓存失败: $err')),
      data: (cacheData) {
        if (cacheData == null) {
          return _buildEmptyCacheState(context, ref);
        }
        return _buildDataDisplay(context, cacheData, ref);
      },
    );
  }

  Widget _buildEmptyCacheState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("尚未生成分析数据"),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.invalidate(cacheProvider),
            label: const Text("立即运行分析"),
          )
        ],
      ),
    );
  }

  Widget _buildDataDisplay(BuildContext context, CacheData cache, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(cacheProvider),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
           Row(
            children: [
              const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cache.accountName, style: Theme.of(context).textTheme.titleLarge),
                    Text("ID: ${cache.accountId}", style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              // [已恢复] 切换账号按钮
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: "切换账号",
                onPressed: () => _showAccountSwitcher(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('概览', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildOverviewCard(context, cache.followersCount.toString(), '关注者', () => _navigateToUserList(context, ref, '关注者'))),
              const SizedBox(width: 16),
              Expanded(child: _buildOverviewCard(context, cache.followingCount.toString(), '正在关注', () => _navigateToUserList(context, ref, '正在关注'))),
            ],
          ),
          const Divider(height: 48),
          Text('详情', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _buildDetailListItem(context, ref, Icons.person_remove_outlined, '普通取关', cache.unfollowedCount),
                _buildDetailListItem(context, ref, Icons.group_off_outlined, '互关双取', cache.mutualUnfollowedCount),
                _buildDetailListItem(context, ref, Icons.person_off_outlined, '互关单取', cache.singleUnfollowedCount),
                _buildDetailListItem(context, ref, Icons.lock_outline, '冻结', cache.frozenCount),
                _buildDetailListItem(context, ref, Icons.no_accounts_outlined, '注销', cache.deactivatedCount),
                _buildDetailListItem(context, ref, Icons.person_add_alt_1_outlined, '重新关注', cache.refollowedCount),
                _buildDetailListItem(context, ref, Icons.person_add, '新增关注', cache.newFollowersCount, showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 80), // 为悬浮按钮留出空间
        ],
      ),
    );
  }
  
  Widget _buildOverviewCard(BuildContext context, String value, String label, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailListItem(BuildContext context, WidgetRef ref, IconData icon, String label, int count, {bool showDivider = true}) {
    return InkWell(
      onTap: () => _navigateToUserList(context, ref, label),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
                Text(count.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                )),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, indent: 56),
        ],
      ),
    );
  }
}

