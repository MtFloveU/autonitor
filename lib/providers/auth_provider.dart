import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../models/cache_data.dart';
import '../models/twitter_user.dart';
import '../services/secure_storage_service.dart';
import '../services/twitter_api_service.dart';
import '../services/database.dart';
import '../main.dart';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../utils/diff_utils.dart';
import 'package:async/async.dart';
import '../services/twitter_api_v1_service.dart';
import 'package:flutter/material.dart'; // Import for @immutable
import 'package:drift/drift.dart' as drift; // Alias for count
import '../core/data_processor.dart';
import 'package:async_locks/async_locks.dart';

// --- Helper class for userListProvider parameters ---
@immutable
class UserListParam {
  final String ownerId;
  final String categoryKey;
  const UserListParam({required this.ownerId, required this.categoryKey});
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserListParam &&
          runtimeType == other.runtimeType &&
          ownerId == other.ownerId &&
          categoryKey == other.categoryKey;
  @override
  int get hashCode => ownerId.hashCode ^ categoryKey.hashCode;
}

// --- Moved Providers ---
final cacheProvider = FutureProvider.autoDispose<CacheData?>((ref) async {
  final database = ref.watch(databaseProvider);
  final activeAccount = ref.watch(activeAccountProvider);
  if (activeAccount == null) {
    print("cacheProvider: No active account, returning null.");
    return null;
  }
  print(
    "cacheProvider: Fetching counts from database for account ${activeAccount.id}...",
  );
  try {
    // --- Corrected Drift GroupBy Query ---
    final changeTypeCol = database.changeReports.changeType;
    final countExp = changeTypeCol.count();

    // 1. 创建查询
    final query = database.selectOnly(database.changeReports)
      ..addColumns([changeTypeCol, countExp])
      ..where(database.changeReports.ownerId.equals(activeAccount.id));

    // 2. 应用 groupBy
    query.groupBy([changeTypeCol]);

    // 3. 获取结果
    final countsResult = await query.get();

    // 4. 读取结果
    final Map<String, int> categoryCounts = {
      for (var row in countsResult)
        row.read(changeTypeCol)!: row.read(countExp)!,
    };
    // --- Correction End ---

    print("cacheProvider: Fetched category counts: $categoryCounts");
    final accountDetails = await (database.select(
      database.loggedAccounts,
    )..where((tbl) => tbl.id.equals(activeAccount.id))).getSingleOrNull();
    return CacheData(
      accountId: activeAccount.id,
      accountName: activeAccount.name ?? 'N/A',
      lastUpdateTime: DateTime.now().toIso8601String(),
      followersCount: accountDetails?.followersCount ?? 0,
      followingCount: accountDetails?.followingCount ?? 0,
      unfollowedCount: categoryCounts['normal_unfollowed'] ?? 0,
      mutualUnfollowedCount: categoryCounts['mutual_unfollowed'] ?? 0,
      singleUnfollowedCount: categoryCounts['oneway_unfollowed'] ?? 0,
      frozenCount: categoryCounts['suspended'] ?? 0,
      deactivatedCount: categoryCounts['deactivated'] ?? 0,
      refollowedCount: categoryCounts['be_followed_back'] ?? 0,
      newFollowersCount: categoryCounts['new_followers_following'] ?? 0,
      temporarilyRestrictedCount: categoryCounts['temporarily_restricted'] ?? 0,
    );
  } catch (e, s) {
    print("cacheProvider: Error fetching counts from database: $e\n$s");
    return null;
  }
});

final userListProvider = FutureProvider.family
    .autoDispose<List<TwitterUser>, UserListParam>((ref, param) async {
      final accountsNotifier = ref.watch(accountsProvider.notifier);
      try {
        return await accountsNotifier.getUsersForCategory(
          param.ownerId,
          param.categoryKey,
        );
      } catch (e) {
        print("userListProvider Error: $e");
        throw Exception('Failed to load user list');
      }
    });

class RefreshResult {
  final String accountId;
  final bool success;
  final String? error;
  RefreshResult({required this.accountId, required this.success, this.error});
}

final analysisLogProvider = StateProvider<List<String>>((ref) => []);

