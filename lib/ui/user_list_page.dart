import 'dart:io';
import 'package:autonitor/models/twitter_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/ui/user_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import '../l10n/app_localizations.dart';
import '../providers/report_providers.dart';
import 'package:autonitor/providers/media_provider.dart';

final RegExp _avatarSizeRegex = RegExp(r'_(normal|bigger|400x400)');

class _UserDisplayData {
  final String? absoluteLocalPath;
  final String highQualityNetworkUrl;
  final bool fetchNetworkLayer;

  _UserDisplayData({
    required this.absoluteLocalPath,
    required this.highQualityNetworkUrl,
    required this.fetchNetworkLayer,
  });
}

class UserListTile extends StatelessWidget {
  final TwitterUser user;
  final String? mediaDir;
  final VoidCallback? onTap;
  final String followingLabel;
  final bool isFollower;

  const UserListTile({
    super.key,
    required this.user,
    required this.mediaDir,
    required this.onTap,
    required this.followingLabel,
    required this.isFollower,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _calculateDisplayData(user, mediaDir);

    final avatarWidget = Hero(
      tag: 'avatar_${user.restId}',
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: _OptimizedUserAvatar(
            absoluteLocalPath: data.absoluteLocalPath,
            highQualityNetworkUrl: data.highQualityNetworkUrl,
            fetchNetworkLayer: data.fetchNetworkLayer,
          ),
        ),
      ),
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
                    child: Text(
                      user.name ?? 'Unknown Name',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
              Text(
                "@${user.screenName}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
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
          if (user.automatedScreenName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icon/bot.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).hintColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l10n.automated_by(user.automatedScreenName!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (user.parodyCommentaryFanLabel != null &&
              user.parodyCommentaryFanLabel != "None")
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icon/mask.svg',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "${user.parodyCommentaryFanLabel!} account",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            user.bio ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

_UserDisplayData _calculateDisplayData(TwitterUser user, String? mediaDir) {
  final String? relativeLocalPath = user.avatarLocalPath;
  final String? absoluteLocalPath =
      (mediaDir != null &&
          relativeLocalPath != null &&
          relativeLocalPath.isNotEmpty)
      ? p.join(mediaDir, relativeLocalPath)
      : null;

  final String highQualityNetworkUrl = (user.avatarUrl ?? '').replaceFirst(
    _avatarSizeRegex,
    '_400x400',
  );

  final bool isLocalHighQuality =
      absoluteLocalPath != null && absoluteLocalPath.contains('_high');

  return _UserDisplayData(
    absoluteLocalPath: absoluteLocalPath,
    highQualityNetworkUrl: highQualityNetworkUrl,
    fetchNetworkLayer: !isLocalHighQuality && highQualityNetworkUrl.isNotEmpty,
  );
}

class _OptimizedUserAvatar extends StatelessWidget {
  final String? absoluteLocalPath;
  final String highQualityNetworkUrl;
  final bool fetchNetworkLayer;

  const _OptimizedUserAvatar({
    required this.absoluteLocalPath,
    required this.highQualityNetworkUrl,
    required this.fetchNetworkLayer,
  });

  @override
  Widget build(BuildContext context) {
    const placeholder = SizedBox(width: 48, height: 48);

    if (absoluteLocalPath != null) {
      return Image.file(
        File(absoluteLocalPath!),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        cacheWidth: 100,
        errorBuilder: (context, error, stackTrace) {
          if (absoluteLocalPath == null && highQualityNetworkUrl.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: highQualityNetworkUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              memCacheWidth: 100,
              placeholder: (context, url) => placeholder,
              errorWidget: (context, url, error) => placeholder,
              fadeInDuration: const Duration(milliseconds: 200),
            );
          }
          return placeholder;
        },
      );
    }

    if (absoluteLocalPath == null && highQualityNetworkUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: highQualityNetworkUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        memCacheWidth: 100,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      );
    }

    return placeholder;
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

    // ✅ 监听路由进入动画
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
      default:
        return widget.categoryKey;
    }
  }

  Widget _buildSuspendedBanner(BuildContext context) {
    if (widget.categoryKey == 'suspended') {
      return AspectRatio(
        aspectRatio: 1500 / 500,
        child: Image.asset('assets/suspended_banner.png', fit: BoxFit.cover),
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
            child: !_routeAnimationCompleted
                ? const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final param = UserListParam(
                        ownerId: widget.ownerId,
                        categoryKey: widget.categoryKey,
                      );

                      final userListAsync = ref.watch(userListProvider(param));
                      final mediaDirAsync = ref.watch(appSupportDirProvider);

                      return userListAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
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

                          final int itemCount =
                              users.length + (hasMore ? 1 : 0);

                          final mediaDir = mediaDirAsync.value;

                          return ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            cacheExtent: 1000,
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              if (index == users.length) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  final notifier = ref.read(
                                    userListProvider(param).notifier,
                                  );
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
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final user = users[index];

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
}
