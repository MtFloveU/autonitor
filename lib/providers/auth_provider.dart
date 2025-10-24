import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/secure_storage_service.dart';
import '../services/twitter_api_service.dart';

// [已更新]
// 核心改动：
// 1. 将 `activeAccountProvider` 升级为 StateNotifierProvider。
// 2. `ActiveAccountNotifier` 现在 "监听" `accountsProvider` 的变化，并自动处理活动账号被删除的情况。
// 3. 移除了 `AccountsNotifier` 中的循环依赖。

// --- Provider定义 ---

// accountsProvider 保持不变
final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>((ref) {
  return AccountsNotifier(ref);
});

// --- 新的 ActiveAccountNotifier ---
class ActiveAccountNotifier extends StateNotifier<Account?> {
  final Ref _ref;
  ActiveAccountNotifier(this._ref) : super(null) {
    // 立即尝试设置初始状态
    _initialize();
  }

  // 1. 初始化时，从账号列表中加载第一个
  void _initialize() {
    final accounts = _ref.read(accountsProvider);
    state = accounts.isNotEmpty ? accounts.first : null;
  }

  // 2. 提供一个公共方法来设置活动账号
  void setActive(Account? account) {
    state = account;
  }

  // 3. 关键逻辑：当账号列表更新时，检查当前活动账号是否被删除
  void updateFromList(List<Account> newList) {
    if (state == null) {
      // 如果之前没有活动账号，则设为新列表的第一个
      state = newList.isNotEmpty ? newList.first : null;
    } else {
      // 如果之前有活动账号，检查它是否还在新列表中
      final bool stillExists = newList.any((acc) => acc.id == state!.id);
      if (!stillExists) {
        // 它被删除了！将活动账号重置为新列表的第一个
        state = newList.isNotEmpty ? newList.first : null;
      }
      // 如果它仍然存在，我们什么都不做，保持它被选中
    }
  }
}

// --- 将 activeAccountProvider 升级为 StateNotifierProvider ---
final activeAccountProvider = StateNotifierProvider<ActiveAccountNotifier, Account?>((ref) {
  final notifier = ActiveAccountNotifier(ref);

  // *** 关键 ***
  // "监听" accountsProvider。当列表变化时，
  // 自动调用我们的 updateFromList 方法。
  ref.listen(accountsProvider, (previousList, newList) {
    notifier.updateFromList(newList);
  });
  
  return notifier;
});


// --- State Notifier ---

class AccountsNotifier extends StateNotifier<List<Account>> {
  final Ref _ref;
  late final SecureStorageService _storageService;
  late final TwitterApiService _apiService;

  AccountsNotifier(this._ref) : super([]) {
    _storageService = _ref.read(secureStorageServiceProvider);
    _apiService = _ref.read(twitterApiServiceProvider);
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    state = await _storageService.getAccounts();
  }

  Future<void> addAccount(String cookie) async {
    final profile = await _apiService.getUserProfile(cookie);
    if (profile == null) {
      throw Exception("提供的Cookie无效或已过期。");
    }

    final twid = _parseTwidFromCookie(cookie);
    if (twid == null) {
      throw Exception('无法从Cookie中解析出twid');
    }

    final newAccount = Account(id: twid, cookie: cookie);

    final exists = state.any((acc) => acc.id == newAccount.id);
    if (exists) {
      state = [
        for (final acc in state)
          if (acc.id == newAccount.id) newAccount else acc,
      ];
    } else {
      state = [...state, newAccount];
    }

    await _storageService.saveAccounts(state);
    
    // --- 修改：使用 .setActive() 方法 ---
    _ref.read(activeAccountProvider.notifier).setActive(newAccount);
  }

  // --- 修改：移除 removeAccount 中的循环依赖 ---
  Future<void> removeAccount(String id) async {
    // 1. (移除) final currentActive = _ref.read(activeAccountProvider);

    // 2. 创建新列表
    final newList = state.where((acc) => acc.id != id).toList();
    
    // 3. 更新自己的状态
    state = newList;

    // 4. 保存到存储
    await _storageService.saveAccounts(state);

    // 5. (移除) if (currentActive?.id == id) { ... }
    //    (activeAccountProvider 的 .listen() 会自动处理这个)
  }

  String? _parseTwidFromCookie(String cookie) {
    try {
      final parts = cookie.split(';');
      final twidPart = parts.firstWhere(
        (part) => part.trim().startsWith('twid='),
      );
      final valuePart = twidPart.split('=')[1];
      final decodedValue = Uri.decodeComponent(valuePart);
      final id = decodedValue.split('=')[1];
      return id;
    } catch (e) {
      return null;
    }
  }
}
