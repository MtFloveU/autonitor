// lib/providers/json_worker_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/json_parse_worker.dart';

final jsonParseWorkerProvider = Provider.autoDispose<JsonParseWorker>((ref) {
  final worker = JsonParseWorker.instance;

  ref.onDispose(() {
    worker.dispose();
  });

  return worker;
});
