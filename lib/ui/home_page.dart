import 'package:autonitor/ui/user_detail_page.dart';
import 'package:autonitor/models/twitter_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/models/cache_data.dart';
import 'package:autonitor/providers/auth_provider.dart';
import 'package:autonitor/ui/user_list_page.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
// 移除了未使用的 drift, database, main 导入

// Providers 现已在 auth_provider.dart 中定义

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToAccounts;
  const HomePage({super.key, required this.onNavigateToAccounts});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  void _showAccountSwitcher(BuildContext context) {
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
              child: Text(l10n.switch_account, style: Theme.of(context).textTheme.titleLarge),
            ),
            ...allAccounts.map((account) {
              return ListTile(
                leading: SizedBox(
                  width: 48, height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(alignment: Alignment.center, child: const Icon(Icons.person, size: 24)),
                      if (account.avatarUrl != null && account.avatarUrl!.isNotEmpty)
                        ClipOval(child: CachedNetworkImage(
                            imageUrl: account.avatarUrl!, fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (context, url) => const SizedBox.shrink(),
                            errorWidget: (context, url, error) => const SizedBox.shrink(),
                            imageBuilder: (context, imageProvider) => Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                            ),
                        )),
                      if (account.id == activeAccount?.id)
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(account.name ?? 'Unknown Name', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text("@${account.screenName ?? account.id ?? '...'}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                    Text("ID: ${account.id ?? '...'}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
                trailing: null,
                onTap: () { ref.read(activeAccountProvider.notifier).setActive(account); Navigator.pop(context); },
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _navigateToUserList(BuildContext context, String categoryKey) async {
    final activeAccount = ref.read(activeAccountProvider);
    if (activeAccount == null) return;
    print('--- HomePage: Navigating to UserListPage for category $categoryKey ---');
    Navigator.push(context, MaterialPageRoute(
        // --- 修正：使用 UserListPage 的正确构造函数 ---
        builder: (_) => UserListPage(
          ownerId: activeAccount.id,   // 传递 ownerId
          categoryKey: categoryKey, // 传递 categoryKey
        ),
        // --- 修正结束 ---
    ));
  }

  Widget _buildNoAccountState(BuildContext context, VoidCallback onNavigate) {
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(l10n.login_first, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.login_first_description, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.login), label: Text(l10n.log_in),
              onPressed: onNavigate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
    ));
  }

  Widget _buildAccountView(BuildContext context) {
    final cacheAsyncValue = ref.watch(cacheProvider);
    return cacheAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载缓存失败: $err')), // TODO: Add l10n
      data: (cacheData) {
        if (cacheData == null) { return _buildEmptyCacheState(context); }
        return _buildDataDisplay(context, cacheData);
      },
    );
  }

  Widget _buildEmptyCacheState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.no_analysis_data), // 使用 l10n
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.invalidate(cacheProvider),
            label: Text(l10n.run_analysis_now), // 使用 l10n
          ),
        ],
    ));
  }

  Widget _buildDataDisplay(BuildContext context, CacheData cache) {
    final l10n = AppLocalizations.of(context)!;
    final activeAccount = ref.watch(activeAccountProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(cacheProvider),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Card(
            clipBehavior: Clip.antiAlias, margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () {
                if (activeAccount == null) return;
                final user = TwitterUser(
                  avatarUrl: activeAccount.avatarUrl ?? '', name: activeAccount.name ?? 'Unknown',
                  id: activeAccount.screenName ?? activeAccount.id, restId: activeAccount.id,
                  joinTime: activeAccount.joinTime ?? '', bio: activeAccount.bio,
                  location: activeAccount.location, bannerUrl: activeAccount.bannerUrl,
                  link: activeAccount.link, followersCount: activeAccount.followersCount,
                  followingCount: activeAccount.followingCount, statusesCount: activeAccount.statusesCount,
                  mediaCount: activeAccount.mediaCount, favouritesCount: activeAccount.favouritesCount,
                  listedCount: activeAccount.listedCount, latestRawJson: activeAccount.latestRawJson,
                );
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetailPage(user: user)));
              },
              child: Column(children: [
                  Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: Row(children: [
                      Hero(
                        tag: 'avatar_${activeAccount?.id}',
                        child: CircleAvatar(radius: 24, backgroundColor: Colors.transparent, child: Stack(
                            alignment: Alignment.center, children: [
                              const Icon(Icons.person, size: 24),
                              if (activeAccount?.avatarUrl != null && activeAccount!.avatarUrl!.isNotEmpty)
                                ClipOval(child: CachedNetworkImage(
                                    imageUrl: activeAccount.avatarUrl!, fit: BoxFit.cover, width: 48, height: 48,
                                    fadeInDuration: const Duration(milliseconds: 300), fadeOutDuration: const Duration(milliseconds: 100),
                                    errorWidget: (context, url, error) => const SizedBox(),
                                )),
                            ],
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(activeAccount?.name ?? 'Unknown Name', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("@${activeAccount?.screenName ?? activeAccount?.id ?? '...'}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("ID: ${activeAccount?.id ?? '...'}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      IconButton(icon: const Icon(Icons.swap_horiz), tooltip: l10n.switch_account, onPressed: () => _showAccountSwitcher(context)),
                  ])),
                  const Divider(height: 1, indent: 0, endIndent: 0),
                  IntrinsicHeight(child: Row(children: [
                      Expanded(child: InkWell(
                          onTap: () => _navigateToUserList(context, 'following'),
                          child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Column(children: [
                              Text(cache.followingCount.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2), Text(l10n.following, style: Theme.of(context).textTheme.bodySmall),
                          ])),
                      )),
                      const VerticalDivider(width: 1),
                      Expanded(child: InkWell(
                          onTap: () => _navigateToUserList(context, 'followers'),
                          child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Column(children: [
                              Text(cache.followersCount.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2), Text(l10n.followers, style: Theme.of(context).textTheme.bodySmall),
                          ])),
                      )),
                  ])),
              ])),
          ),
          const SizedBox(height: 24),
          Card(margin: EdgeInsets.zero, child: Column(children: [
                _buildDetailListItem(context, 'normal_unfollowed', Icons.person_remove_outlined, l10n.normal_unfollowed, cache.unfollowedCount),
                _buildDetailListItem(context, 'mutual_unfollowed', Icons.group_off_rounded, l10n.mutual_unfollowed, cache.mutualUnfollowedCount),
                _buildDetailListItem(context, 'oneway_unfollowed', Icons.group_off_outlined, l10n.oneway_unfollowed, cache.singleUnfollowedCount),
                // --- 修正：使用 l10n key 并从 cache 获取真实 count ---
                _buildDetailListItem(context, 'temporarily_restricted', Icons.warning_amber_rounded, l10n.temporarily_restricted, cache.temporarilyRestrictedCount),
                // --- 修正结束 ---
                _buildDetailListItem(context, 'suspended', Icons.lock_outline, l10n.suspended, cache.frozenCount),
                _buildDetailListItem(context, 'deactivated', Icons.no_accounts_outlined, l10n.deactivated, cache.deactivatedCount),
                _buildDetailListItem(context, 'be_followed_back', Icons.group_add_outlined, l10n.be_followed_back, cache.refollowedCount),
                _buildDetailListItem(context, 'new_followers_following', Icons.person_add_alt_1_outlined, l10n.new_followers_following, cache.newFollowersCount, showDivider: false),
          ])),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDetailListItem(BuildContext context, String categoryKey, IconData icon, String label, int count, { bool showDivider = true }) {
    return InkWell(
      onTap: () => _navigateToUserList(context, categoryKey),
      child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), child: Row(children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              Text(count.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
              const SizedBox(width: 8), const Icon(Icons.chevron_right, color: Colors.grey),
          ])),
          if (showDivider) const Divider(height: 1, indent: 56),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeAccount = ref.watch(activeAccountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.app_title)), // 使用 l10n key
      body: activeAccount == null
          ? _buildNoAccountState(context, widget.onNavigateToAccounts)
          : _buildAccountView(context),
      floatingActionButton: activeAccount == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final currentContext = context; final currentRef = ref;
                final currentL10n = AppLocalizations.of(currentContext)!; final currentTheme = Theme.of(currentContext);
                showDialog(
                  context: currentContext, barrierDismissible: false,
                  builder: (dialogContext) => PopScope(
                    canPop: false,
                    child: AlertDialog(
                      title: Row(children: [
                          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                          SizedBox(width: 16), Text(currentL10n.analysis_log), // 使用 l10n
                      ]),
                      content: SizedBox(
                         width: double.maxFinite, height: MediaQuery.of(currentContext).size.height * 0.7,
                         child: Consumer(
                           builder: (context, ref, child) {
                             final logs = ref.watch(analysisLogProvider);
                             final ScrollController scrollController = ScrollController();
                             WidgetsBinding.instance.addPostFrameCallback((_) {
                               if (scrollController.hasClients) {
                                  scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                               }
                             });
                             return ListView.builder(
                               controller: scrollController, itemCount: logs.length,
                               itemBuilder: (context, index) => Padding(
                                   padding: const EdgeInsets.symmetric(vertical: 2.0),
                                   child: Text(logs[index], style: TextStyle(fontSize: 10, fontFamily: 'monospace')), // Use monospace for logs
                               ),
                             );
                           }
                         ),
                      ),
                      actions: [ TextButton(child: Text(currentL10n.close), onPressed: () => Navigator.pop(dialogContext)) ], // TODO: Disable button while running
                    ),
                  ),
                );
                try {
                  final accountToProcess = currentRef.read(activeAccountProvider);
                  if (accountToProcess == null) { throw Exception(currentL10n.no_active_account_error); } // 使用 l10n
                  await currentRef.read(accountsProvider.notifier).runAnalysisProcess(accountToProcess);
                } catch (e) {
                  if (!currentContext.mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(SnackBar(
                      content: Text('${currentL10n.analysis_failed_error}: $e', style: TextStyle(color: currentTheme.colorScheme.onError)), // 使用 l10n
                      backgroundColor: currentTheme.colorScheme.error,
                  ));
                } finally {
                  if (currentContext.mounted) {
                     try { if (Navigator.canPop(currentContext)) { Navigator.pop(currentContext); } }
                     catch (e) { print("Error closing dialog in finally: $e"); }
                  }
                   currentRef.invalidate(cacheProvider);
                }
              },
              label: Text(l10n.run), icon: const Icon(Icons.play_arrow),
            ),
    );
  }
}

