import 'package:flutter/material.dart';
import '../models/twitter_user.dart';
import 'user_detail_page.dart'; // [新增] 导入新的详情页

/// [已更新]
/// 核心改动：
/// 1. 为每个 `ListTile` 添加了 `onTap` 事件。
/// 2. 点击列表项后，会使用 `Navigator.push` 导航到新的 `UserDetailPage`。
/// 3. 在导航时，会将当前点击的 `TwitterUser` 对象传递给详情页。
class UserListPage extends StatelessWidget {
  final String title;
  final List<TwitterUser> users;

  const UserListPage({super.key, required this.title, required this.users});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              child: user.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(user.name),
            subtitle: Text(user.id),
            trailing: const Icon(Icons.chevron_right),
            // [已更新] 添加点击事件
            onTap: () {
              // 导航到用户详情页
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailPage(user: user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

