import 'package:flutter/material.dart';
import '../models/twitter_user.dart';

/// [新增] 这是一个新的UI页面，用于显示单个用户的详细信息。
class UserDetailPage extends StatelessWidget {
  final TwitterUser user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 顶部头像和名称
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                child: user.avatarUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
                    Text(user.id, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48),

          // 详细信息列表
          _buildInfoTile(context, Icons.fingerprint, "REST ID", user.restId),
          _buildInfoTile(context, Icons.info_outline, "Avatar URL", user.avatarUrl, isUrl: true),
        ],
      ),
    );
  }

  // 辅助函数，用于构建信息列表项
  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle, {bool isUrl = false}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: SelectableText( // 使用 SelectableText 方便用户复制信息
        subtitle,
        style: TextStyle(color: isUrl ? Colors.blue : null),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }
}
