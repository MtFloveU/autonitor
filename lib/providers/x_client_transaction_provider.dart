import 'package:autonitor/services/log_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/x_client_transaction_service.dart';

// 提供 XClientGenerator 实例
final xClientGeneratorProvider = Provider<XClientGenerator>((ref) {
  return XClientGenerator();
});

// --- MODIFICATION: Restore xctServiceProvider as a FutureProvider ---
// This provider now fetches the service *once* and caches it.
final xctServiceProvider = FutureProvider<XClientTransactionService>((
  ref,
) async {
  final generator = ref.read(xClientGeneratorProvider);
  logger.i(
    "[xctServiceProvider] Fetching new XClientTransactionService instance...",
  );
  return await generator.fetchService();
});
// --- END MODIFICATION ---

// --- MODIFICATION: Changed to Notifier and NotifierProvider ---
class TransactionIdNotifier extends Notifier<AsyncValue<String?>> {
  XClientTransactionService? _service;

  @override
  AsyncValue<String?> build() {
    return const AsyncData(null);
  }

  /// 初始化，只执行一次
  Future<void> init() async {
    if (_service != null) return; // 已经初始化，不重复
    state = const AsyncLoading();

    try {
      // --- MODIFICATION: Read from the new FutureProvider ---
      logger.i("[TransactionIdNotifier] init() awaiting xctServiceProvider...");
      _service = await ref.read(
        xctServiceProvider.future,
      ); // Awaits the cached service
      logger.i("[TransactionIdNotifier] init() successfully got service.");

      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError("Failed to init XClient: $e", s);
      rethrow; // This rethrow is CRITICAL
    }
  }

  /// 按需生成 ID (必须先调用 init())
  Future<String?> generate({
    required String method,
    required String url,
  }) async {
    if (_service == null) {
      // This should not happen if init() is called correctly in DataProcessor.
      final errorMsg =
          "TransactionIdNotifier.init() must be called before generate().";
      logger.e(errorMsg);
      state = AsyncError(errorMsg, StackTrace.current);
      throw StateError(errorMsg);
    }

    try {
      // generateTransactionId from the service is synchronous.
      final id = _service!.generateTransactionId(method: method, url: url);
      state = AsyncData(id);

      logger.i('[XCT] Generated id: $id');
      return id; // The async keyword will wrap this in a Future.
    } catch (e, s) {
      final errorMsg = "Failed to generate ID: $e";
      state = AsyncError(errorMsg, s);
      logger.e(errorMsg, error: e, stackTrace: s);
      rethrow;
    }
  }
}

// --- MODIFICATION: Changed to NotifierProvider (non-autoDispose) ---
final transactionIdProvider =
    NotifierProvider<TransactionIdNotifier, AsyncValue<String?>>(
      TransactionIdNotifier.new,
    );
