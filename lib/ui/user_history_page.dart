import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/providers/media_provider.dart';
import 'package:autonitor/providers/history_provider.dart';
import 'package:autonitor/ui/user_detail_page.dart';
import '../models/twitter_user.dart';
import '../l10n/app_localizations.dart';
import 'user_list_page.dart';

// 1. 改为 ConsumerStatefulWidget
class UserHistoryPage extends ConsumerStatefulWidget {
  final TwitterUser user;
  final String ownerId;

  const UserHistoryPage({super.key, required this.user, required this.ownerId});

  @override
  ConsumerState<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends ConsumerState<UserHistoryPage> {
  // 2. 添加状态变量
  bool _routeAnimationCompleted = false;

  // 3. 添加初始化逻辑监听路由动画
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      final animation = route?.animation;

      if (animation == null || animation.status == AnimationStatus.completed) {
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
    if (mounted) {
      setState(() {
        _routeAnimationCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = widget.user.restId; // 注意这里用 widget.user

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.user_history_page_title),
            const SizedBox(height: 2),
            Text(
              '@${widget.user.screenName}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      // 4. 使用 Builder 来包含逻辑
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: Builder(
            builder: (context) {
              // 定义统一的 Loading 组件
              const loadingWidget = Center(child: CircularProgressIndicator());

              // 5. 阻断逻辑：动画未完成时，直接返回 Loading，不 Watch Provider
              if (!_routeAnimationCompleted) {
                return loadingWidget;
              }

              // 6. 动画完成，开始 Watch Provider (触发后台 Worker 计算)
              final params = ProfileHistoryParams(
                ownerId: widget.ownerId,
                userId: userId,
              );
              final historyAsync = ref.watch(profileHistoryProvider(params));
              final mediaDirAsync = ref.watch(appSupportDirProvider);

              return historyAsync.when(
                // 加载中：继续显示同一个 Loading 组件，无缝衔接
                loading: () => loadingWidget,

                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('${l10n.failed_to_load_user_list}:\n$err'),
                  ),
                ),
                data: (snapshots) {
                  if (snapshots.isEmpty) {
                    return Center(child: Text(l10n.no_users_in_this_category));
                  }

                  return ListView.builder(
                    itemCount: snapshots.length,
                    itemBuilder: (context, index) {
                      final snapshot = snapshots[index];
                      final snapshotUser = snapshot.user;

                      // 2. 只需要获取 mediaDir (UserListTile 内部会处理路径计算)
                      final mediaDir = mediaDirAsync.value;
                      final String uniqueHeroTag =
                          'avatar_${snapshotUser.restId}_${snapshot.entry.id}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 3. 保留顶部的 ID 和时间戳 Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              "ID: ${snapshot.entry.id}  (${snapshot.entry.timestamp.toLocal().toString().substring(0, 16)})",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // 4. 使用 UserListTile 替换原有的手动 ListTile
                          UserListTile(
                            user: snapshotUser,
                            mediaDir: mediaDir,
                            followingLabel: l10n.following,
                            isFollower: snapshotUser.isFollower,

                            // [关键] 传入唯一的 Hero Tag，结合 User ID 和 快照 ID
                            customHeroTag: uniqueHeroTag,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserDetailPage(
                                    user: snapshotUser,
                                    ownerId: widget.ownerId,
                                    isFromHistory: true,
                                    snapshotJson: snapshot.fullJson,
                                    snapshotId: snapshot.entry.id,
                                    snapshotTimestamp: snapshot.entry.timestamp,
                                    heroTag: uniqueHeroTag,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
