import 'dart:math'; // 导入 math 库以使用 max 函数
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/twitter_user.dart';

class UserDetailPage extends StatelessWidget {
  final TwitterUser user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 1024x341 的宽高比
    const double bannerAspectRatio = 1024 / 341;
    // 按钮高度(MD3 TonalButton 约 40) + 按钮与横幅间距(8)
    const double buttonOverhang = 48.0;
    // 头像半径(45) - 中心点距横幅底部的偏移(5) = 40
    const double avatarOverhang = 40.0;

    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    // 计算动态的横幅高度
    final bannerHeight = screenWidth / bannerAspectRatio;
    // 计算 Stack 所需的总高度
    final stackTotalHeight = bannerHeight + max(avatarOverhang, buttonOverhang);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '查看历史',
            onPressed: () {
              // TODO: History 逻辑
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            clipBehavior: Clip.none,
            // --- 修改 1: 设置对齐方式 ---
            alignment: Alignment.topCenter,
            children: [
              AspectRatio(
                aspectRatio: bannerAspectRatio,
                child: (user.bannerUrl ?? '').isNotEmpty
                    ? Image.network(user.bannerUrl!, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade300),
              ),
              Positioned(
                left: 16,
                bottom: -avatarOverhang,
                child: Hero(
                  tag: 'avatar_${user.restId}', // 使用与列表页相同的 tag
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                ),
              ),

              // --- 修改 2: 添加透明 SizedBox 撑开 Stack 点击区域 ---
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 16.0,
              top: 8.0,
            ), // top可调按钮垂直间距
            child: Align(
              alignment: Alignment.centerRight, // 靠右对齐
              child: FilledButton.tonalIcon(
                onPressed: () {
                  /* TODO: JSON 逻辑 */
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.pink.shade100,
                  foregroundColor: Colors.pink.shade800,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ), // 控制按钮大小
                ),
                icon: const Icon(Icons.description_outlined, size: 20),
                label: const Text('JSON'),
              ),
            ),
          ),

          // --- 修改 3: 移除之前多余的 SizedBox ---
          const SizedBox(height: 5),

          // --- 新增: 根据最大悬垂物添加必要的间距 ---
          // SizedBox(height: max(avatarOverhang, buttonOverhang) + 8), // 确保内容总是在头像/按钮下方（已减半间距）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '@',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: SelectableText(
                          user.id,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
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
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: SelectableText(
                          user.location ?? '',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                if (user.link != null && user.link!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: InkWell(
                          onTap: () => _launchURL(context, user.link),
                          child: Text(
                            user.link ?? '',
                            style: TextStyle(
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
                    Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${l10n.joined} ${user.joinTime ?? ''}',
                        style: TextStyle(color: Colors.grey),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: ' ${l10n.following}',
                        style: TextStyle(
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: ' ${l10n.followers}',
                        style: TextStyle(
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
          // —— View on Twitter（两列、标签水平对齐、图标非灰色、链接最多两行） —— //
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.view_on_twitter,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐，保证两个标签水平对齐
              children: [
                // 第一列：ByScreenName
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.link,
                        color: Theme.of(context).colorScheme.primary, // 非灰色
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ByScreenName',
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _launchURL(
                                context,
                                'https://x.com/${user.id}',
                              ),
                              child: Text(
                                'https://x.com/${user.id}',
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

                // 第二列：ByRestId
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
                            Text(
                              'ByRestId',
                              style: TextStyle(
                                fontSize: 12,
                              ),
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

          // —— 原有 Metadata 与指标 —— //
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 1, 0),
            child: Text(
              l10n.metadata,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          _buildInfoTile(context, Icons.create, l10n.tweets, "65"),
          _buildInfoTile(context, Icons.image, l10n.media_count, "3"),
          _buildInfoTile(context, Icons.favorite, l10n.likes, "100"),
          _buildInfoTile(context, Icons.list_alt, l10n.listed_count, "1"),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 1, 0),
            child: Text(
              l10n.identity,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          _buildInfoTile(context, Icons.fingerprint, "Rest ID", user.restId),
        ],
      ),
    );
  }

  void _launchURL(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      return;
    }
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法打开链接: 格式错误')));
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
