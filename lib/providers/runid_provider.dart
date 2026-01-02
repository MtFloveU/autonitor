import 'package:autonitor/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database.dart';
import '../utils/runid_generator.dart';

final runIdProvider = Provider<RunIdService>((ref) {
  final db = ref.watch(databaseProvider);
  return RunIdService(db);
});

class RunIdService {
  final AppDatabase _db;

  RunIdService(this._db);

  Future<String> generateUniqueRunId() async {
    String runId = '';
    bool isUnique = false;

    while (!isUnique) {
      runId = generateRunId();

      // 检查 SyncLogs 表
      final existingLog =
          await (_db.select(_db.syncLogs)
                ..where((t) => t.runId.equals(runId))
                ..limit(1))
              .getSingleOrNull();

      if (existingLog == null) {
        isUnique = true;
      }
    }

    return runId;
  }
}
