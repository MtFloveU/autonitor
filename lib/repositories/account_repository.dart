// lib/repositories/account_repository.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import '../models/account.dart';
import '../services/database.dart';
import '../services/twitter_api_service.dart';
import '../services/secure_storage_service.dart';
import '../main.dart';
import '../utils/diff_utils.dart';
import 'package:autonitor/services/log_service.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../services/image_history_service.dart';
import '../providers/graphql_queryid_provider.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final apiService = ref.watch(twitterApiServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);

  return AccountRepository(db, apiService, secureStorage, ref);
});

class AccountRepository {
  final AppDatabase _database;
  final TwitterApiService _apiService;
  final SecureStorageService _secureStorage;
  final Ref _ref;

  AccountRepository(
    this._database,
    this._apiService,
    this._secureStorage,
    this._ref,
  );

  String? _parseidFromCookie(String cookie) {
    try {
      final parts = cookie.split(';');
      final idPart = parts.firstWhere(
        (part) => part.trim().startsWith('twid='),
        orElse: () => '',
      );
      if (idPart.isNotEmpty) {
        var valuePart = idPart.split('=')[1].trim();
        valuePart = Uri.decodeComponent(valuePart);
        if (valuePart.startsWith('u=')) {
          final id = valuePart.substring(2);
          return id.isNotEmpty ? id : null;
        } else if (valuePart.startsWith('u_')) {
          final id = valuePart.substring(2);
          return id.isNotEmpty ? id : null;
        } else {
          logger.w("解析 id 失败: id value ($valuePart) 不以 'u=' 或 'u_' 开头");
          return null;
        }
      }
      return null;
    } catch (e, s) {
      logger.e("Error parsing id from cookie", error: e, stackTrace: s);
      return null;
    }
  }

  Future<Account> addAccount(String cookie) async {
    final id = _parseidFromCookie(cookie);
    if (id == null) {
      throw Exception('Unable to parse ID from Cookie');
    }
    await _secureStorage.saveCookie(id, cookie);
    logger.i("addAccount: Saved cookie to SecureStorage for ID: $id");
    return await _fetchAndSaveAccountProfile(id, cookie);
  }

  Future<void> removeAccount(String id) async {
    try {
      await _secureStorage.deleteCookie(id);
      logger.i(
        "AccountRepository: Deleted cookie from SecureStorage for ID $id.",
      );

      final deletedRows = await (_database.delete(
        _database.loggedAccounts,
      )..where((tbl) => tbl.id.equals(id))).go();

      if (deletedRows > 0) {
        logger.i(
          "AccountRepository: Deleted profile from database for ID $id.",
        );
      } else {
        logger.w(
          "AccountRepository: Tried to delete profile for ID $id, but it was not found.",
        );
      }
    } catch (e, s) {
      logger.e(
        "AccountRepository: Error removing account ID $id",
        error: e,
        stackTrace: s,
      );
      throw Exception('Failed to remove account: $e');
    }
  }

