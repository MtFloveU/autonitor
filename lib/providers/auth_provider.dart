import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/secure_storage_service.dart';
import '../services/twitter_api_service.dart';
import 'dart:convert';

// --- Provider 定义 ---

// accountsProvider 保持不变
final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>(
  (ref) {
    return AccountsNotifier(ref);
  },
);

// --- ActiveAccountNotifier ---
class ActiveAccountNotifier extends StateNotifier<Account?> {
  final Ref _ref;
  late final SecureStorageService _storageService;

  ActiveAccountNotifier(this._ref) : super(null) {
    _storageService = _ref.read(secureStorageServiceProvider);
    _initializeActiveAccount();
  }

  Future<void> _initializeActiveAccount() async {
    final activeId = await _storageService.readActiveAccountId();
    final accounts = _ref.read(accountsProvider);
    print(
      "ActiveAccountNotifier: Initializing... Loaded active ID: $activeId. Current accounts: ${accounts.length}",
    );
    if (activeId != null && accounts.isNotEmpty) {
      try {
        final initialAccount = accounts.firstWhere((acc) => acc.id == activeId);
        state = initialAccount;
        print(
          "ActiveAccountNotifier: Initial active account set to ID ${state?.id}.",
        );
      } catch (e) {
        print(
          "ActiveAccountNotifier: Stored active ID $activeId not found in accounts list. Resetting.",
        );
        // 使用假设的正确方法名
        await _storageService.deleteActiveAccountId();
        if (accounts.isNotEmpty) {
          state = accounts.first;
          // 使用假设的正确方法名
          await _storageService.saveActiveAccountId(state!.id);
          print(
            "ActiveAccountNotifier: Reset active account to first account ID ${state?.id}.",
          );
        } else {
          state = null;
          print("ActiveAccountNotifier: No accounts available after reset.");
        }
      }
    } else if (accounts.isNotEmpty) {
      state = accounts.first;
      // 使用假设的正确方法名
      await _storageService.saveActiveAccountId(state!.id);
      print(
        "ActiveAccountNotifier: No active ID stored, setting first account ID ${state?.id} as active.",
      );
    } else {
      state = null;
      print(
        "ActiveAccountNotifier: No accounts available, active account remains null.",
      );
    }
  }

  Future<void> setActive(Account? account) async {
    state = account;
    if (account != null) {
      // 使用假设的正确方法名
      await _storageService.saveActiveAccountId(account.id);
      print(
        "ActiveAccountNotifier: Set active account ID: ${account.id} and persisted.",
      );
    } else {
      // 使用假设的正确方法名
      await _storageService.deleteActiveAccountId();
      print("ActiveAccountNotifier: Cleared active account ID and persisted.");
    }
  }

  Future<void> updateFromList(List<Account> newList) async {
    print(
      "ActiveAccountNotifier: Account list updated. Current active ID: ${state?.id}. New list size: ${newList.length}",
    );
    if (state == null) {
      if (newList.isNotEmpty) {
        await setActive(newList.first);
        print(
          "ActiveAccountNotifier: No previous active account, set first of new list (${state?.id}) as active.",
        );
      } else {
        print(
          "ActiveAccountNotifier: No previous active account and new list is empty.",
        );
      }
    } else {
      final bool stillExists = newList.any((acc) => acc.id == state!.id);
      if (!stillExists) {
        print(
          "ActiveAccountNotifier: Active account ID ${state!.id} no longer exists in the updated list.",
        );
        await setActive(newList.isNotEmpty ? newList.first : null);
        print(
          "ActiveAccountNotifier: Reset active account to ${state?.id ?? 'null'}.",
        );
      } else {
        print(
          "ActiveAccountNotifier: Active account ID ${state!.id} still exists. No change needed.",
        );
        final updatedAccountInstance = newList.firstWhere(
          (acc) => acc.id == state!.id,
        );
        if (state != updatedAccountInstance) {
          state = updatedAccountInstance;
          print(
            "ActiveAccountNotifier: Updated active account instance for ID ${state!.id}.",
          );
        }
      }
    }
  }
}

// activeAccountProvider 保持不变
final activeAccountProvider =
    StateNotifierProvider<ActiveAccountNotifier, Account?>((ref) {
      final notifier = ActiveAccountNotifier(ref);
      ref.listen(accountsProvider, (previousList, newList) {
        notifier.updateFromList(newList);
      });
      return notifier;
    });

