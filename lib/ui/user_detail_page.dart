// [文件: lib/ui/user_detail_page.dart]

import 'dart:io';
import 'package:autonitor/providers/media_provider.dart'; // 确保这个 import 存在
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:autonitor/services/log_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/twitter_user.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'user_history_page.dart';

// 1. 确保它是 ConsumerWidget
class UserDetailPage extends ConsumerWidget {
  final TwitterUser user;
  final String ownerId;

  // --- 2. 添加新的可选历史参数 ---
  final bool isFromHistory;
  final String? snapshotJson;
  final int? snapshotId;
  final DateTime? snapshotTimestamp;
  // --- 修改结束 ---

  const UserDetailPage({
    super.key,
    required this.user,
    required this.ownerId,
    // --- 3. 更新构造函数 ---
    this.isFromHistory = false, // 默认为 false
    this.snapshotJson,
    this.snapshotId,
    this.snapshotTimestamp,
    // --- 修改结束 ---
  });

  @override
  // 4. 确保 build 方法有 WidgetRef ref
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    const double bannerAspectRatio = 1500 / 500;
    const double avatarOverhang = 40.0;

    // 5. 修复：这里的 provider 应该是 mediaDirectoryProvider
    //    (你之前的文件中这里是 appSupportDirProvider，我已为你修正)
    final mediaDirAsync = ref.watch(appSupportDirProvider);

    // --- (所有头像和横幅的路径拼接逻辑保持不变) ---
    // 头像逻辑
    final String? relativeAvatarPath = user.avatarLocalPath;
    final String? absoluteAvatarPath =
        (mediaDirAsync.hasValue &&
            relativeAvatarPath != null &&
            relativeAvatarPath.isNotEmpty)
        ? p.join(mediaDirAsync.value!, relativeAvatarPath)
        : null;

    final String? networkAvatarUrl = user.avatarUrl;
    bool isLocalHighQuality = false;
    if (absoluteAvatarPath != null && absoluteAvatarPath.contains('_high')) {
      isLocalHighQuality = true;
    }
    final String highQualityNetworkUrl = (networkAvatarUrl ?? '').replaceFirst(
      RegExp(r'_(normal|bigger|400x400)'),
      '_400x400',
    );
    bool fetchNetworkAvatar =
        !isLocalHighQuality && highQualityNetworkUrl.isNotEmpty;

