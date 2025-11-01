import 'package:autonitor/ui/user_detail_page.dart';
import 'package:autonitor/models/twitter_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/models/cache_data.dart';
import 'package:autonitor/providers/auth_provider.dart';
import 'package:autonitor/ui/user_list_page.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/report_providers.dart';
import '../providers/analysis_provider.dart';

// Providers (cacheProvider, userListProvider) 现在在 auth_provider.dart 中定义

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToAccounts;
  const HomePage({super.key, required this.onNavigateToAccounts});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // 辅助方法：格式化 ISO 8601 时间字符串
  String _getFormattedLastUpdate(
    BuildContext context,
    AppLocalizations l10n,
    String isoString,
  ) {
    if (isoString.isEmpty) {
      return l10n.last_updated_at("N/A");
    }
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      // 格式: YYYY-MM-DD HH:MM
      final formattedDate =
          "${dateTime.year.toString().padLeft(4, '0')}-"
          "${dateTime.month.toString().padLeft(2, '0')}-"
          "${dateTime.day.toString().padLeft(2, '0')} "
          "${dateTime.hour.toString().padLeft(2, '0')}:"
          "${dateTime.minute.toString().padLeft(2, '0')}";
      return l10n.last_updated_at(formattedDate);
    } catch (e) {
      print("Error parsing lastUpdateTime: $e");
      return l10n.last_updated_at("Invalid Date");
    }
  }

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
              child: Text(
                l10n.switch_account,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...allAccounts.map((account) {
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, size: 24),
                      ),
                      if (account.avatarUrl != null &&
                          account.avatarUrl!.isNotEmpty)
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: account.avatarUrl!,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (context, url) =>
                                const SizedBox.shrink(),
                            errorWidget: (context, url, error) =>
                                const SizedBox.shrink(),
                            imageBuilder: (context, imageProvider) => Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (account.id == activeAccount?.id)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
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
                trailing: null,
                onTap: () {
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
    BuildContext context,
    String categoryKey,
  ) async {
    final activeAccount = ref.read(activeAccountProvider);
    if (activeAccount == null) return;
    print(
      '--- HomePage: Navigating to UserListPage for category $categoryKey ---',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserListPage(ownerId: activeAccount.id, categoryKey: categoryKey),
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
            Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              l10n.login_first,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.login_first_description, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: Text(l10n.log_in),
              onPressed: onNavigate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountView(BuildContext context) {
    final cacheAsyncValue = ref.watch(cacheProvider);
    return cacheAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载缓存失败: $err')),
      data: (cacheData) {
        if (cacheData == null) {
          return _buildEmptyCacheState(context);
        }
        return _buildDataDisplay(context, cacheData);
      },
    );
  }

  Widget _buildEmptyCacheState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.no_analysis_data),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.invalidate(cacheProvider),
            label: Text(l10n.run_analysis_now),
          ),
        ],
      ),
    );
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
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () {
                if (activeAccount == null) return;
                final user = TwitterUser(
                  avatarUrl: activeAccount.avatarUrl ?? '',
                  name: activeAccount.name ?? 'Unknown',
                  id: activeAccount.screenName ?? activeAccount.id,
                  restId: activeAccount.id,
                  joinTime: activeAccount.joinTime ?? '',
                  bio: activeAccount.bio,
                  location: activeAccount.location,
                  bannerUrl: activeAccount.bannerUrl,
                  link: activeAccount.link,
                  followersCount: activeAccount.followersCount,
                  followingCount: activeAccount.followingCount,
                  statusesCount: activeAccount.statusesCount,
                  mediaCount: activeAccount.mediaCount,
                  favouritesCount: activeAccount.favouritesCount,
                  listedCount: activeAccount.listedCount,
                  latestRawJson: activeAccount.latestRawJson,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetailPage(user: user),
                  ),
                );
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'avatar_${activeAccount?.id}',
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.person, size: 24),
                                if (activeAccount?.avatarUrl != null &&
                                    activeAccount!.avatarUrl!.isNotEmpty)
                                  ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: activeAccount.avatarUrl!,
                                      fit: BoxFit.cover,
                                      width: 48,
                                      height: 48,
                                      fadeInDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      fadeOutDuration: const Duration(
                                        milliseconds: 100,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const SizedBox(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeAccount?.name ?? 'Unknown Name',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "@${activeAccount?.screenName ?? activeAccount?.id ?? '...'}",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "ID: ${activeAccount?.id ?? '...'}",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: l10n.switch_account,
                          onPressed: () => _showAccountSwitcher(context),
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
                                _navigateToUserList(context, 'following'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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
                                _navigateToUserList(context, 'followers'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _buildDetailListItem(
                  context,
                  'normal_unfollowed',
                  Icons.person_remove_outlined,
                  l10n.normal_unfollowed,
                  cache.unfollowedCount,
                ),
                _buildDetailListItem(
                  context,
                  'mutual_unfollowed',
                  Icons.group_off_rounded,
                  l10n.mutual_unfollowed,
                  cache.mutualUnfollowedCount,
                ),
                _buildDetailListItem(
                  context,
                  'oneway_unfollowed',
                  Icons.group_off_outlined,
                  l10n.oneway_unfollowed,
                  cache.singleUnfollowedCount,
                ),
                _buildDetailListItem(
                  context,
                  'temporarily_restricted',
                  Icons.warning_amber_rounded,
                  l10n.temporarily_restricted,
                  cache.temporarilyRestrictedCount,
                ),
                _buildDetailListItem(
                  context,
                  'suspended',
                  Icons.lock_outline,
                  l10n.suspended,
                  cache.frozenCount,
                ),
                _buildDetailListItem(
                  context,
                  'deactivated',
                  Icons.no_accounts_outlined,
                  l10n.deactivated,
                  cache.deactivatedCount,
                ),
                _buildDetailListItem(
                  context,
                  'be_followed_back',
                  Icons.group_add_outlined,
                  l10n.be_followed_back,
                  cache.refollowedCount,
                ),
                _buildDetailListItem(
                  context,
                  'new_followers_following',
                  Icons.person_add_alt_1_outlined,
                  l10n.new_followers_following,
                  cache.newFollowersCount,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),

          // --- 新增：上次更新时间 ---
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Center(
              child: Text(
                _getFormattedLastUpdate(context, l10n, cache.lastUpdateTime),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ),
          // --- 新增结束 ---
        ],
      ),
    );
  }

  Widget _buildDetailListItem(
    BuildContext context,
    String categoryKey,
    IconData icon,
    String label,
    int count, {
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: () => _navigateToUserList(context, categoryKey),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeAccount = ref.watch(activeAccountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.app_title)),
      body: activeAccount == null
          ? _buildNoAccountState(context, widget.onNavigateToAccounts)
          : _buildAccountView(context),
      floatingActionButton: activeAccount == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final currentContext = context;
                final currentRef = ref;
                final currentL10n = AppLocalizations.of(currentContext)!;
                final currentTheme = Theme.of(currentContext);

                // --- 修改：在 showDialog 之前启动分析 ---
                // (这将立即设置 analysisIsRunningProvider 为 true)
                // (并且异步执行，不会阻塞 UI)
                // 我们在 try/catch 之外调用它，因为日志对话框会处理自己的错误
                // 确保 accountToProcess 在调用前被检查
                final accountToProcess = currentRef.read(activeAccountProvider);
                if (accountToProcess == null) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        currentL10n.no_active_account_error,
                        style: TextStyle(
                          color: currentTheme.colorScheme.onError,
                        ),
                      ),
                      backgroundColor: currentTheme.colorScheme.error,
                    ),
                  );
                  return; // 没有活动账号，不执行
                }

                // 异步调用，但不等待它
                // 我们将通过 analysisIsRunningProvider 观察它的完成
                currentRef
                    .read(analysisServiceProvider.notifier)
                    .runAnalysis(accountToProcess)
                    .catchError((e) {
                      // 即使在 provider 中捕获了错误，这里也可能需要一个顶层捕获
                      // 以防 runAnalysisProcess 本身抛出（例如 accountToProcess 为 null）
                      // 已经在 provider 内部处理了
                      print(
                        "runAnalysisProcess top-level error (should be handled in Notifier): $e",
                      );
                    })
                    .whenComplete(() {
                      // 无论成功还是失败，都触发 cacheProvider 刷新
                      currentRef.invalidate(cacheProvider);
                    });

                // --- 立即显示对话框 ---
                showDialog(
                  context: currentContext,
                  barrierDismissible: false,
                  builder: (dialogContext) => PopScope(
                    canPop: false,
                    child: AlertDialog(
                      title: Row(
                        children: [
                          Consumer(
                            // 让转圈动画也监听状态
                            builder: (context, ref, child) {
                              final isRunning = ref.watch(
                                analysisIsRunningProvider,
                              );
                              return isRunning
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ); // 完成时显示勾
                            },
                          ),
                          SizedBox(width: 16),
                          Text(currentL10n.analysis_log),
                        ],
                      ),
                      // --- 修改：使用不可编辑的 TextField ---
                      content: SizedBox(
                        width: double.maxFinite,
                        height: MediaQuery.of(currentContext).size.height * 0.7,
                        child: Consumer(
                          builder: (context, ref, child) {
                            final logs = ref.watch(analysisLogProvider);
                            final String logText = logs.join('\n');
                            // 使用 TextEditingController 来设置文本
                            final controller = TextEditingController(
                              text: logText,
                            );

                            return Container(
                              decoration: BoxDecoration(
                                color: currentTheme
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: SingleChildScrollView(
                                reverse: true, // 尝试自动滚动到底部
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: controller,
                                  readOnly: true,
                                  maxLines: null,
                                  decoration: InputDecoration.collapsed(
                                    hintText: null,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: currentTheme
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // --- 修改：根据状态显示/隐藏关闭按钮 ---
                      actions: [
                        Consumer(
                          builder: (context, ref, child) {
                            final isRunning = ref.watch(
                              analysisIsRunningProvider,
                            );
                            // 运行时隐藏按钮
                            if (isRunning) return const SizedBox.shrink();
                            // 运行结束后显示按钮
                            return TextButton(
                              child: Text(currentL10n.close),
                              onPressed: () => Navigator.pop(dialogContext),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
                // --- 移除 try/catch/finally 块 ---
                // (因为逻辑已经移入 Notifier 和 Dialog 状态)
              },
              label: Text(l10n.run),
              icon: const Icon(Icons.play_arrow),
            ),
    );
  }
}
