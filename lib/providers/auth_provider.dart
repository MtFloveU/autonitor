import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/secure_storage_service.dart';
import '../repositories/account_repository.dart';
import 'package:async/async.dart';
import 'package:async_locks/async_locks.dart';
import 'package:autonitor/services/log_service.dart';

class RefreshResult {
  final String accountId;
  final bool success;
  final String? error;
  RefreshResult({required this.accountId, required this.success, this.error});
}

class ActiveAccountState {
  final Account? account;
  final bool isInitialized;

  const ActiveAccountState({this.account, this.isInitialized = false});

  ActiveAccountState copyWith({
    Account? account,
    bool? isInitialized,
    bool clearAccount = false,
  }) {
    return ActiveAccountState(
      account: clearAccount ? null : (account ?? this.account),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>(
  (ref) {
    return AccountsNotifier(ref);
  },
);

class ActiveAccountNotifier extends StateNotifier<ActiveAccountState> {
  final Ref _ref;
  late final SecureStorageService _storageService;

  ActiveAccountNotifier(this._ref) : super(const ActiveAccountState()) {
    _storageService = _ref.read(secureStorageServiceProvider);
  }

  /// 初始化状态：当 accounts 加载完成后被调用
  void initializeState(List<Account> accounts, String? activeId) {
    if (state.isInitialized) {
      logger.i("ActiveAccountNotifier: Already initialized.");
      return;
    }

    logger.i(
      "ActiveAccountNotifier: Initializing with ${accounts.length} accounts and activeId: $activeId",
    );

    if (activeId != null && accounts.isNotEmpty) {
      try {
        final initialAccount = accounts.firstWhere((acc) => acc.id == activeId);
        state = state.copyWith(account: initialAccount, isInitialized: true);
      } catch (e) {
        logger.w(
          "ActiveAccountNotifier: Stored active ID not found. Resetting.",
        );
        _resetToFirst(accounts);
      }
    } else if (accounts.isNotEmpty) {
      _resetToFirst(accounts);
    } else {
      // 关键点：即使没有账户，也要标记为已初始化，这会触发 UI 刷新
      state = state.copyWith(clearAccount: true, isInitialized: true);
    }
  }

  void _resetToFirst(List<Account> accounts) {
    final first = accounts.isNotEmpty ? accounts.first : null;
    state = state.copyWith(account: first, isInitialized: true);
    if (first != null) {
      _storageService.saveActiveAccountId(first.id);
    }
  }

  Future<void> setActive(Account? account) async {
    state = state.copyWith(account: account, isInitialized: true);
    if (account != null) {
      await _storageService.saveActiveAccountId(account.id);
    } else {
      await _storageService.deleteActiveAccountId();
    }
  }

  /// 当账号列表发生变化（如删除账号）时同步更新
  void updateFromList(List<Account> newList) {
    if (!state.isInitialized) return;

    final currentAccount = state.account;
    if (currentAccount != null) {
      final exists = newList.any((acc) => acc.id == currentAccount.id);
      if (!exists) {
        _resetToFirst(newList);
      } else {
        // 更新账户实例以保持数据同步
        final updated = newList.firstWhere(
          (acc) => acc.id == currentAccount.id,
        );
        if (updated != currentAccount) {
          state = state.copyWith(account: updated);
        }
      }
    } else if (newList.isNotEmpty) {
      _resetToFirst(newList);
    }
  }
}

/// 核心状态 Provider
final activeAccountStateProvider =
    StateNotifierProvider<ActiveAccountNotifier, ActiveAccountState>((ref) {
      final notifier = ActiveAccountNotifier(ref);
      // 监听账号列表变化
      ref.listen(accountsProvider, (prev, next) {
        notifier.updateFromList(next);
      });
      return notifier;
    });

/// 兼容层：保持 activeAccountProvider 返回 Account?
/// 这样你的 home_widgets.dart 和其他地方不需要大规模改动
final activeAccountProvider = Provider<Account?>((ref) {
  return ref.watch(activeAccountStateProvider).account;
});

class AccountsNotifier extends StateNotifier<List<Account>> {
  final Ref _ref;
  late final SecureStorageService _storageService;
  late final AccountRepository _accountRepository;

  AccountsNotifier(this._ref) : super([]) {
    _storageService = _ref.read(secureStorageServiceProvider);
    _accountRepository = _ref.read(accountRepositoryProvider);
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    List<Account> loadedAccounts = [];
    String? storedActiveId;

    try {
      loadedAccounts = await _accountRepository.getAllAccounts();
      storedActiveId = await _storageService.readActiveAccountId();
    } catch (e) {
      logger.e("AccountsNotifier: Error loading accounts: $e");
    }

    state = loadedAccounts;

    // 调用初始化逻辑
    _ref
        .read(activeAccountStateProvider.notifier)
        .initializeState(loadedAccounts, storedActiveId);
  }

  Future<void> addAccount(String cookie) async {
    try {
      await _accountRepository.addAccount(cookie);
      await loadAccounts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeAccount(String id) async {
    try {
      await _accountRepository.removeAccount(id);
      await loadAccounts();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RefreshResult>> refreshAllAccountProfiles(
    List<Account> accounts,
  ) async {
    final semaphore = Semaphore(5);
    final group = FutureGroup<RefreshResult>();
    for (final account in accounts) {
      group.add(
        Future(() async {
          await semaphore.acquire();
          try {
            await _accountRepository.refreshAccountProfile(account);
            return RefreshResult(accountId: account.id, success: true);
          } catch (e) {
            return RefreshResult(
              accountId: account.id,
              success: false,
              error: e.toString(),
            );
          } finally {
            semaphore.release();
          }
        }),
      );
    }
    group.close();
    return await group.future;
  }
}
