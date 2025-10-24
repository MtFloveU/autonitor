import 'dart:math';

import 'package:autonitor/models/twitter_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/core/data_processor.dart';
import 'package:autonitor/models/cache_data.dart';
import 'package:autonitor/providers/auth_provider.dart';
import 'package:autonitor/ui/user_list_page.dart';
import '../l10n/app_localizations.dart';

// --- (Providers... 保持不变) ---
final userListProvider =
    FutureProvider.family.autoDispose<List<TwitterUser>, String>((ref, category) async {
  final dataProcessor = ref.watch(dataProcessorProvider);
  if (dataProcessor == null) {
    print("userListProvider: DataProcessor is null for category '$category'");
    return []; 
  }
  print("userListProvider: Calling getUsers for category '$category'");
  try {
    final users = await dataProcessor.getUsers(category);
    print(
        "userListProvider: getUsers completed for category '$category'. Found ${users.length} users.");
    return users;
  } catch (e, stacktrace) {
    print(
        "userListProvider: !!! ERROR fetching users for category '$category': $e !!!");
    print("userListProvider: Stacktrace: $stacktrace");
    throw Exception('$e'); 
  }
});

final dataProcessorProvider = Provider.autoDispose<DataProcessor?>((ref) {
  final activeAccount = ref.watch(activeAccountProvider);
  if (activeAccount == null) return null;
  return DataProcessor(account: activeAccount);
});

final cacheProvider = FutureProvider.autoDispose<CacheData?>((ref) async {
  final dataProcessor = ref.watch(dataProcessorProvider);
  if (dataProcessor == null) return null;

  final initialCache = await dataProcessor.getCacheData();
  if (initialCache != null) return initialCache;

  await dataProcessor.runProcess();
  return await dataProcessor.getCacheData();
});
// --- (Providers 结束) ---


class HomePage extends ConsumerWidget {
  final VoidCallback onNavigateToAccounts;

  const HomePage({super.key, required this.onNavigateToAccounts});

  void _showAccountSwitcher(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
              child:
                  Text(l10n.switch_account, style: Theme.of(context).textTheme.titleLarge),
            ),
            ...allAccounts.map((account) {
              return ListTile(
                leading: Icon(
                  account.id == activeAccount?.id
                      ? Icons.check_circle
                      : Icons.person_outline,
                  color:
                      account.id == activeAccount?.id ? Colors.green : null,
                ),
                title: Text("ID: ${account.id}"),
                onTap: () {
                  // --- 修改：使用 .setActive() 方法 ---
                  ref.read(activeAccountProvider.notifier).setActive(account);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _navigateToUserList(
      BuildContext context, WidgetRef ref, String categoryKey) async {
    print('--- HomePage: Navigating to UserListPage for category key: $categoryKey ---');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserListPage(title: categoryKey),
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeAccount = ref.watch(activeAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonitor'),
      ),
      body: activeAccount == null
          ? _buildNoAccountState(context, onNavigateToAccounts)
          : _buildAccountView(context, ref),
      
      floatingActionButton: activeAccount == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final currentContext = context;
                showDialog(
                  context: currentContext, 
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                await ref.read(dataProcessorProvider)?.runProcess();
                ref.invalidate(cacheProvider);
                if (currentContext.mounted) {
                  Navigator.pop(currentContext);
                }
              },
              label: Text(l10n.run),
              icon: const Icon(Icons.play_arrow),
            ),
    );
  }

  Widget _buildNoAccountState(BuildContext context, VoidCallback onNavigate) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(l10n.login_first, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.login_first_description, textAlign: TextAlign.center),
            const SizedBox(height: 24), 
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: Text(l10n.accounts),
              onPressed: onNavigate,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
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

  Widget _buildDataDisplay(
      BuildContext context, CacheData cache, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(cacheProvider),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Card(
            clipBehavior: Clip.antiAlias, 
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                          radius: 24, child: Icon(Icons.person, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cache.accountName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),maxLines: 1,
                                overflow: TextOverflow.ellipsis,),
                            Text("@${cache.accountName}",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),maxLines: 1,
                                overflow: TextOverflow.ellipsis,),
                            Text("ID: ${cache.accountId}", 
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),maxLines: 1,
                                overflow: TextOverflow.ellipsis,),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        tooltip: l10n.switch_account,
                        onPressed: () => _showAccountSwitcher(context, ref),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 0, endIndent: 0),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _navigateToUserList(context, ref, 'following'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Column(
                              children: [
                                Text(
                                  cache.followingCount.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.following,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _navigateToUserList(context, ref, 'followers'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Column(
                              children: [
                                Text(
                                  cache.followersCount.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.followers,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24), 
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _buildDetailListItem(context, ref, 'normal_unfollowed', Icons.person_remove_outlined,
                    l10n.normal_unfollowed, cache.unfollowedCount),
                _buildDetailListItem(context, ref, 'mutual_unfollowed', Icons.group_off_rounded,
                    l10n.mutual_unfollowed, cache.mutualUnfollowedCount),
                _buildDetailListItem(context, ref, 'oneway_unfollowed', Icons.group_off_outlined,
                    l10n.oneway_unfollowed, cache.singleUnfollowedCount),
                _buildDetailListItem(
                    context, ref, 'suspended', Icons.lock_outline, l10n.suspended, cache.frozenCount),
                _buildDetailListItem(context, ref, 'deactivated', Icons.no_accounts_outlined,
                    l10n.deactivated, cache.deactivatedCount),
                _buildDetailListItem(context, ref, 'be_followed_back', Icons.group_add_outlined,
                    l10n.be_followed_back, cache.refollowedCount),
                _buildDetailListItem(
                    context,
                    ref,
                    'new_followers_following',
                    Icons.person_add_alt_1_outlined,
                    l10n.new_followers_following,
                    cache.newFollowersCount,
                    showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 80), 
        ],
      ),
    );
  }

  Widget _buildDetailListItem(BuildContext context, WidgetRef ref,
      String categoryKey, IconData icon, String label, int count,
      {bool showDivider = true}) {
    return InkWell(
      onTap: () => _navigateToUserList(context, ref, categoryKey),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                    child: Text(label,
                        style: Theme.of(context).textTheme.titleMedium)),
                Text(count.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

