import 'package:autonitor/services/log_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/x_client_transaction_service.dart';

// 提供 XClientGenerator 实例
final xClientGeneratorProvider = Provider<XClientGenerator>((ref) {

  return XClientGenerator();
});

final xctServiceProvider =
    FutureProvider.autoDispose<XClientTransactionService>((ref) {
      final generator = ref.watch(xClientGeneratorProvider);
      return generator.fetchService();
    });

// AsyncNotifier 管理 ID 状态，并且 generateId 会返回生成的 ID（String）
class TransactionIdNotifier extends AutoDisposeNotifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    return const AsyncData(null);
  }

  /// 生成一个 ID，并返回该 ID（避免 UI 通过 ref.read 竞态读取）
  Future<String?> generateId({
    required String method,
    required String url,
  }) async {
    state = const AsyncLoading();

    final generator = ref.read(xClientGeneratorProvider);

    try {
      final id = await generator.fetchAndGenerateTransactionId(
        method: method,
        url: url,
      );

      state = AsyncData(id);
      logger.i('[XCT-Generator] Generated id: $id');
      return id;
    } catch (e, s) {
      state = AsyncError("Failed to generate ID: $e", s);
      rethrow;
    }
  }
}

// Provider 本体
final transactionIdProvider =
    AutoDisposeNotifierProvider<TransactionIdNotifier, AsyncValue<String?>>(
      TransactionIdNotifier.new,
    );
