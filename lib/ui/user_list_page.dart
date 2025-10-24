import 'package:autonitor/ui/home_page.dart'; // 导入 home_page.dart (如果 Provider 在那里)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 添加 riverpod 导入
import '../models/twitter_user.dart';
import '../l10n/app_localizations.dart';
import 'user_detail_page.dart';
// import '../providers/user_list_provider.dart'; // 如果单独创建了文件

// --- 修改：改为 ConsumerWidget ---
class UserListPage extends ConsumerWidget {
  final String title;
  // --- 修改：移除 users 参数 ---
  // final List<TwitterUser> users;

  // --- 修改：构造函数只接收 title ---
  const UserListPage({super.key, required this.title});

  @override
  // --- 修改：添加 WidgetRef ref ---
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // --- 修改：监听 Provider 状态 ---
    final userListAsyncValue = ref.watch(userListProvider(title));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      // --- 修改：使用 AsyncValue.when 处理状态 ---
      body: userListAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('$error'),
          ),
        ),
        data: (users) {
          // 注意这里的 users 是从 data 中获取的
          if (users.isEmpty) {
            return Center(child: Text(l10n.empty_list_message));
          }
          // 列表有数据时，显示 ListView.builder
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: Hero(
                  tag: 'avatar_${user.restId}',
                  child: CircleAvatar(
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? NetworkImage(user.avatarUrl)
                        : null,
                    child: user.avatarUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                title: Text(user.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("@${user.id}"),
                    Text(
                      user.bio ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailPage(user: user),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
