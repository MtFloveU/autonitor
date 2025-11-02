import 'dart:io';

import 'package:autonitor/services/log_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/ui/user_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import '../l10n/app_localizations.dart';
import '../providers/report_providers.dart';
import 'package:autonitor/providers/media_provider.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final param = UserListParam(
        ownerId: widget.ownerId,
        categoryKey: widget.categoryKey,
      );
      ref.read(userListProvider(param).notifier).fetchMore();
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
    final l10n = AppLocalizations.of(context)!;
    final param = UserListParam(
      ownerId: widget.ownerId,
      categoryKey: widget.categoryKey,
    );
    final userListAsync = ref.watch(userListProvider(param));
    final mediaDirAsync = ref.watch(appSupportDirProvider);

    return Scaffold(
      appBar: AppBar(title: Text(getLocalizedTitle(l10n))),
      body: Column(
        children: [
          _buildSuspendedBanner(context),
          Expanded(
            child: userListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('${l10n.failed_to_load_user_list}: $err')),
              data: (users) {
                if (users.isEmpty) {
                  return Center(child: Text(l10n.no_users_in_this_category));
                }

                final bool hasMore = ref
                    .read(userListProvider(param).notifier)
                    .hasMore();
                final int itemCount = users.length + (hasMore ? 1 : 0);

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == users.length) {
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

                    final user = users[index];
                    final String? localAvatarPath = user.avatarLocalPath;
                    final String? networkAvatarUrl = user.avatarUrl;
                    final String? relativeLocalPath = user.avatarLocalPath;
                    // 2. 拼接绝对路径
                    final String? absoluteLocalPath =
                        (mediaDirAsync.hasValue &&
                            relativeLocalPath != null &&
                            relativeLocalPath.isNotEmpty)
                        ? p.join(mediaDirAsync.value!, relativeLocalPath)
                        : null;
                    logger.d(absoluteLocalPath);

                    bool isLocalHighQuality = false;
                    if (absoluteLocalPath != null &&
                        absoluteLocalPath.contains('_high')) {
                      isLocalHighQuality = true;
                    }

                    final String highQualityNetworkUrl =
                        (networkAvatarUrl ?? '').replaceFirst(
                          RegExp(r'_(normal|bigger|400x400)'),
                          '_400x400',
                        );

                    bool fetchNetworkLayer =
                        !isLocalHighQuality && highQualityNetworkUrl.isNotEmpty;
                    return ListTile(
                      leading: Hero(
                        tag: 'avatar_${user.restId}',
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // --- 修改开始: 替换 ClipOval ---
                              // Layer 1: Base Icon
                              const Icon(Icons.person, size: 24),

                              // Layer 2: Local File
                              if (localAvatarPath != null &&
                                  localAvatarPath.isNotEmpty)
                                ClipOval(
                                  child: Image.file(
                                    File(localAvatarPath),
                                    fit: BoxFit.cover,
                                    width: 48,
                                    height: 48,
                                    // 渐显
                                    frameBuilder:
                                        (context, child, frame, wasSync) {
                                          if (wasSync) return child;
                                          return AnimatedOpacity(
                                            opacity: frame == null ? 0 : 1,
                                            duration: const Duration(
                                              milliseconds: 0,
                                            ),
                                            child: child,
                                          );
                                        },
                                    // 加载失败时显示底层
                                    errorBuilder: (context, e, s) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),

                              // Layer 3: Network File (High Quality)
                              if (fetchNetworkLayer)
                                ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: highQualityNetworkUrl,
                                    fit: BoxFit.cover,
                                    width: 48,
                                    height: 48,
                                    fadeInDuration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    placeholder: (context, url) =>
                                        const SizedBox.shrink(),
                                    errorWidget: (context, url, error) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              // --- 修改结束 ---
                            ],
                          ),
                        ),
                      ),
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified)
                            SvgPicture.asset(
                              'assets/icon/verified.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF1DA1F2),
                                BlendMode.srcIn,
                              ),
                            ),
                          if (user.isProtected)
                            SvgPicture.asset(
                              'assets/icon/protected.svg',
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "@${user.id}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.bio ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserDetailPage(user: user),
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
}
