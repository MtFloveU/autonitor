import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/twitter_user.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'user_history_page.dart';

class UserDetailPage extends StatelessWidget {
  final TwitterUser user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const double bannerAspectRatio = 1500 / 500;
    const double avatarOverhang = 40.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.history,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserHistoryPage(user: user),
                ),
              );
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
                    ? CachedNetworkImage(
                        imageUrl: user.bannerUrl!,
                        fit: BoxFit.cover,
                        // 添加一个占位符，保持灰色背景
                        placeholder: (context, url) =>
                            Container(color: Colors.grey.shade300),
                        // 加载失败时也显示灰色背景
                        errorWidget: (context, url, error) =>
                            Container(color: Colors.grey.shade300),
                      )
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
                          ? CachedNetworkImageProvider(user.avatarUrl)
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
                  final rawJson = user.latestRawJson;
                  if (rawJson != null && rawJson.isNotEmpty) {
                    String formattedJson = rawJson; // 默认值
                    try {
                      // 尝试解码并重新编码以格式化
                      final dynamic jsonObj = jsonDecode(rawJson);
                      const encoder = JsonEncoder.withIndent('  '); // 2空格缩进
                      formattedJson = encoder.convert(jsonObj);
                    } catch (e) {
                      // 如果解码失败（理论上不应发生），则保持原始字符串
                      print("Error formatting JSON for display: $e");
                    }

                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        // 使用硬编码标题或 l10n.json_title (如果添加了)
                        title: const Text('JSON'),
                        content: Container(
                          // 使用 Container 设置最大高度和背景色
                          width: double.maxFinite, // 尽可能宽
                          // 设置一个最大高度，防止 JSON 过长导致对话框无限高
                          // MediaQuery.of(context).size.height * 0.6 表示屏幕高度的 60%
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          decoration: BoxDecoration(
                            // 使用 M3 风格的容器背景色
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8.0), // 圆角
                          ),
                          child: SingleChildScrollView(
                            // 仍然需要滚动
                            padding: const EdgeInsets.all(
                              8.0,
                            ), // TextField 周围的内边距
                            child: TextField(
                              controller: TextEditingController(
                                text: formattedJson,
                              ), // 设置文本
                              readOnly: true, // 只读，不可编辑
                              maxLines: null, // 自动换行，显示所有内容
                              decoration: InputDecoration.collapsed(
                                // 移除边框和下划线
                                hintText: null, // 不需要提示文本
                              ),
                              style: TextStyle(
                                fontFamily: 'monospace', // 等宽字体
                                fontSize: 12,
                                // 使用 M3 风格的文本颜色
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          // 复制按钮
                          TextButton(
                            child: Text(l10n.copy), // 使用 l10n.copy
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: formattedJson),
                              );
                              // 可选：显示一个 SnackBar 提示复制成功
                              Navigator.pop(dialogContext); // 关闭对话框
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
                          // 确定按钮
                          ElevatedButton(
                            child: Text(l10n.ok), // 使用 l10n.ok
                            onPressed: () {
                              Navigator.pop(dialogContext); // 只关闭对话框
                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    // 如果没有 JSON 数据，可以显示一个提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.no_json_data_available),
                      ), // 使用 l10n.no_json_data_available
                    );
                  }
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
                        '${l10n.joined} ${user.joinTime}',
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
                              style: TextStyle(fontSize: 12),
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
                            Text('ByRestId', style: TextStyle(fontSize: 12)),
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
