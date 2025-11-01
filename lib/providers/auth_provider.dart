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

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>(
  (ref) {
    return AccountsNotifier(ref);
  },
);

class ActiveAccountNotifier extends StateNotifier<Account?> {
  final Ref _ref;
  late final SecureStorageService _storageService;
  bool _isInitialized = false;

  ActiveAccountNotifier(this._ref) : super(null) {
    _storageService = _ref.read(secureStorageServiceProvider);
  }

  void initializeState(List<Account> accounts, String? activeId) {
    if (_isInitialized || state != null) {
      logger.i("ActiveAccountNotifier: Initialization skipped.");
      return;
    }
    logger.i(
      "ActiveAccountNotifier: Initializing state with ${accounts.length} accounts and activeId: $activeId",
    );
    if (activeId != null && accounts.isNotEmpty) {
      try {
        final initialAccount = accounts.firstWhere((acc) => acc.id == activeId);
        state = initialAccount;
        logger.i(
          "ActiveAccountNotifier: Initial state set to ID ${state?.id} from storage.",
        );
        _isInitialized = true;
      } catch (e) {
        logger.w(
          "ActiveAccountNotifier: Stored active ID $activeId not found. Resetting.",
        );
        _resetActiveAccountAndMarkInitialized(accounts);
      }
    } else if (accounts.isNotEmpty) {
      logger.i(
        "ActiveAccountNotifier: No active ID stored. Setting first account.",
      );
      _resetActiveAccountAndMarkInitialized(accounts);
    } else {
      logger.i("ActiveAccountNotifier: No accounts loaded. State remains null.");
      state = null;
      _isInitialized = true;
    }
  }

  Future<void> _resetActiveAccountAndMarkInitialized(
    List<Account> accounts,
  ) async {
    await _resetActiveAccount(accounts);
    _isInitialized = true;
    logger.i("ActiveAccountNotifier: Initialization completed after reset.");
  }

  Future<void> _resetActiveAccount(List<Account> accounts) async {
    if (accounts.isNotEmpty) {
      state = accounts.first;
      await _storageService.saveActiveAccountId(state!.id);
      logger.i(
        "ActiveAccountNotifier: Reset active account to first ID ${state?.id}.",
      );
    } else {
      state = null;
      await _storageService.deleteActiveAccountId();
      logger.i("ActiveAccountNotifier: Reset called but no accounts available.");
    }
  }

  Future<void> setActive(Account? account) async {
    state = account;
    if (account != null) {
      await _storageService.saveActiveAccountId(account.id);
      logger.i(
        "ActiveAccountNotifier: Set active account ID: ${account.id} and persisted.",
      );
    } else {
      await _storageService.deleteActiveAccountId();
      logger.i("ActiveAccountNotifier: Cleared active account ID and persisted.");
    }
  }

  Future<void> updateFromList(List<Account> newList) async {
    logger.i(
      "ActiveAccountNotifier: (Post-init) Account list updated. Current active ID: ${state?.id}. New list size: ${newList.length}",
    );
    if (state != null) {
      final bool stillExists = newList.any((acc) => acc.id == state!.id);
      if (!stillExists) {
        logger.i(
          "ActiveAccountNotifier: (Post-init) Active account ${state!.id} removed. Resetting.",
        );
        await _resetActiveAccount(newList);
      } else {
        final updatedAccountInstance = newList.firstWhere(
          (acc) => acc.id == state!.id,
        );
        if (state != updatedAccountInstance) {
          state = updatedAccountInstance;
          logger.i(
            "ActiveAccountNotifier: (Post-init) Updated active account instance for ID ${state!.id}.",
          );
        }
      }
    } else if (newList.isNotEmpty) {
      logger.i(
        "ActiveAccountNotifier: (Post-init) State was null, setting first account.",
      );
      await _resetActiveAccount(newList);
    }
  }

  bool get isInitialized => _isInitialized;
}

final activeAccountProvider =
    StateNotifierProvider<ActiveAccountNotifier, Account?>((ref) {
      final notifier = ActiveAccountNotifier(ref);
      ref.listen(accountsProvider, (previousList, newList) {
        if (notifier.isInitialized) {
          logger.i(
            "ActiveAccountNotifier Listen: Initialized, calling updateFromList.",
          );
          notifier.updateFromList(newList);
        } else {
          logger.i(
            "ActiveAccountNotifier Listen: Not initialized yet, skipping updateFromList.",
          );
        }
      });
      return notifier;
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
    } catch (e, s) {
      logger.e("AccountsNotifier: Error loading accounts from repository: $e\n$s");
    }

    state = loadedAccounts;
    logger.i("AccountsNotifier: Loaded and assembled ${state.length} accounts.");

    _ref
        .read(activeAccountProvider.notifier)
        .initializeState(loadedAccounts, storedActiveId);
  }

  Future<void> addAccount(String cookie) async {
    try {
      await _accountRepository.addAccount(cookie);
      await loadAccounts();
    } catch (e) {
      logger.e("AccountsNotifier: Error adding account: $e");
      rethrow;
    }
  }

  Future<void> removeAccount(String id) async {
    try {
      await _accountRepository.removeAccount(id);
      await loadAccounts();
    } catch (e) {
      logger.e("AccountsNotifier: Error removing account: $e");
      rethrow;
    }
  }

  Future<List<RefreshResult>> refreshAllAccountProfiles(
    List<Account> accounts,
  ) async {
    final semaphore = Semaphore(5);
    final group = FutureGroup<RefreshResult>();
    logger.i(
      "AccountsNotifier: Starting refresh for ${accounts.length} accounts with concurrency limit 5...",
    );
    for (final account in accounts) {
      group.add(
        Future(() async {
          await semaphore.acquire();
          try {
            logger.i("AccountsNotifier: Refreshing profile for ${account.id}...");
            await _refreshSingleAccountProfile(account);
            logger.i("AccountsNotifier: Refresh successful for ${account.id}.");
            return RefreshResult(accountId: account.id, success: true);
          } catch (e) {
            logger.e("AccountsNotifier: Refresh failed for ${account.id}: $e");
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
    final results = await group.future;
    logger.i("AccountsNotifier: Refresh process completed.");
    return results;
  }

  Future<void> _refreshSingleAccountProfile(Account account) async {
    try {
      await _accountRepository.refreshAccountProfile(account);
    } catch (e) {
      logger.e("AccountsNotifier: _refreshSingleAccountProfile failed.");
      rethrow;
    }
  }
}
