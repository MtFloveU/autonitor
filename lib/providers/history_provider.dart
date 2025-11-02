import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autonitor/models/history_snapshot.dart';
import 'package:autonitor/providers/settings_provider.dart';
import 'package:autonitor/repositories/history_repository.dart'; // <-- 1. 导入 Repository

/// 1. 定义 Provider 的参数 (FamilyProvider 仍需要它)
@immutable
class ProfileHistoryParams {
  final String ownerId;
  final String userId;

  const ProfileHistoryParams({required this.ownerId, required this.userId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileHistoryParams &&
          runtimeType == other.runtimeType &&
          ownerId == other.ownerId &&
          userId == other.userId;

  @override
  int get hashCode => ownerId.hashCode ^ userId.hashCode;
}

/// 2. 创建 History Provider (现在它非常简单)
final profileHistoryProvider = AsyncNotifierProvider.family<
    ProfileHistoryNotifier,
    List<HistorySnapshot>,
    ProfileHistoryParams>(() {
  return ProfileHistoryNotifier();
});

class ProfileHistoryNotifier extends FamilyAsyncNotifier<List<HistorySnapshot>, ProfileHistoryParams> {
  
  @override
  Future<List<HistorySnapshot>> build(ProfileHistoryParams arg) async {
    // 3. Provider 的职责：
    
    // a. 监听它依赖的 Provider (设置)
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return []; // 如果设置未加载，不执行
    }

    // b. 获取它需要的 Repository
    final repository = ref.read(historyRepositoryProvider);

    // c. 调用 Repository 的方法并返回结果
    return repository.getFilteredHistory(
      arg.ownerId,
      arg.userId,
      settings,
    );
  }
}