final analysisIsRunningProvider = StateProvider<bool>((ref) => false);

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
      print("ActiveAccountNotifier: Initialization skipped.");
      return;
    }
    print(
      "ActiveAccountNotifier: Initializing state with ${accounts.length} accounts and activeId: $activeId",
    );
    if (activeId != null && accounts.isNotEmpty) {
      try {
        final initialAccount = accounts.firstWhere((acc) => acc.id == activeId);
        state = initialAccount;
        print(
          "ActiveAccountNotifier: Initial state set to ID ${state?.id} from storage.",
        );
        _isInitialized = true;
      } catch (e) {
        print(
          "ActiveAccountNotifier: Stored active ID $activeId not found. Resetting.",
        );
        _resetActiveAccountAndMarkInitialized(accounts);
      }
    } else if (accounts.isNotEmpty) {
      print(
        "ActiveAccountNotifier: No active ID stored. Setting first account.",
      );
      _resetActiveAccountAndMarkInitialized(accounts);
    } else {
      print("ActiveAccountNotifier: No accounts loaded. State remains null.");
      state = null;
      _isInitialized = true;
    }
  }

  Future<void> _resetActiveAccountAndMarkInitialized(
    List<Account> accounts,
  ) async {
    await _resetActiveAccount(accounts);
    _isInitialized = true;
    print("ActiveAccountNotifier: Initialization completed after reset.");
  }

  Future<void> _resetActiveAccount(List<Account> accounts) async {
    if (accounts.isNotEmpty) {
      state = accounts.first;
      await _storageService.saveActiveAccountId(state!.id);
      print(
        "ActiveAccountNotifier: Reset active account to first ID ${state?.id}.",
      );
    } else {
      state = null;
      await _storageService.deleteActiveAccountId();
      print("ActiveAccountNotifier: Reset called but no accounts available.");
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
      "ActiveAccountNotifier: (Post-init) Account list updated. Current active ID: ${state?.id}. New list size: ${newList.length}",
    );
    if (state != null) {
      final bool stillExists = newList.any((acc) => acc.id == state!.id);
      if (!stillExists) {
        print(
          "ActiveAccountNotifier: (Post-init) Active account ${state!.id} removed. Resetting.",
        );
        await _resetActiveAccount(newList);
      } else {
        final updatedAccountInstance = newList.firstWhere(
          (acc) => acc.id == state!.id,
        );
        if (state != updatedAccountInstance) {
          state = updatedAccountInstance;
          print(
            "ActiveAccountNotifier: (Post-init) Updated active account instance for ID ${state!.id}.",
          );
        }
      }
    } else if (newList.isNotEmpty) {
      print(
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
          print(
            "ActiveAccountNotifier Listen: Initialized, calling updateFromList.",
          );
          notifier.updateFromList(newList);
        } else {
          print(
            "ActiveAccountNotifier Listen: Not initialized yet, skipping updateFromList.",
          );
        }
      });
      return notifier;
    });

class AccountsNotifier extends StateNotifier<List<Account>> {
  final Ref _ref;
  late final SecureStorageService _storageService;
  late final TwitterApiService _apiService;
  late final AppDatabase _database;
  late final TwitterApiV1Service _apiServiceV1;

