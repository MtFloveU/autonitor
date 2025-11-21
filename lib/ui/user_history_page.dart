// [文件: lib/ui/user_history_page.dart]

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:autonitor/providers/media_provider.dart';
import 'package:autonitor/providers/history_provider.dart';
import 'package:autonitor/ui/user_detail_page.dart';
import '../models/twitter_user.dart';
import '../l10n/app_localizations.dart';

class UserHistoryPage extends ConsumerWidget {
  final TwitterUser user;
  final String ownerId;

  const UserHistoryPage({
    super.key,
    required this.user,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = user.restId; // <-- 2. 修复：使用 restId 更准确

    // 3. Watch 我们的新 Provider
    final params = ProfileHistoryParams(ownerId: ownerId, userId: userId);
    final historyAsync = ref.watch(profileHistoryProvider(params));

    // 4. Watch 媒体路径 Provider (用于渲染头像)
    final mediaDirAsync = ref.watch(appSupportDirProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.user_history_page_title),
            const SizedBox(height: 2),
            Text(
              '@${user.screenName}', // <-- 这里显示 @handle 没问题
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      // 5. 使用 .when() 处理加载状态
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // 显示你截图中的错误
            child: Text('${l10n.failed_to_load_user_list}:\n$err'),
          ),
        ),
        data: (snapshots) {
          // 6. 处理空列表
          if (snapshots.isEmpty) {
            return Center(child: Text(l10n.no_users_in_this_category));
          }

          // 7. 构建列表
          return ListView.builder(
            itemCount: snapshots.length,
            itemBuilder: (context, index) {
              final snapshot = snapshots[index];
              final snapshotUser = snapshot.user; // 重建的 user 对象

              // --- 8. 复制 user_list_page 的头像渲染逻辑 ---
              final String? relativeLocalPath = snapshotUser.avatarLocalPath;
              final String? absoluteLocalPath = (mediaDirAsync.hasValue &&
                      relativeLocalPath != null &&
                      relativeLocalPath.isNotEmpty)
                  ? p.join(mediaDirAsync.value!, relativeLocalPath)
                  : null;

              final String? networkAvatarUrl = snapshotUser.avatarUrl;
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
              // --- 头像逻辑结束 ---

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 9. 添加你要求的 "设置页" 风格的 Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      // 格式化时间
                      "ID: ${snapshot.entry.id}  (${snapshot.entry.timestamp.toLocal().toString().substring(0, 16)})",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // 10. 添加 "user_list_page" 风格的 ListTile
                  ListTile(
                    leading: Hero(
                      // 注意：Tag 必须是唯一的，我们用 snapshot ID 附加
                      tag: 'avatar_${snapshotUser.restId}_${snapshot.entry.id}',
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.person, size: 24),
                            if (absoluteLocalPath != null)
                              ClipOval(
                                child: Image.file(
                                  File(absoluteLocalPath),
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                  frameBuilder:
                                      (context, child, frame, wasSync) {
                                    if (wasSync) return child;
                                    return AnimatedOpacity(
                                      opacity: frame == null ? 0 : 1,
                                      duration:
                                          const Duration(milliseconds: 0),
                                      child: child,
                                    );
                                  },
                                  errorBuilder: (context, e, s) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            if (fetchNetworkLayer)
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: highQualityNetworkUrl,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                  fadeInDuration:
                                      const Duration(milliseconds: 300),
                                  placeholder: (context, url) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (context, url, error) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
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
                            snapshotUser.name ?? 'Unknown Name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (snapshotUser.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: SvgPicture.asset(
                              'assets/icon/verified.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                  Color(0xFF1DA1F2), BlendMode.srcIn),
                            ),
                          ),
                        if (snapshotUser.isProtected)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "@${snapshotUser.screenName}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          snapshotUser.bio ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    onTap: () {
                      // 11. 导航到详情页，并传递所有历史数据
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetailPage(
                            user: snapshotUser, // 传入重建的 user
                            ownerId: ownerId,
                            isFromHistory: true, // 标记为来自历史
                            snapshotJson: snapshot.fullJson, //x 传入重建的 JSON
                            snapshotId: snapshot.entry.id, // 传入快照 ID
                            snapshotTimestamp: snapshot.entry.timestamp, // 传入时间
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}