import 'package:autonitor/utils/history_rebuild_worker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyWorkerProvider = Provider<HistoryRebuildWorker>((ref) {
  return HistoryRebuildWorker();
});
