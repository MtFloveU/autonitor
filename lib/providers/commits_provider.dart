import 'dart:async';
import 'package:autonitor/main.dart';
import 'package:autonitor/services/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 使用 FamilyStreamNotifier 处理带参数 (activeAccountId) 的流
class SyncLogsNotifier
    extends FamilyStreamNotifier<List<SyncLogsEntry>, String> {
  @override
  Stream<List<SyncLogsEntry>> build(String arg) {
    // arg 即为传入的 activeAccountId
    // 自动监听数据库 provider，当数据库实例变化时流会自动重建
    return ref.watch(databaseProvider).watchSyncLogs(arg);
  }

  /// 封装回滚业务逻辑，UI 不再直接接触 DB 接口
  Future<void> rollback(String runId) async {
    final db = ref.read(databaseProvider);
    await db.rollbackToRun(
      ownerId: arg,
      targetRunId: runId,
    );
  }
}

/// 全局 Provider 定义
final syncLogsProvider =
    StreamNotifierProvider.family<
      SyncLogsNotifier,
      List<SyncLogsEntry>,
      String
    >(() => SyncLogsNotifier());
