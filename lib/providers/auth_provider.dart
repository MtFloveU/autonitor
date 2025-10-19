import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/secure_storage_service.dart';
import '../services/twitter_api_service.dart';

// [已更新]
// 核心改动：
// 1. 创建了两个独立的Provider：
//    - `accountsProvider`：管理所有已保存账号的列表。
//    - `activeAccountProvider`：管理当前被选中的活动账号。
// 2. `AccountsNotifier` 成为管理账号列表的核心，包含加载、添加、移除等方法。
// 3. 登录逻辑现在被封装在 `addAccount` 方法中。

// --- Provider定义 ---

// Provider for the list of all saved accounts
final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>((ref) {
  return AccountsNotifier(ref);
});

// Provider for the currently active account
final activeAccountProvider = StateProvider<Account?>((ref) {
  // 当应用启动时，尝试从存储中加载第一个账号作为默认活动账号
  final accounts = ref.watch(accountsProvider);
  if (accounts.isNotEmpty) {
    return accounts.first;
  }
  return null;
});

// --- State Notifier ---

class AccountsNotifier extends StateNotifier<List<Account>> {
  final Ref _ref;
  late final SecureStorageService _storageService;
  late final TwitterApiService _apiService;

  AccountsNotifier(this._ref) : super([]) {
    _storageService = _ref.read(secureStorageServiceProvider);
    _apiService = _ref.read(twitterApiServiceProvider);
    // Notifier创建时，立即从安全存储加载账号列表
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    state = await _storageService.getAccounts();
  }

  Future<void> addAccount(String cookie) async {
    // 验证Cookie有效性
    final profile = await _apiService.getUserProfile(cookie);
    if (profile == null) {
      throw Exception("提供的Cookie无效或已过期。");
    }

    // 从Cookie字符串中解析出 `twid` 作为唯一ID
    final twid = _parseTwidFromCookie(cookie);
    if (twid == null) {
      throw Exception('无法从Cookie中解析出twid');
    }

    final newAccount = Account(id: twid, cookie: cookie);

    // 更新状态（不可变地）
    // 检查是否已存在相同ID的账号
    final exists = state.any((acc) => acc.id == newAccount.id);
    if (exists) {
      // 如果存在，则替换它
      state = [
        for (final acc in state)
          if (acc.id == newAccount.id) newAccount else acc,
      ];
    } else {
      // 如果不存在，则添加到列表
      state = [...state, newAccount];
    }

    // 将更新后的完整列表保存到安全存储
    await _storageService.saveAccounts(state);
    
    // 将新添加的账号设为当前活动账号
    _ref.read(activeAccountProvider.notifier).state = newAccount;
  }

  // (将来可以实现)
  Future<void> removeAccount(String id) async {
    // ...
  }
  
  String? _parseTwidFromCookie(String cookie) {
    try {
      final parts = cookie.split(';');
      final twidPart = parts.firstWhere((part) => part.trim().startsWith('twid='));
      final valuePart = twidPart.split('=')[1];
      final decodedValue = Uri.decodeComponent(valuePart);
      final id = decodedValue.split('=')[1];
      return id;
    } catch (e) {
      return null;
    }
  }
}