// --- AccountsNotifier ---

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
    state = await _storageService.getAccounts(); // Assuming getAccounts exists
    print("AccountsNotifier: Loaded ${state.length} accounts.");
    // Notify ActiveAccountNotifier after loading
    _ref.read(activeAccountProvider.notifier).updateFromList(state);
  }

  Future<void> addAccount(String cookie) async {
    final twid = _parseTwidFromCookie(cookie);
    if (twid == null) {
      throw Exception('无法从Cookie中解析出twid');
    }

    String? name;
    String? screenName;
    String? avatarUrl;
    String? bannerUrl;
    String? bio;
    String? location;
    String? link;
    String? joinTime;
    int followersCount = 0;
    int followingCount = 0;
    int statusesCount = 0;
    int mediaCount = 0;
    int favouritesCount = 0;
    int listedCount = 0;

    try {
      final Map<String, dynamic> userProfileJson = await _apiService
          .getUserByRestId(twid, cookie);

      final result = userProfileJson['data']?['user']?['result'];

      // ... 在 addAccount 方法内部 ...
      if (result != null &&
          result is Map<String, dynamic> &&
          result['__typename'] == 'User') {
        // --- 修正后的解析逻辑 ---

        final core = result['core'];
        final legacy = result['legacy'];

        if (core != null && core is Map<String, dynamic>) {
          name = core['name'] as String?;
          screenName = core['screen_name'] as String?;
          avatarUrl = (result['avatar']['image_url'] as String?)?.replaceFirst(
            '_normal',
            '_400x400',
          );

          // 'joinTime' 来自 core
          joinTime = core['created_at'] as String?;

          print(
            "addAccount: Profile fetched - Name: $name, ScreenName: $screenName, Avatar: $avatarUrl",
          );
        } else {
          print("addAccount: API 返回成功，但 core 数据缺失或格式不正确。");
        }

        if (legacy != null && legacy is Map<String, dynamic>) {
          bio = legacy['description'] as String?;
          followersCount = legacy['followers_count'] as int? ?? 0;
          followingCount =
              legacy['friends_count'] as int? ?? 0; // API 使用 'friends_count'
          final String? tcoUrl = legacy['url'] as String?;
          String? finalLink = tcoUrl; // 默认回退到 t.co 链接

          try {
            final entities = legacy['entities'] as Map<String, dynamic>?;
            final urlBlock = entities?['url'] as Map<String, dynamic>?;
            final urlsList = urlBlock?['urls'] as List<dynamic>?;

            if (tcoUrl != null && urlsList != null) {
              // 遍历列表，查找 t.co 链接匹配的块
              for (final item in urlsList) {
                final urlMap = item as Map<String, dynamic>?;
                if (urlMap != null && urlMap['url'] == tcoUrl) {
                  // 找到了！使用 expanded_url
                  finalLink = urlMap['expanded_url'] as String?;
                  break; // 停止搜索
                }
              }
            }
          } catch (e) {
            // 发生解析错误，finalLink 将保持为 tcoUrl，这正是我们想要的回退行为
          }

          link = finalLink;

          // [修正] 'bannerUrl' 来自 legacy
          bannerUrl = legacy['profile_banner_url'] as String?;
          statusesCount = legacy['statuses_count'] as int? ?? 0;
          mediaCount = legacy['media_count'] as int? ?? 0;
          favouritesCount = legacy['favourites_count'] as int? ?? 0;
          listedCount = legacy['listed_count'] as int? ?? 0;
        }

        // [修正] 'location' 是一个嵌套对象
        final locationMap = result['location'] as Map<String, dynamic>?;
        location = locationMap?['location'] as String?;

        // --- 修正结束 ---
      } else {
        print("addAccount: API 返回成功，但 result 数据缺失或格式不正确。");
      }
    } catch (e) {
      print("addAccount: 调用 API 或解析 Profile 时出错: $e");
      rethrow;
    }

    // --- 使用正确的命名参数调用 Account 构造函数 ---
    final newAccount = Account(
      id: twid,
      cookie: cookie,
      name: name, // 确保 Account 构造函数有 'name'
      screenName: screenName, // 确保 Account 构造函数有 'screenName'
      avatarUrl: avatarUrl, // 确保 Account 构造函数有 'avatarUrl'
      bannerUrl: bannerUrl,
      bio: bio,
      location: location,
      link: link,
      joinTime: joinTime,
      followersCount: followersCount,
      followingCount: followingCount,
      statusesCount: statusesCount,
      mediaCount: mediaCount,
      favouritesCount: favouritesCount,
      listedCount: listedCount,
    );

    // --- 将这部分代码移回方法内部 ---
    final exists = state.any((acc) => acc.id == newAccount.id);
    List<Account> newList;
    if (exists) {
      newList = [
        for (final acc in state)
          if (acc.id == newAccount.id) newAccount else acc,
      ];
      print("addAccount: Updated existing account for ID: $twid");
    } else {
      newList = [...state, newAccount];
      print("addAccount: Added new account for ID: $twid");
    }
    state = newList;

    // Assuming saveAccounts exists and uses the correct state
    await _storageService.saveAccounts(state);
    print("addAccount: Saved accounts list to secure storage.");

    await _ref.read(activeAccountProvider.notifier).setActive(newAccount);
    print("addAccount: Set account ID $twid as active.");
    // --- 移动的代码块结束 ---
  } // <--- addAccount 方法结束

  Future<void> removeAccount(String id) async {
    final newList = state.where((acc) => acc.id != id).toList();
    state = newList;
    // Assuming saveAccounts exists
    await _storageService.saveAccounts(state);
    print("AccountsNotifier: Removed account ID $id and saved.");
  }

  String? _parseTwidFromCookie(String cookie) {
    try {
      final parts = cookie.split(';');
      final twidPart = parts.firstWhere(
        (part) => part.trim().startsWith('twid='),
        orElse: () => '',
      );
      if (twidPart.isNotEmpty) {
        var valuePart = twidPart.split('=')[1].trim();

        // URL 解码
        valuePart = Uri.decodeComponent(valuePart);

        // 兼容 u=xxxx 或 u_xxxx
        if (valuePart.startsWith('u=')) {
          final id = valuePart.substring(2);
          return id.isNotEmpty ? id : null;
        } else if (valuePart.startsWith('u_')) {
          final id = valuePart.substring(2);
          return id.isNotEmpty ? id : null;
        } else {
          print("解析 twid 失败: twid value ($valuePart) 不以 'u=' 或 'u_' 开头");
          return null;
        }
      }
      return null;
    } catch (e) {
      print("Error parsing twid from cookie: $e");
      return null;
    }
  }
}
