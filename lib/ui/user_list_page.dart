import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/ui/user_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart'; // <-- 修正：导入 auth_provider.dart
import '../l10n/app_localizations.dart';
import '../models/twitter_user.dart';

class UserListPage extends ConsumerWidget {
  final String ownerId;
  final String categoryKey;

  const UserListPage({
    super.key,
    required this.ownerId,
    required this.categoryKey,
  });

  // Helper function to get localized title
  String getLocalizedTitle(AppLocalizations l10n) {
    switch (categoryKey) {
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
        return categoryKey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // --- 修正：使用 userListProvider ---
    final userListAsync = ref.watch(
      userListProvider(
        UserListParam(ownerId: ownerId, categoryKey: categoryKey),
      ),
    );
    // --- 修正结束 ---

    return Scaffold(
      appBar: AppBar(title: Text(getLocalizedTitle(l10n))),
      body: userListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('${l10n.failed_to_load_user_list}: $err')),
        data: (users) {
          if (users.isEmpty) {
            return Center(child: Text(l10n.no_users_in_this_category));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: Hero(
                  tag: 'avatar_${user.restId}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.person, size: 24),
                        if (user.avatarUrl.isNotEmpty)
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user.avatarUrl,
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              placeholder: (context, url) => const SizedBox(),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(),
                            ),
                          ),
                      ],
                    ),
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
    );
  }
}