  Future<List<Account>> getAllAccounts() async {
    try {
      final profiles = await _database.select(_database.loggedAccounts).get();
      final cookies = await _secureStorage.getAllCookies();
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
              // [修复 1] 映射本地路径字段
              avatarLocalPath: profile.avatarLocalPath,
              bannerLocalPath: profile.bannerLocalPath,
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
              isVerified: profile.isVerified ?? false,
              isProtected: profile.isProtected ?? false,
            ),
          );
        } else {
          logger.w(
            "AccountRepository: Profile found for ID ${profile.id} but no cookie in SecureStorage. Skipping.",
          );
        }
      }
      return loadedAccounts;
    } catch (e, s) {
      logger.e(
        "AccountRepository: Error getting all accounts",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<Account> refreshAccountProfile(Account account) async {
    return await _fetchAndSaveAccountProfile(account.id, account.cookie);
  }

  Future<Account> _fetchAndSaveAccountProfile(String id, String cookie) async {
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
    bool isVerified = false;
    bool isProtected = false;
    try {
      final queryId = _ref
          .read(gqlQueryIdProvider.notifier)
          .getCurrentQueryIdForDisplay('UserByRestId');
      final Map<String, dynamic> userProfileJson = await _apiService
          .getUserByRestId(id, cookie, queryId);
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
          avatarUrl = (result['avatar']['image_url'] as String?);
          joinTime = core['created_at'] as String?;
          logger.i(
            "addAccount: Profile fetched - Name: $name, ScreenName: $screenName, Avatar: $avatarUrl",
          );
        } else {
          logger.w("addAccount: API 返回成功，但 core 数据缺失或格式不正确。");
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
          } catch (e, s) {
            logger.w(
              "addAccount: Failed to parse URL entities",
              error: e,
              stackTrace: s,
            );
          }
          link = finalLink;
          bannerUrl = legacy['profile_banner_url'] as String?;
          statusesCount = legacy['statuses_count'] as int? ?? 0;
          mediaCount = legacy['media_count'] as int? ?? 0;
          favouritesCount = legacy['favourites_count'] as int? ?? 0;
          listedCount = legacy['listed_count'] as int? ?? 0;
          isVerified = result['verification']['verified'] as bool? ?? false;
          isProtected = result['privacy']['protected'] as bool? ?? false;
        }
        final locationMap = result['location'] as Map<String, dynamic>?;
        location = locationMap?['location'] as String?;
      } else {
        logger.w(
          "addAccount: The API call succeeded, but the result field is either missing or malformed.",
        );
      }
    } catch (e, s) {
      logger.e(
        "addAccount: Failed to call the API or parse the Profile.",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
    try {
      final settingsValue = _ref.read(settingsProvider);
      final imageService = _ref.read(imageHistoryServiceProvider);

      final AppSettings settings;
      if (settingsValue is AsyncData<AppSettings>) {
        settings = settingsValue.value;
      } else {
        logger.e("在 AccountRepository 中读取设置失败，状态为: $settingsValue");
        throw Exception("无法执行操作，因为设置未准备好: $settingsValue");
      }

      // [修复 2] 定义变量以捕获事务中确定的最终路径
      String? finalAvatarLocalPath;
      String? finalBannerLocalPath;

      await _database.transaction(() async {
        final oldProfile = await (_database.select(
          _database.loggedAccounts,
        )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
        final oldJsonString = oldProfile?.latestRawJson;
        final diffString = calculateReverseDiff(rawJsonString, oldJsonString);
        logger.i(
          "addAccount: Calculated reverse diff (length: ${diffString?.length ?? 'null'}) for ID: $id",
        );
        final String? newAvatarLocalPath = await imageService
            .processMediaUpdate(
              ownerId: id,
              userId: id,
              mediaType: MediaType.avatar,
              oldUrl: oldProfile?.avatarUrl,
              newUrl: avatarUrl, // (这是你从 API 获取的 avatarUrl)
              settings: settings, // 使用我们从 read 读到的 settings
            );

        // 11. (新) 处理横幅下载
        final String? newBannerLocalPath = await imageService
            .processMediaUpdate(
              ownerId: id,
              userId: id,
              mediaType: MediaType.banner,
              oldUrl: oldProfile?.bannerUrl,
              newUrl: bannerUrl, // (这是你从 API 获取的 bannerUrl)
              settings: settings, // 使用我们从 read 读到的 settings
            );

        // [修复 2] 确定最终的 Companion 值和返回对象值
        final avatarPathValue = newAvatarLocalPath != null
            ? Value<String?>(newAvatarLocalPath)
            : (avatarUrl == oldProfile?.avatarUrl
                  ? Value<String?>(oldProfile?.avatarLocalPath)
                  : const Value<String?>.absent());

        final bannerPathValue = newBannerLocalPath != null
            ? Value<String?>(newBannerLocalPath)
            : (bannerUrl == oldProfile?.bannerUrl
                  ? Value<String?>(oldProfile?.bannerLocalPath)
                  : const Value<String?>.absent());

        // 捕获用于返回对象的值 (如果 Value 是 absent，则 finalPath 保持为 null/旧值需要小心处理)
        // 这里简化逻辑：如果是 absent 且没有新值，说明我们没有更改它，所以应该沿用旧值
        if (newAvatarLocalPath != null) {
          finalAvatarLocalPath = newAvatarLocalPath;
        } else if (avatarUrl == oldProfile?.avatarUrl) {
          finalAvatarLocalPath = oldProfile?.avatarLocalPath;
        }

        if (newBannerLocalPath != null) {
          finalBannerLocalPath = newBannerLocalPath;
        } else if (bannerUrl == oldProfile?.bannerUrl) {
          finalBannerLocalPath = oldProfile?.bannerLocalPath;
        }

        final companion = LoggedAccountsCompanion(
          id: Value(id),
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
          isVerified: Value(isVerified),
          isProtected: Value(isProtected),
          latestRawJson: Value(rawJsonString),
          avatarLocalPath: avatarPathValue,
          bannerLocalPath: bannerPathValue,
        );
        await _database
            .into(_database.loggedAccounts)
            .insert(companion, mode: InsertMode.replace);
        logger.i(
          "addAccount: Inserted/Replaced profile in LoggedAccounts for ID: $id",
        );
        if (diffString != null && diffString.isNotEmpty) {
          final historyCompanion = AccountProfileHistoryCompanion(
            ownerId: Value(id),
            reverseDiffJson: Value(diffString),
            timestamp: Value(DateTime.now()),
          );
          await _database
              .into(_database.accountProfileHistory)
              .insert(historyCompanion);
          logger.i(
            "addAccount: Inserted profile history into AccountProfileHistory for ID: $id",
          );
        }
      });
      return Account(
        id: id,
        cookie: cookie,
        name: name,
        screenName: screenName,
        avatarUrl: avatarUrl,
        // [修复 2] 传入计算出的路径
        avatarLocalPath: finalAvatarLocalPath,
        bannerUrl: bannerUrl,
        // [修复 2] 传入计算出的路径
        bannerLocalPath: finalBannerLocalPath,
        bio: bio,
        location: location,
        link: link,
        joinTime: joinTime,
        followersCount: followersCount,
        followingCount: followingCount,
        statusesCount: statusesCount,
        mediaCount: mediaCount,
        favouritesCount: favouritesCount,
        isVerified: isVerified,
        isProtected: isProtected,
        listedCount: listedCount,
        latestRawJson: rawJsonString,
      );
    } catch (e, s) {
      logger.e(
        "addAccount: Error during database transaction for ID $id",
        error: e,
        stackTrace: s,
      );
      throw Exception('Failed to save account data: $e');
    }
  }

  String getCurrentQueryId(String operationName) {
    return _ref
        .read(gqlQueryIdProvider.notifier)
        .getCurrentQueryIdForDisplay(operationName);
  }
}
