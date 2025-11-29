import 'package:autonitor/models/twitter_user.dart';
import 'package:autonitor/services/database.dart';

/// 1. 定义一个 Model 来封装列表项所需的数据
class HistorySnapshot {
  // 包含 ID 和 时间戳 的数据库原始条目
  final FollowUserHistoryEntry entry;
  // 重建后的、用于在列表项中显示的 TwitterUser 对象
  final TwitterUser user;
  // 重建后的、用于传递给详情页的 完整JSON字符串
  final String fullJson;

  HistorySnapshot({
    required this.entry,
    required this.user,
    required this.fullJson,
  });
}
