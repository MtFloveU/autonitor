part of 'home_page.dart';

extension _HomePageWidgets on _HomePageState {
  /// 格式化最后更新时间
  String _getFormattedLastUpdate(
    BuildContext context,
    AppLocalizations l10n,
    String isoString,
  ) {
    if (isoString.isEmpty) return l10n.last_updated_at("N/A");
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final formattedDate = DateFormat.yMd().add_Hms().format(
        DateTime.fromMillisecondsSinceEpoch(dateTime.millisecondsSinceEpoch),
      );
      return l10n.last_updated_at(formattedDate);
    } catch (e) {
      return l10n.last_updated_at("Invalid Date");
    }
  }

  /// 显示账号切换底栏
  void _showAccountSwitcher(BuildContext context) {
    final allAccounts = ref.read(accountsProvider);
    final activeAccount = ref.read(activeAccountProvider);
    final mediaDir = ref.watch(appSupportDirProvider).value;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ...allAccounts.map((account) {
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      UserAvatar(
                        avatarUrl: account.avatarUrl,
                        avatarLocalPath: account.avatarLocalPath,
                        mediaDir: mediaDir,
                        radius: 24,
                        heroTag: 'avatar_${account.id}',
                        isHighQuality: true,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "ID: ${account.id}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  ref
                      .read(activeAccountStateProvider.notifier)
                      .setActive(account);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  /// 构建未登录状态 UI
  Widget _buildNoAccountState(BuildContext context, VoidCallback onNavigate) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
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

  /// 构建用户资料卡片
  Widget _buildUserProfileCard(BuildContext context, CacheData? cache) {
    final l10n = AppLocalizations.of(context)!;
    final activeAccount = ref.watch(activeAccountProvider);
    final mediaDir = ref.watch(appSupportDirProvider).value;

    if (activeAccount == null) return const SizedBox.shrink();

    final followingCount = cache?.followingCount ?? "--";
    final followersCount = cache?.followersCount ?? "--";

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          final user = TwitterUser(
            avatarUrl: activeAccount.avatarUrl ?? '',
            avatarLocalPath: activeAccount.avatarLocalPath ?? '',
            bannerLocalPath: activeAccount.bannerLocalPath ?? '',
            name: activeAccount.name ?? 'Unknown',
            screenName: activeAccount.screenName ?? activeAccount.id,
            restId: activeAccount.id,
            joinedTime: activeAccount.joinTime ?? '',
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
            isProtected: activeAccount.isProtected,
            isVerified: activeAccount.isVerified,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  UserDetailPage(user: user, ownerId: activeAccount.id),
            ),
          );
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  UserAvatar(
                    avatarUrl: activeAccount.avatarUrl,
                    avatarLocalPath: activeAccount.avatarLocalPath,
                    mediaDir: mediaDir,
                    radius: 24,
                    heroTag: 'avatar_${activeAccount.id}',
                    isHighQuality: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeAccount.name ?? 'Unknown Name',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "@${activeAccount.screenName ?? activeAccount.id}",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "ID: ${activeAccount.id}",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
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
                      onTap: () => _navigateToUserList(context, 'following'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            Text(
                              followingCount.toString(),
                              style: Theme.of(context).textTheme.titleMedium
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
                      onTap: () => _navigateToUserList(context, 'followers'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            Text(
                              followersCount.toString(),
                              style: Theme.of(context).textTheme.titleMedium
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
            ),
          ],
        ),
      ),
    );
  }

  /// 构建无数据状态 UI
  Widget _buildNoDataState(BuildContext context, VoidCallback onNavigate) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildUserProfileCard(context, null),
        const SizedBox(height: 60),
        Icon(
          Icons.folder_off_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.no_data,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(l10n.no_data_description, textAlign: TextAlign.center),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 构建账号视图入口
  Widget _buildAccountView(BuildContext context) {
    final cacheAsyncValue = ref.watch(cacheProvider);
    final mediaDir = ref.watch(appSupportDirProvider).value;
    return cacheAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error on cache: $err')),
      data: (cacheData) {
        if (cacheData == null) {
          return _buildNoDataState(context, () {});
        }
        return _buildDataDisplay(context, cacheData, mediaDir);
      },
    );
  }

  /// 构建数据展示列表
  Widget _buildDataDisplay(
    BuildContext context,
    CacheData cache,
    String? mediaDir,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
      children: <Widget>[
        _buildUserProfileCard(context, cache),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _buildDetailListItem(
                context,
                'profile_update',
                Icons.badge_outlined,
                l10n.profile_updates,
                cache.profileUpdatedCount,
              ),
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
              ),
              _buildDetailListItem(
                context,
                'recovered',
                Icons.refresh_rounded,
                l10n.recovered,
                cache.recoveredCount,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: Center(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${_getFormattedLastUpdate(context, l10n, cache.lastUpdateTime)} ${cache.lastRunId}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建详情列表项
  Widget _buildDetailListItem(
    BuildContext context,
    String categoryKey,
    IconData icon,
    String label,
    int count, {
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () => _navigateToUserList(context, categoryKey),
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
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, indent: 56),
        ],
      ),
    );
  }
}
