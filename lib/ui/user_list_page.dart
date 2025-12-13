import 'package:autonitor/models/twitter_user.dart';
import 'package:autonitor/ui/components/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/ui/user_detail_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../providers/report_providers.dart';
import 'package:autonitor/providers/media_provider.dart';

class UserListTile extends StatelessWidget {
  final TwitterUser user;
  final String? mediaDir;
  final VoidCallback? onTap;
  final String followingLabel;
  final bool isFollower;
  final String? customHeroTag;
  final String? highlightQuery;

  const UserListTile({
    super.key,
    required this.user,
    required this.mediaDir,
    required this.onTap,
    required this.followingLabel,
    required this.isFollower,
    this.customHeroTag,
    this.highlightQuery,
  });

  List<TextSpan> _buildHighlightedSpans(
    BuildContext context,
    String text,
    String? query,
    TextStyle? baseStyle,
  ) {
    if (query == null || query.trim().isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight = lowerText.indexOf(lowerQuery);

    while (indexOfHighlight != -1) {
      if (indexOfHighlight > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, indexOfHighlight),
            style: baseStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(
            indexOfHighlight,
            indexOfHighlight + query.length,
          ),
          style: baseStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = indexOfHighlight + query.length;
      indexOfHighlight = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final avatarWidget = UserAvatar(
      avatarUrl: user.avatarUrl,
      avatarLocalPath: user.avatarLocalPath,
      mediaDir: mediaDir,
      radius: 24,
      heroTag: customHeroTag ?? 'avatar_${user.restId}',
      isHighQuality:
          true, // List view usually looks better with HQ or at least bigger
    );

    final listTile = ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      onTap: user.isFollower ? null : onTap,
      leading: avatarWidget,
      title: _buildTitleRow(context, user),
      subtitle: _buildSubtitle(context, user, l10n),
    );

    final content = isFollower
        ? InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.follows_you,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(child: listTile),
              ],
            ),
          )
        : listTile;

    return RepaintBoundary(child: content);
  }

  Widget _buildTitleRow(BuildContext context, TwitterUser user) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: _buildHighlightedSpans(
                          context,
                          user.name ?? 'Unknown Name',
                          highlightQuery,
                          const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ... icons (verified/protected) remain same
                  if (user.isVerified)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: SvgPicture.asset(
                        'assets/icon/verified.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF1DA1F2),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  if (user.isProtected)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: SvgPicture.asset(
                        'assets/icon/protected.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                ],
              ),
              // [修改] ScreenName 高亮，保留 hintColor
              Text.rich(
                TextSpan(
                  children: _buildHighlightedSpans(
                    context,
                    "@${user.screenName}",
                    highlightQuery,
                    theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (user.isFollowing)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              followingLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    TwitterUser user,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (user.automatedScreenName != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icon/bot.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).hintColor,
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (_) =>
                          const SizedBox(width: 16, height: 16),
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      child: Text(
                        l10n.automated,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              if (user.parodyCommentaryFanLabel != null &&
                  user.parodyCommentaryFanLabel != "None")
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icon/mask.svg',
                      width: 16,
                      height: 16,
                      placeholderBuilder: (_) =>
                          const SizedBox(width: 16, height: 16),
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      child: Text(
                        user.parodyCommentaryFanLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (user.bio?.isNotEmpty == true && user.bio != null)
            _buildBio(context, user.bio!),
        ],
      ),
    );
  }

  Widget _buildBio(BuildContext context, String bio) {
    // 判定是否匹配：搜索词不为空 且 Bio 包含搜索词 (忽略大小写)
    final bool isMatch =
        highlightQuery != null &&
        highlightQuery!.trim().isNotEmpty &&
        bio.toLowerCase().contains(highlightQuery!.toLowerCase());

    if (isMatch) {
      // [逻辑 A] 匹配成功：高亮 + 不折叠 (移除 maxLines)
      return Text.rich(
        TextSpan(
          children: _buildHighlightedSpans(
            context,
            bio,
            highlightQuery,
            Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // [逻辑 B] 未匹配：普通显示 + 限制 2 行 + 省略号
    return Text(
      bio,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class UserListPage extends ConsumerStatefulWidget {
  final String ownerId;
  final String categoryKey;

  const UserListPage({
    super.key,
    required this.ownerId,
    required this.categoryKey,
  });

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage>
    with AutomaticKeepAliveClientMixin {
  bool _routeAnimationCompleted = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      final animation = route?.animation;

      if (animation == null) {
        _markRouteCompleted();
        return;
      }

      if (animation.status == AnimationStatus.completed) {
        _markRouteCompleted();
      } else {
        late final AnimationStatusListener listener;
        listener = (status) {
          if (status == AnimationStatus.completed) {
            animation.removeStatusListener(listener);
            _markRouteCompleted();
          }
        };
        animation.addStatusListener(listener);
      }
    });
  }

  void _markRouteCompleted() {
    if (!mounted) return;

    setState(() {
      _routeAnimationCompleted = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String getLocalizedTitle(AppLocalizations l10n) {
    switch (widget.categoryKey) {
      case 'followers':
        return l10n.followers;
      case 'following':
        return l10n.following;
      case 'normal_unfollowed':
        return l10n.normal_unfollowed;
      case 'mutual_unfollowed':
        return l10n.mutual_unfollowed;
      case 'oneway_unfollowed':
        return l10n.oneway_unfollowed;
      case 'temporarily_restricted':
        return l10n.temporarily_restricted;
      case 'suspended':
        return l10n.suspended;
      case 'deactivated':
        return l10n.deactivated;
      case 'be_followed_back':
        return l10n.be_followed_back;
      case 'new_followers_following':
        return l10n.new_followers_following;
      case 'recovered':
        return l10n.recovered;
      default:
        return widget.categoryKey;
    }
  }

  Widget _buildSuspendedBanner(BuildContext context) {
    if (widget.categoryKey == 'suspended') {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: AspectRatio(
            aspectRatio: 1500 / 500,
            child: Image.asset(
              'assets/suspended_banner.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(getLocalizedTitle(l10n))),
      body: Column(
        children: [
          _buildSuspendedBanner(context),

          Expanded(
            child: Builder(
              builder: (context) {
                const loadingWidget = Center(
                  child: CircularProgressIndicator(),
                );

                if (!_routeAnimationCompleted) {
                  return loadingWidget;
                }

                final param = UserListParam(
                  ownerId: widget.ownerId,
                  categoryKey: widget.categoryKey,
                );

                final userListAsync = ref.watch(userListProvider(param));
                final mediaDirAsync = ref.watch(appSupportDirProvider);

                return userListAsync.when(
                  loading: () => loadingWidget,

                  error: (err, stack) => Center(
                    child: Text('${l10n.failed_to_load_user_list}: $err'),
                  ),
                  data: (users) {
                    if (users.isEmpty) {
                      return Center(
                        child: Text(l10n.no_users_in_this_category),
                      );
                    }

                    final bool hasMore = ref
                        .read(userListProvider(param).notifier)
                        .hasMore();

                    final int itemCount = users.length + (hasMore ? 1 : 0);

                    final mediaDir = mediaDirAsync.value;

                    // 使用 ListView + Center + ConstrainedBox 替代 GridView
                    // 彻底解决像素溢出问题，同时适配大屏幕
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      cacheExtent: 1000,
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (index == users.length) {
                          return _buildLoadingFooter(param);
                        }

                        // 核心修改：在每个 Item 外层包裹 Center 和 ConstrainedBox
                        // 这样在宽屏下内容居中且宽度受限，在窄屏下自适应
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Card(
                              elevation: 0, // 列表模式下通常不需要高阴影，0或默认即可，视设计而定
                              margin: EdgeInsets
                                  .zero, // 移除 Card 默认边距，由 UserListTile 控制或外部 Padding 控制
                              color: Colors.transparent, // 透明背景，让 Tile 自己处理
                              child: _buildListItem(
                                context,
                                users[index],
                                mediaDir,
                                l10n,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingFooter(UserListParam param) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(userListProvider(param).notifier);
      if (notifier.hasMore()) {
        notifier.fetchMore();
      }
    });

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    TwitterUser user,
    String? mediaDir,
    AppLocalizations l10n,
  ) {
    void onTapAction() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserDetailPage(
            key: ValueKey(user.restId),
            user: user,
            ownerId: widget.ownerId,
          ),
        ),
      );
    }

    return UserListTile(
      key: ValueKey(user.restId),
      user: user,
      mediaDir: mediaDir,
      onTap: onTapAction,
      followingLabel: l10n.following,
      isFollower: user.isFollower,
    );
  }
}