  AccountsNotifier(this._ref) : super([]) {
    _storageService = _ref.read(secureStorageServiceProvider);
    _apiService = _ref.read(twitterApiServiceProvider);
    _database = _ref.read(databaseProvider);
    _apiServiceV1 = _ref.read(twitterApiV1ServiceProvider);
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    try {
      final profiles = await _database.select(_database.loggedAccounts).get();
      final cookies = await _storageService.getAllCookies();
      final storedActiveId = await _storageService.readActiveAccountId();
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
              latestRawJson: profile.latestRawJson,
            ),
          );
        } else {
          print(
            "AccountsNotifier: Warning - Profile found for ID ${profile.id} but no cookie in SecureStorage. Skipping.",
          );
        }
      }
      state = loadedAccounts;
      print("AccountsNotifier: Loaded and assembled ${state.length} accounts.");
      _ref
          .read(activeAccountProvider.notifier)
          .initializeState(loadedAccounts, storedActiveId);
    } catch (e, s) {
      print("AccountsNotifier: Error loading accounts: $e\n$s");
      state = [];
      _ref.read(activeAccountProvider.notifier).initializeState([], null);
    }
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
    String rawJsonString = '{}';
    try {
      final Map<String, dynamic> userProfileJson = await _apiService
          .getUserByRestId(twid, cookie);
      rawJsonString = jsonEncode(userProfileJson);
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
            /* Fallback */
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
      }
    } catch (e) {
      print("addAccount: 调用 API 或解析 Profile 时出错: $e");
      rethrow;
    }

    await _storageService.saveCookie(twid, cookie);
    print("addAccount: Saved cookie to SecureStorage for ID: $twid");
    try {
      await _database.transaction(() async {
        final oldProfile = await (_database.select(
          _database.loggedAccounts,
        )..where((tbl) => tbl.id.equals(twid))).getSingleOrNull();
        final oldJsonString = oldProfile?.latestRawJson;
        final diffString = calculateReverseDiff(rawJsonString, oldJsonString);
        print(
          "addAccount: Calculated reverse diff (length: ${diffString?.length ?? 'null'}) for ID: $twid",
        );
        final companion = LoggedAccountsCompanion(
          id: Value(twid),
          name: name == null ? const Value.absent() : Value(name),
          screenName: screenName == null
              ? const Value.absent()
              : Value(screenName),
          avatarUrl: avatarUrl == null
              ? const Value.absent()
              : Value(avatarUrl),
          bannerUrl: bannerUrl == null
              ? const Value.absent()
              : Value(bannerUrl),
          bio: bio == null ? const Value.absent() : Value(bio),
          location: location == null ? const Value.absent() : Value(location),
          link: link == null ? const Value.absent() : Value(link),
          joinTime: joinTime == null ? const Value.absent() : Value(joinTime),
          followersCount: Value(followersCount),
          followingCount: Value(followingCount),
          statusesCount: Value(statusesCount),
          mediaCount: Value(mediaCount),
          favouritesCount: Value(favouritesCount),
          listedCount: Value(listedCount),
          latestRawJson: Value(rawJsonString),
          avatarLocalPath: const Value.absent(),
          bannerLocalPath: const Value.absent(),
        );
        await _database
            .into(_database.loggedAccounts)
            .insert(companion, mode: InsertMode.replace);
        print(
          "addAccount: Inserted/Replaced profile in LoggedAccounts for ID: $twid",
        );
        if (diffString != null && diffString.isNotEmpty) {
          final historyCompanion = AccountProfileHistoryCompanion(
            ownerId: Value(twid),
            reverseDiffJson: Value(diffString),
            timestamp: Value(DateTime.now()),
          );
          await _database
              .into(_database.accountProfileHistory)
              .insert(historyCompanion);
          print(
            "addAccount: Inserted profile history into AccountProfileHistory for ID: $twid",
          );
        }
      });
      await loadAccounts();
    } catch (e, s) {
      print(
        "addAccount: Error during database transaction for ID $twid: $e\n$s",
      );
      throw Exception('Failed to save account data: $e');
    }
  }

  Future<void> removeAccount(String id) async {
    try {
      await _storageService.deleteCookie(id);
      print("AccountsNotifier: Deleted cookie from SecureStorage for ID $id.");
      final deletedRows = await (_database.delete(
        _database.loggedAccounts,
      )..where((tbl) => tbl.id.equals(id))).go();
      if (deletedRows > 0) {
        print("AccountsNotifier: Deleted profile from database for ID $id.");
      } else {
        print(
          "AccountsNotifier: Warning - Tried to delete profile for ID $id, but it was not found.",
        );
      }
      await loadAccounts();
    } catch (e, s) {
      print("AccountsNotifier: Error removing account ID $id: $e\n$s");
    }
  }

  Future<void> runAnalysisProcess(Account accountToProcess) async {
    _ref.read(analysisIsRunningProvider.notifier).state = true;
    _ref.read(analysisLogProvider.notifier).state = [];
    void logCallback(String message) {
      _ref
          .read(analysisLogProvider.notifier)
          .update((state) => [...state, message]);
    }

    logCallback('Initializing DataProcessor...');
    final dataProcessor = DataProcessor(
      database: _database,
      apiServiceGql: _apiService,
      apiServiceV1: _apiServiceV1,
      ownerAccount: accountToProcess,
      logCallback: logCallback,
    );
    try {
      await dataProcessor.runFullProcess();
      await loadAccounts();
      logCallback('Process finished successfully.');
    } catch (e, s) {
      logCallback('!!! PROCESS FAILED for account ${accountToProcess.id}: $e');
      logCallback('Stacktrace: $s');
      rethrow;
    } finally {
      _ref.read(analysisIsRunningProvider.notifier).state = false;
    }
  }

  Future<List<RefreshResult>> refreshAllAccountProfiles(
    List<Account> accounts,
  ) async {
    final semaphore = Semaphore(5);
    final group = FutureGroup<RefreshResult>();
    print(
      "AccountsNotifier: Starting refresh for ${accounts.length} accounts with concurrency limit 5...",
    );
    for (final account in accounts) {
      group.add(
        Future(() async {
          await semaphore.acquire();
          try {
            print("AccountsNotifier: Refreshing profile for ${account.id}...");
            await _refreshSingleAccountProfile(account);
            print("AccountsNotifier: Refresh successful for ${account.id}.");
            return RefreshResult(accountId: account.id, success: true);
          } catch (e) {
            print("AccountsNotifier: Refresh failed for ${account.id}: $e");
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
    print("AccountsNotifier: Refresh process completed.");
    return results;
  }

  Future<void> _refreshSingleAccountProfile(Account account) async {
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
    String rawJsonString = '{}';
    try {
      final Map<String, dynamic> userProfileJson = await _apiService
          .getUserByRestId(account.id, account.cookie);
      rawJsonString = jsonEncode(userProfileJson);
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
            /* Fallback */
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
        throw Exception('API returned invalid user data.');
      }

      await _database.transaction(() async {
        final oldProfile = await (_database.select(
          _database.loggedAccounts,
        )..where((tbl) => tbl.id.equals(account.id))).getSingleOrNull();
        final oldJsonString = oldProfile?.latestRawJson;
        final diffString = calculateReverseDiff(rawJsonString, oldJsonString);
        final companion = LoggedAccountsCompanion(
          id: Value(account.id),
          name: name == null ? const Value.absent() : Value(name),
          screenName: screenName == null
              ? const Value.absent()
              : Value(screenName),
          avatarUrl: avatarUrl == null
              ? const Value.absent()
              : Value(avatarUrl),
          bannerUrl: bannerUrl == null
              ? const Value.absent()
              : Value(bannerUrl),
          bio: bio == null ? const Value.absent() : Value(bio),
          location: location == null ? const Value.absent() : Value(location),
          link: link == null ? const Value.absent() : Value(link),
          joinTime: joinTime == null ? const Value.absent() : Value(joinTime),
          followersCount: Value(followersCount),
          followingCount: Value(followingCount),
          statusesCount: Value(statusesCount),
          mediaCount: Value(mediaCount),
          favouritesCount: Value(favouritesCount),
          listedCount: Value(listedCount),
          latestRawJson: Value(rawJsonString),
          avatarLocalPath: oldProfile?.avatarLocalPath == null
              ? const Value.absent()
              : Value(oldProfile!.avatarLocalPath),
          bannerLocalPath: oldProfile?.bannerLocalPath == null
              ? const Value.absent()
              : Value(oldProfile!.bannerLocalPath),
        );
        await _database
            .into(_database.loggedAccounts)
            .insert(companion, mode: InsertMode.replace);
        if (diffString != null && diffString.isNotEmpty) {
          final historyCompanion = AccountProfileHistoryCompanion(
            ownerId: Value(account.id),
            reverseDiffJson: Value(diffString),
            timestamp: Value(DateTime.now()),
          );
          await _database
              .into(_database.accountProfileHistory)
              .insert(historyCompanion);
          print(
            "AccountsNotifier: Inserted profile history for ${account.id} during refresh.",
          );
        }
      });
    } catch (e) {
      print("AccountsNotifier: Error refreshing profile for ${account.id}: $e");
      rethrow;
    }
  }

  Future<List<TwitterUser>> getUsersForCategory(
    String ownerId,
    String categoryKey,
  ) async {
    print(
      "AccountsNotifier: Getting users for category '$categoryKey' for owner '$ownerId'...",
    );
    try {
      List<TwitterUser> twitterUsers = [];

      // 逻辑 1: 获取 'followers' / 'following' (当前状态)
      if (categoryKey == 'followers' || categoryKey == 'following') {
        final bool isFollower = (categoryKey == 'followers');
        final query = _database.select(_database.followUsers)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                (isFollower
                    ? tbl.isFollower.equals(true)
                    : tbl.isFollowing.equals(true)),
          );
        final followUsers = await query.get();
        print(
          "AccountsNotifier: Fetched ${followUsers.length} users directly from FollowUsers for '$categoryKey'.",
        );

        // 解析 FollowUsers 记录
        for (final followUser in followUsers) {
          twitterUsers.add(
            _parseFollowUserToTwitterUser(
              followUser.userId,
              followUser.screenName,
              followUser.name,
              followUser.avatarUrl,
              followUser.bio,
              followUser.latestRawJson,
            ),
          );
        }
      }
      // 逻辑 2: 获取所有其他差异列表 (历史快照)
      else {
        final reportQuery = _database.select(_database.changeReports)
          ..where(
            (tbl) =>
                tbl.ownerId.equals(ownerId) &
                tbl.changeType.equals(categoryKey),
          );
        final reportResults = await reportQuery.get();
        print(
          "AccountsNotifier: Fetched ${reportResults.length} user snapshots from ChangeReport for '$categoryKey'.",
        );

        if (reportResults.isEmpty) {
          return [];
        }

        // --- 修正：直接从 reportResults 解析快照 ---
        for (final report in reportResults) {
          if (report.userSnapshotJson == null ||
              report.userSnapshotJson!.isEmpty) {
            print(
              "AccountsNotifier: Warning - No snapshot JSON found for user ${report.userId} in category $categoryKey",
            );
            continue;
          }
          // 使用辅助方法从快照 JSON 中解析 TwitterUser
          twitterUsers.add(
            _parseFollowUserToTwitterUser(
              report.userId,
              null, // dbScreenName (从 JSON 解析)
              null, // dbName (从 JSON 解析)
              null, // dbAvatarUrl (从 JSON 解析)
              null, // dbBio (从 JSON 解析)
              report.userSnapshotJson, // 传入快照 JSON
            ),
          );
        }
        // --- 修正结束 ---
      }
      return twitterUsers;
    } catch (e, s) {
      print(
        "AccountsNotifier: Error in getUsersForCategory '$categoryKey': $e\n$s",
      );
      throw Exception('Failed to load user list: $e');
    }
  }

  // --- 新增：统一的 API 1.1 JSON 解析辅助方法 ---
  TwitterUser _parseFollowUserToTwitterUser(
    String userId,
    String? dbScreenName,
    String? dbName,
    String? dbAvatarUrl,
    String? dbBio,
    String? jsonString,
  ) {
    // 默认值（来自 FollowUsers 表的缓存）
    String? screenName = dbScreenName;
    String? name = dbName;
    String? avatarUrl = dbAvatarUrl;
    String? bio = dbBio;
    String? location, link, joinTime, bannerUrl;
    int followersCount = 0,
        followingCount = 0,
        statusesCount = 0,
        mediaCount = 0,
        favouritesCount = 0,
        listedCount = 0;

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;

        // 覆盖或填充来自 JSON 的数据
        name = parsedJson['name'] as String? ?? name;
        screenName = parsedJson['screen_name'] as String? ?? screenName;
        avatarUrl =
            parsedJson['profile_image_url_https'] as String? ?? avatarUrl;
        bio = parsedJson['description'] as String? ?? bio;
        location = parsedJson['location'] as String?;
        joinTime = parsedJson['created_at'] as String?;
        bannerUrl = parsedJson['profile_banner_url'] as String?;
        followersCount = parsedJson['followers_count'] as int? ?? 0;
        followingCount =
            parsedJson['friends_count'] as int? ??
            0; // API 1.1 使用 friends_count
        statusesCount = parsedJson['statuses_count'] as int? ?? 0;
        mediaCount = parsedJson['media_count'] as int? ?? 0;
        favouritesCount = parsedJson['favourites_count'] as int? ?? 0;
        listedCount = parsedJson['listed_count'] as int? ?? 0;

        // --- 实现：API 1.1 expanded_url 逻辑 ---
        link = parsedJson['url'] as String?; // 默认 t.co 链接
        final entities = parsedJson['entities'] as Map<String, dynamic>?;
        final urlBlock = entities?['url'] as Map<String, dynamic>?;
        final urlsList = urlBlock?['urls'] as List<dynamic>?;
        if (link != null && urlsList != null && urlsList.isNotEmpty) {
          // 遍历 'urls' 列表
          for (final item in urlsList) {
            final urlMap = item as Map<String, dynamic>?;
            // 找到与 'url' (t.co) 匹配的条目
            if (urlMap != null && urlMap['url'] == link) {
              link = urlMap['expanded_url'] as String?; // 替换为 expanded_url
              break;
            }
          }
        }
        // --- 实现结束 ---

        // --- 实现：_400x400 替换 ---
        if (avatarUrl != null) {
          avatarUrl = avatarUrl.replaceFirst('_normal', '_400x400');
        }
        // --- 实现结束 ---
      } catch (e) {
        print("AccountsNotifier: Error parsing rawJson for user $userId: $e");
        // 即使解析失败，也继续使用数据库中的缓存数据
      }
    }

    return TwitterUser(
      restId: userId,
      id: screenName ?? userId, // handle
      name: name ?? 'Unknown Name',
      avatarUrl: avatarUrl ?? '',
      bio: bio,
      location: location,
      link: link,
      joinTime: joinTime ?? '', // <-- 修复：添加 '?? ''' 来处理 null
      bannerUrl: bannerUrl,
      followersCount: followersCount,
      followingCount: followingCount,
      statusesCount: statusesCount,
      mediaCount: mediaCount ?? 0,
      favouritesCount: favouritesCount,
      listedCount: listedCount,
      latestRawJson: jsonString,
    );
  }

  // --- 新增结束 ---
}