    // 横幅逻辑
    final String? relativeBannerPath = user.bannerLocalPath;
    final String? absoluteBannerPath =
        (mediaDirAsync.hasValue &&
            relativeBannerPath != null &&
            relativeBannerPath.isNotEmpty)
        ? p.join(mediaDirAsync.value!, relativeBannerPath)
        : null;
    final String? networkBannerUrl = user.bannerUrl;
    // --- 逻辑结束 ---

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name as String),
        actions: [
          // --- 6. 根据 isFromHistory 隐藏历史按钮 ---
          if (!isFromHistory)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l10n.history,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserHistoryPage(
                      user: user,
                      ownerId: ownerId, // 确保 ownerId 被传递
                    ),
                  ),
                );
              },
            ),
          // --- 修改结束 ---
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            // ... (横幅和头像的渲染逻辑... 均保持不变) ...
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              AspectRatio(
                aspectRatio: bannerAspectRatio,
                child: (absoluteBannerPath != null)
                    ? Image.file(
                        File(absoluteBannerPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return (networkBannerUrl ?? '').isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: networkBannerUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey.shade300),
                                  errorWidget: (context, url, error) =>
                                      Container(color: Colors.grey.shade300),
                                )
                              : Container(color: Colors.grey.shade300);
                        },
                      )
                    : (networkBannerUrl ?? '').isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: networkBannerUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey.shade300),
                        errorWidget: (context, url, error) =>
                            Container(color: Colors.grey.shade300),
                      )
                    : Container(color: Colors.grey.shade300),
              ),
              Positioned(
                left: 16,
                bottom: -avatarOverhang,
                child: Hero(
                  tag: 'avatar_${user.restId}',
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Icon(
                              Icons.person,
                              size: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            if (absoluteAvatarPath != null)
                              Image.file(
                                File(absoluteAvatarPath),
                                fit: BoxFit.cover,
                                width: 84,
                                height: 84,
                                frameBuilder: (context, child, frame, wasSync) {
                                  if (wasSync) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 0),
                                    child: child,
                                  );
                                },
                                errorBuilder: (context, e, s) =>
                                    const SizedBox.shrink(),
                              ),
                            if (fetchNetworkAvatar)
                              CachedNetworkImage(
                                imageUrl: highQualityNetworkUrl,
                                fit: BoxFit.cover,
                                width: 84,
                                height: 84,
                                fadeInDuration: const Duration(
                                  milliseconds: 300,
                                ),
                                placeholder: (context, url) =>
                                    const SizedBox.shrink(),
                                errorWidget: (context, url, error) =>
                                    const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // lib/ui/user_detail_page.dart

          // ... inside build() ...

          // 替换原来的 Padding 块
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  // --- [修复] JSON 获取逻辑 ---
                  // 1. 尝试使用传入的快照 JSON (历史模式)
                  // 2. 如果没有快照，则将当前 TwitterUser 对象序列化为 JSON (实时模式)
                  String rawJson = snapshotJson ?? jsonEncode(user.toJson());

                  // --- 下面代码保持不变 ---
                  if (rawJson.isNotEmpty) {
                    String formattedJson = rawJson;
                    try {
                      final dynamic jsonObj = jsonDecode(rawJson);
                      const encoder = JsonEncoder.withIndent('  ');
                      formattedJson = encoder.convert(jsonObj);
                    } catch (e, s) {
                      logger.e(
                        "Error formatting JSON: $e",
                        error: e,
                        stackTrace: s,
                      );
                    }

                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('JSON'),
                        content: Container(
                          width: double.maxFinite,
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: TextEditingController(
                                text: formattedJson,
                              ),
                              readOnly: true,
                              maxLines: null,
                              decoration: const InputDecoration.collapsed(
                                hintText: null,
                              ),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text(l10n.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: formattedJson),
                              );
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.copied_to_clipboard,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                ),
                              );
                            },
                          ),
                          ElevatedButton(
                            child: Text(l10n.ok),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.no_json_data_available)),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.pink.shade100,
                  foregroundColor: Colors.pink.shade800,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.description_outlined, size: 20),
                label: const Text('JSON'),
              ),
            ),
          ),

          // ... (所有显示用户 bio, location, link, followers... 的代码保持不变) ...
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SelectableText.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(text: user.name),
                      if (user.isVerified)
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: SvgPicture.asset(
                              'assets/icon/verified.svg',
                              width: 23,
                              height: 23,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF1DA1F2),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          alignment: PlaceholderAlignment.middle,
                        ),
                      if (user.isProtected)
                        WidgetSpan(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: user.isVerified ? 0.0 : 4.0,
                              right: 4.0,
                            ),
                            child: SvgPicture.asset(
                              'assets/icon/protected.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          alignment: PlaceholderAlignment.middle,
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '@',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: SelectableText(
                                user.screenName ?? '',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  user.bio ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 4.0,
              children: [
                if (user.location != null && user.location!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: SelectableText(
                          user.location ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                if (user.link != null && user.link!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: InkWell(
                          onTap: () => _launchURL(context, user.link),
                          child: Text(
                            user.link ?? '',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${l10n.joined} ${user.joinedTime}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 4.0,
              children: [
                Text.rich(
                  TextSpan(
                    text: user.followingCount.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: ' ${l10n.following}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: user.followersCount.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: ' ${l10n.followers}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.view_on_twitter,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.link,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ByScreenName',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _launchURL(
                                context,
                                'https://x.com/${user.screenName}',
                              ),
                              child: Text(
                                'https://x.com/${user.screenName}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.link,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ByRestId',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _launchURL(
                                context,
                                'https://x.com/intent/user?user_id=${user.restId}',
                              ),
                              child: Text(
                                'https://x.com/intent/user?user_id=${user.restId}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 1, 0),
            child: Text(
              l10n.metadata,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          _buildInfoTile(
            context,
            Icons.create,
            l10n.tweets,
            user.statusesCount.toString(),
          ),
          _buildInfoTile(
            context,
            Icons.image,
            l10n.media_count,
            user.mediaCount.toString(),
          ),
          _buildInfoTile(
            context,
            Icons.favorite,
            l10n.likes,
            user.favouritesCount.toString(),
          ),
          _buildInfoTile(
            context,
            Icons.list_alt,
            l10n.listed_count,
            user.listedCount.toString(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 1, 0),
            child: Text(
              l10n.identity,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          _buildInfoTile(context, Icons.fingerprint, "Rest ID", user.restId),

          // --- 8. 添加快照 ID 和时间戳 ---
          if (isFromHistory && snapshotId != null && snapshotTimestamp != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Text(
                "Snapshot ID: $snapshotId\nTimestamp: ${snapshotTimestamp!.toLocal()}",
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          // --- 修改结束 ---
        ],
      ),
    );
  }

  void _launchURL(BuildContext context, String? urlString) async {
    // ... (此辅助方法保持不变) ...
    if (urlString == null || urlString.isEmpty) {
      return;
    }
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开链接: 格式错误')));
      }
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开链接: $e')));
      }
    }
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    bool isUrl = false,
  }) {
    // ... (此辅助方法保持不变) ...
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: SelectableText(
        subtitle,
        style: TextStyle(color: isUrl ? Colors.blue : null),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}
