import 'dart:convert';
import 'package:autonitor/models/twitter_user.dart';
import 'package:autonitor/ui/components/user_avatar.dart';
import 'package:autonitor/ui/components/profile_change_card.dart';
import 'package:autonitor/repositories/analysis_report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final String? avatarLocalPathOverride;

  const UserListTile({
    super.key,
    required this.user,
    required this.mediaDir,
    required this.onTap,
    required this.followingLabel,
    required this.isFollower,
    this.customHeroTag,
    this.highlightQuery,
    this.avatarLocalPathOverride,
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

    final effectiveAvatarPath = avatarLocalPathOverride ?? user.avatarLocalPath;

    final avatarWidget = UserAvatar(
      avatarUrl: user.avatarUrl,
      avatarLocalPath: effectiveAvatarPath,
      mediaDir: mediaDir,
      radius: 24,
      heroTag: customHeroTag ?? 'avatar_${user.restId}',
      isHighQuality: true,
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 名字 + @screenName
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        theme.colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                children: _buildHighlightedSpans(
                  context,
                  "@${user.screenName}",
                  highlightQuery,
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),

        // 浮动的 followingLabel
        if (user.isFollowing)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: theme.canvasColor,
                border: Border.all(color: theme.dividerColor, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                followingLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
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
    final bool isMatch =
        highlightQuery != null &&
        highlightQuery!.trim().isNotEmpty &&
        bio.toLowerCase().contains(highlightQuery!.toLowerCase());

    if (isMatch) {
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

class _UserListPageState extends ConsumerState<UserListPage> {
  // [恢复] 路由动画检测，确保转场动画完成后再加载数据
  bool _routeAnimationCompleted = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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

  // 字符串清洗函数：修复 UTF-16 错误
  String _sanitizeJson(String input) {
    try {
      // 尝试通过 round-trip 替换掉不合法的 surrogate pair
      return utf8.decode(utf8.encode(input), allowMalformed: true);
    } catch (_) {
      // 极端情况返回空 JSON 对象防止崩溃
      return '{}';
    }
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
      case 'profile_update':
        return l10n.profile_updates;
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
    final l10n = AppLocalizations.of(context)!;

    // 1. 定义 Provider 参数
    final param = UserListParam(
      ownerId: widget.ownerId,
      categoryKey: widget.categoryKey,
    );

    return Scaffold(
      appBar: AppBar(title: Text(getLocalizedTitle(l10n))),
      body: Column(
        children: [
          _buildSuspendedBanner(context),

          Expanded(
            // [恢复] 如果动画未完成，显示 Loading，暂不触发 Provider 监听（也就不会开始查询）
            child: !_routeAnimationCompleted
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      // 2. 只有动画完成后，才开始 watch 数据
                      // 这样可以避免转场动画卡顿
                      final pagedListAsync = ref.watch(userListProvider(param));
                      final mediaDirAsync = ref.watch(appSupportDirProvider);

                      return mediaDirAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text('Media Error: $err')),
                        data: (mediaDir) {
                          return pagedListAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, stack) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  '${l10n.failed_to_load_user_list}: $err',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            data: (pagedState) {
                              if (pagedState.users.isEmpty) {
                                return Center(
                                  child: Text(l10n.no_users_in_this_category),
                                );
                              }

                              return Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: pagedState.users.length,
                                      itemBuilder: (context, index) {
                                        return Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 800,
                                            ),
                                            child: Card(
                                              elevation: 0,
                                              margin: EdgeInsets.zero,
                                              color: Colors.transparent,
                                              child: _buildListItem(
                                                context,
                                                pagedState.users[index],
                                                mediaDir,
                                                l10n,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // 分页控制栏
                                  _PaginationControls(
                                    currentPage: pagedState.currentPage,
                                    totalPages: pagedState.totalPages,
                                    totalCount: pagedState.totalCount,
                                    onPageChanged: (page) {
                                      ref
                                          .read(
                                            userListProvider(param).notifier,
                                          )
                                          .setPage(page);
                                      _scrollController.jumpTo(0);
                                    },
                                  ),
                                ],
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

  Widget _buildListItem(
    BuildContext context,
    TwitterUser user,
    String? mediaDir,
    AppLocalizations l10n,
  ) {
    if (widget.categoryKey == 'profile_update') {
      try {
        String jsonContent;
        if (user is ProfileSnapshotUser) {
          jsonContent = user.jsonSnapshot;
        } else {
          jsonContent = jsonEncode(user.toJson());
        }

        // 清洗 JSON 字符串，防止 UTF-16 错误
        jsonContent = _sanitizeJson(jsonContent);

        final data = jsonDecode(jsonContent);

        DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(0);
        if (data['timestamp'] != null) {
          timestamp = DateTime.parse(data['timestamp']);
        }

        final String heroTag =
            'profile_diff_${user.restId}_${timestamp.millisecondsSinceEpoch}';

        void onTapAction() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailPage(
                key: ValueKey(user.restId),
                user: user,
                ownerId: widget.ownerId,
                heroTag: heroTag,
              ),
            ),
          );
        }

        return ProfileChangeCard(
          jsonContent: jsonContent,
          timestamp: timestamp,
          onTap: onTapAction,
          mediaDir: mediaDir,
          heroTag: heroTag,
          avatarLocalPath: user.avatarLocalPath,
        );
      } catch (e) {
        return const SizedBox.shrink();
      }
    }

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

// ---------------------------------------------------------------------------
// 分页控制组件 (遵循 MD3 风格)
// ---------------------------------------------------------------------------
class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.onPageChanged,
  });

  void _showJumpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;

        void clampValue() {
          final text = controller.text;
          if (text.isEmpty) return;
          final value = int.tryParse(text);
          if (value == null) return;
          final clamped = value.clamp(1, totalPages);
          if (clamped.toString() != text) {
            controller.value = TextEditingValue(
              text: clamped.toString(),
              selection: TextSelection.collapsed(
                offset: clamped.toString().length,
              ),
            );
          }
        }

        controller.addListener(clampValue);

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: '${l10n.jump_to_page} (1-$totalPages)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
                onSubmitted: (_) {
                  final page = int.tryParse(controller.text);
                  if (page != null) {
                    onPageChanged(page);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final page = int.tryParse(controller.text);
                  if (page != null) {
                    onPageChanged(page);
                    Navigator.pop(context);
                  }
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous Button
            IconButton.filledTonal(
              icon: const Icon(Icons.chevron_left),
              onPressed: currentPage > 1
                  ? () => onPageChanged(currentPage - 1)
                  : null,
            ),
            const SizedBox(width: 16),

            // Page Indicator (Clickable) - 使用 Flexible 防止溢出
            Flexible(
              child: InkWell(
                onTap: totalPages > 1 ? () => _showJumpDialog(context) : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: l10n.jump_to_page,
                        child: Text(
                          '$currentPage / $totalPages',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text(
                        l10n.total(totalCount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Next Button
            IconButton.filledTonal(
              icon: const Icon(Icons.chevron_right),
              onPressed: currentPage < totalPages
                  ? () => onPageChanged(currentPage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
