import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/secure_storage_service.dart';
import '../services/twitter_api_service.dart';
import '../services/database.dart';
import '../main.dart';
import 'dart:convert';
import 'package:drift/drift.dart';

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
        await _storageService.deleteActiveAccountId();
        if (accounts.isNotEmpty) {
          state = accounts.first;
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
      await _storageService.saveActiveAccountId(account.id);
      print(
        "ActiveAccountNotifier: Set active account ID: ${account.id} and persisted.",
      );
    } else {
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
  late final AppDatabase _database;

  AccountsNotifier(this._ref) : super([]) {
    _storageService = _ref.read(secureStorageServiceProvider);
    _apiService = _ref.read(twitterApiServiceProvider);
    _database = _ref.read(databaseProvider);
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    try {
      final profiles = await _database.select(_database.loggedAccounts).get();
      final cookies = await _storageService.getAllCookies();
      final List<Account> loadedAccounts = [];
      for (final profile in profiles) {
        final cookie = cookies[profile.id];
        if (cookie != null) {
          loadedAccounts.add(
            Account(
              id: profile.id,
              cookie: cookie,
              name: profile.name,
              screenName: profile.screenName,
              avatarUrl: profile.avatarUrl,
              bannerUrl: profile.bannerUrl,
              bio: profile.bio,
              location: profile.location,
              link: profile.link,
              joinTime: profile.joinTime,
              followersCount: profile.followersCount,
              followingCount: profile.followingCount,
              statusesCount: profile.statusesCount,
              mediaCount: profile.mediaCount,
              favouritesCount: profile.favouritesCount,
              listedCount: profile.listedCount,
            ),
          );
        } else {
          print(
            "AccountsNotifier: Warning - Profile found for ID ${profile.id} but no cookie in SecureStorage. Skipping this account.",
          );
        }
      }
      state = loadedAccounts;
      print("AccountsNotifier: Loaded and assembled ${state.length} accounts.");
      _ref.read(activeAccountProvider.notifier).updateFromList(state);
    } catch (e, s) {
      print("AccountsNotifier: Error loading accounts: $e\n$s");
      state = [];
      _ref.read(activeAccountProvider.notifier).updateFromList(state);
    }
  }

  // <-- 修正：方法移动到 addAccount 之前
  String? _parseTwidFromCookie(String cookie) {
    try {
      final parts = cookie.split(';');
      final twidPart = parts.firstWhere(
        (part) => part.trim().startsWith('twid='),
        orElse: () => '',
      );
      if (twidPart.isNotEmpty) {
        var valuePart = twidPart.split('=')[1].trim();
        valuePart = Uri.decodeComponent(valuePart);
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
    String rawJsonString = '{}'; // <-- 初始化为空 JSON 对象字符串

    try {
      final Map<String, dynamic> userProfileJson = await _apiService
          .getUserByRestId(twid, cookie);
      rawJsonString = jsonEncode(userProfileJson); // <-- 保存原始 JSON
      final result = userProfileJson['data']?['user']?['result'];

      if (result != null &&
          result is Map<String, dynamic> &&
          result['__typename'] == 'User') {
        final core = result['core'];
        final legacy = result['legacy'];

        if (core != null && core is Map<String, dynamic>) {
          name = core['name'] as String?;
          screenName = core['screen_name'] as String?;
          avatarUrl = (result['avatar']['image_url'] as String?)?.replaceFirst(
            '_normal',
            '_400x400',
          );
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
          followingCount = legacy['friends_count'] as int? ?? 0;
          final String? tcoUrl = legacy['url'] as String?;
          String? finalLink = tcoUrl;

          try {
            final entities = legacy['entities'] as Map<String, dynamic>?;
            final urlBlock = entities?['url'] as Map<String, dynamic>?;
            final urlsList = urlBlock?['urls'] as List<dynamic>?;
            if (tcoUrl != null && urlsList != null) {
              for (final item in urlsList) {
                final urlMap = item as Map<String, dynamic>?;
                if (urlMap != null && urlMap['url'] == tcoUrl) {
                  finalLink = urlMap['expanded_url'] as String?;
                  break;
                }
              }
            }
          } catch (e) {
             // Fallback handled by finalLink initialization
          }
          link = finalLink;
          bannerUrl = legacy['profile_banner_url'] as String?;
          statusesCount = legacy['statuses_count'] as int? ?? 0;
          mediaCount = legacy['media_count'] as int? ?? 0;
          favouritesCount = legacy['favourites_count'] as int? ?? 0;
          listedCount = legacy['listed_count'] as int? ?? 0;
        }

        final locationMap = result['location'] as Map<String, dynamic>?;
        location = locationMap?['location'] as String?;
      } else {
        print("addAccount: API 返回成功，但 result 数据缺失或格式不正确。");
        // Consider throwing an error if profile data is essential
      }
    } catch (e) {
      print("addAccount: 调用 API 或解析 Profile 时出错: $e");
      rethrow;
    }

    await _storageService.saveCookie(twid, cookie);
    print("addAccount: Saved cookie to SecureStorage for ID: $twid");

    final companion = LoggedAccountsCompanion(
      id: Value(twid),
      name: Value(name),
      screenName: Value(screenName),
      avatarUrl: Value(avatarUrl),
      bannerUrl: Value(bannerUrl),
      bio: Value(bio),
      location: Value(location),
      link: Value(link),
      joinTime: Value(joinTime),
      followersCount: Value(followersCount),
      followingCount: Value(followingCount),
      statusesCount: Value(statusesCount),
      mediaCount: Value(mediaCount),
      favouritesCount: Value(favouritesCount),
      listedCount: Value(listedCount),
      latestRawJson: Value(rawJsonString),
      avatarLocalPath: Value(null),
      bannerLocalPath: Value(null),
    );

    await _database.into(_database.loggedAccounts).insert(
          companion,
          mode: InsertMode.replace,
        );
    print("addAccount: Inserted/Replaced profile in database for ID: $twid");

    await loadAccounts(); // <-- 修正：只保留 loadAccounts()

  } // <--- addAccount 方法结束

  Future<void> removeAccount(String id) async {
    try {
      await _storageService.deleteCookie(id);
      print("AccountsNotifier: Deleted cookie from SecureStorage for ID $id.");

      final deletedRows = await (_database.delete(_database.loggedAccounts)..where((tbl) => tbl.id.equals(id))).go();
      
      if (deletedRows > 0) {
         print("AccountsNotifier: Deleted profile from database for ID $id.");
      } else {
         print("AccountsNotifier: Warning - Tried to delete profile for ID $id, but it was not found in the database.");
      }

      await loadAccounts(); 

    } catch (e, s) {
      print("AccountsNotifier: Error removing account ID $id: $e\n$s");
    }
  }

}