import 'dart:convert';
import 'package:async/async.dart';
import 'package:drift/drift.dart';
import '../models/account.dart';
import '../services/database.dart';
import '../services/twitter_api_service.dart';
import '../services/twitter_api_v1_service.dart';
import '../utils/diff_utils.dart';
import 'package:async_locks/async_locks.dart';
import '../models/app_settings.dart';
import '../services/image_history_service.dart';
import '../repositories/account_repository.dart';

typedef LogCallback = void Function(String message);

class DataProcessor {
  final AppDatabase _database;
  final TwitterApiService _apiServiceGql;
  final TwitterApiV1Service _apiServiceV1;
  final String _ownerId;
  final String _ownerCookie;
  final AccountRepository _accountRepository;
  final LogCallback _log;
  final AppSettings _settings;
  final ImageHistoryService _imageService;

  DataProcessor({
    required AppDatabase database,
    required TwitterApiService apiServiceGql,
    required TwitterApiV1Service apiServiceV1,
    required AccountRepository accountRepository,
    required Account ownerAccount,
    required AppSettings settings,
    required ImageHistoryService imageService,
    required LogCallback logCallback,
  }) : _database = database,
       _apiServiceGql = apiServiceGql,
       _apiServiceV1 = apiServiceV1,
       _accountRepository = accountRepository,
       _ownerId = ownerAccount.id,
       _ownerCookie = ownerAccount.cookie,
       _log = logCallback,
       _settings = settings,
       _imageService = imageService;

  Future<void> runFullProcess() async {
    _log("Starting analysis process for account ID: $_ownerId...");
    try {
      _log("Refreshing owner account profile ($_ownerId)...");
      // 我们需要一个 Account 对象，构造函数里已经有了
      final ownerAccount = Account(id: _ownerId, cookie: _ownerCookie);
      // _fetchAndSaveAccountProfile 会处理所有逻辑：
      // 1. GQL API 调用
      // 2. JSON Diff 计算
      // 3. 图像下载 (使用正确的 ownerId: _ownerId, userId: _ownerId)
      // 4. 数据库保存 (LoggedAccounts 和 AccountProfileHistory)
      await _accountRepository.refreshAccountProfile(ownerAccount);
      _log("Owner account profile refresh successful.");
    } catch (e) {
      // 如果只是 owner 刷新失败，我们记录错误但继续执行
      _log(
        "!!! WARNING: Failed to refresh owner account profile: $e. "
        "Continuing with follower/following analysis...",
      );
    }

    try {
      _log("Fetching old relationships from database...");
      final List<FollowUser> oldRelationsList = await _database
          .getNetworkRelationships(_ownerId);
      final Map<String, FollowUser> oldRelationsMap = {
        for (var relation in oldRelationsList) relation.userId: relation,
      };
      _log("Found ${oldRelationsMap.length} existing relationships.");

      _log("Fetching new followers from API...");
      final Map<String, Map<String, dynamic>> newUserJsons = {};
      final Set<String> newFollowerIds = {};
      final Set<String> newFollowingIds = {};

      String? nextFollowerCursor;
      do {
        final followerResult = await _apiServiceV1.getFollowers(
          _ownerId,
          _ownerCookie,
          cursor: nextFollowerCursor,
        );
        for (var userJson in followerResult.users) {
          final userId =
              userJson['id_str'] as String? ?? userJson['id']?.toString();
          if (userId != null) {
            newUserJsons[userId] = Map<String, dynamic>.from(userJson);
            newFollowerIds.add(userId);
          }
        }
        nextFollowerCursor = followerResult.nextCursor;
        _log(
          "Fetched ${followerResult.users.length} followers, next cursor: $nextFollowerCursor",
        );
      } while (nextFollowerCursor != null &&
          nextFollowerCursor != '0' &&
          nextFollowerCursor.isNotEmpty);

      _log(
        "Finished fetching followers. Total unique users so far: ${newUserJsons.length}",
      );

      _log("Fetching new following from API...");
      String? nextFollowingCursor;
      do {
        final followingResult = await _apiServiceV1.getFollowing(
          _ownerId,
          _ownerCookie,
          cursor: nextFollowingCursor,
        );
        for (var userJson in followingResult.users) {
          final userId =
              userJson['id_str'] as String? ?? userJson['id']?.toString();
          if (userId != null) {
            newFollowingIds.add(userId);
            if (!newUserJsons.containsKey(userId)) {
              newUserJsons[userId] = Map<String, dynamic>.from(userJson);
            }
          }
        }
        nextFollowingCursor = followingResult.nextCursor;
        _log(
          "Fetched ${followingResult.users.length} following, next cursor: $nextFollowingCursor",
        );
      } while (nextFollowingCursor != null &&
          nextFollowingCursor != '0' &&
          nextFollowingCursor.isNotEmpty);

      _log(
        "Finished fetching following. Total unique users in combined list: ${newUserJsons.length}",
      );

      final Set<String> newIds = newUserJsons.keys.toSet();
      final Set<String> oldIds = oldRelationsMap.keys.toSet();
      final Set<String> addedIds = newIds.difference(oldIds);
      final Set<String> removedIds = oldIds.difference(newIds);
      final Set<String> keptIds = newIds.intersection(oldIds);
      _log(
        "Calculated differences: ${addedIds.length} added, ${removedIds.length} removed, ${keptIds.length} kept.",
      );

      _log(
        "Processing ${removedIds.length} removed users to determine status...",
      );
      final Map<String, String> categorizedRemovals = {};
      if (removedIds.isNotEmpty) {
        final semaphore = Semaphore(5);
        final group = FutureGroup<void>();
        for (final removedId in removedIds) {
          group.add(
            Future(() async {
              await semaphore.acquire();
              String category = 'unknown_error';
              try {
                final Map<String, dynamic> gqlJson = await _apiServiceGql
                    .getUserByRestId(removedId, _ownerCookie);
                final result = gqlJson['data']?['user']?['result'];
                final typename = result?['__typename'];

                if (typename == 'User') {
                  final legacy = result?['legacy'];
                  final interstitial =
                      legacy?['profile_interstitial_type'] as String?;
                  if (interstitial != null && interstitial.isNotEmpty) {
                    category = 'temporarily_restricted';
                  } else {
                    final oldRel = oldRelationsMap[removedId];
                    final wasFollower = oldRel?.isFollower ?? false;
                    final wasFollowing = oldRel?.isFollowing ?? false;
                    if (wasFollower && wasFollowing) {
                      category = 'mutual_unfollowed';
                    } else if (wasFollower) {
                      category = 'normal_unfollowed';
                    } else if (wasFollowing) {
                      category = 'normal_unfollowed';
                    } else {
                      category = 'unknown_removed_state';
                    }
                  }
                } else if (typename == 'UserUnavailable') {
                  category = 'suspended';
                } else if (gqlJson['data']?['user'] == null ||
                    (gqlJson['data']?['user'] is Map &&
                        (gqlJson['data']['user'] as Map).isEmpty)) {
                  category = 'deactivated';
                } else {
                  _log(
                    "Warning: Unexpected GraphQL response for $removedId: $gqlJson",
                  );
                  category = 'unknown_gql_response';
                }
              } catch (e) {
                _log("Error fetching GraphQL for removed user $removedId: $e");
                category = 'unknown_error';
              } finally {
                categorizedRemovals[removedId] = category;
                semaphore.release();
              }
            }),
          );
        }
        group.close();
        await group.future;
        _log("Finished processing removed users.");
      }

      _log("Preparing data for database update...");

      final List<FollowUsersCompanion> companionsToUpsert = [];
      final List<FollowUsersHistoryCompanion> historyToInsert = [];

      final List<Map<String, dynamic>> downloadTasks = [];
      const String suffixRegex = r'_(normal|bigger|400x400)';

      for (final userId in newIds) {
        final userJson = newUserJsons[userId]!;
        final oldRelation = oldRelationsMap[userId];

        if (oldRelation != null) {
          final oldJsonString = oldRelation.latestRawJson;
          final newJsonString = jsonEncode(userJson);
          final diffString = calculateReverseDiff(newJsonString, oldJsonString);
          if (diffString != null && diffString.isNotEmpty) {
            historyToInsert.add(
              FollowUsersHistoryCompanion(
                ownerId: Value(_ownerId),
                userId: Value(userId),
                reverseDiffJson: Value(diffString),
                timestamp: Value(DateTime.now()),
              ),
            );
          }
        }

        final String? newAvatarUrl =
            (userJson['profile_image_url_https'] as String?);
        final String? oldAvatarUrl = oldRelation?.avatarUrl;

        String? effectiveNewUrl = newAvatarUrl;
        String? effectiveOldUrl = oldAvatarUrl;

        if (_settings.avatarQuality == AvatarQuality.low) {
          if (effectiveNewUrl != null) {
            effectiveNewUrl = effectiveNewUrl.replaceFirst(
              RegExp(suffixRegex),
              '_bigger',
            );
          }
          if (effectiveOldUrl != null) {
            effectiveOldUrl = effectiveOldUrl.replaceFirst(
              RegExp(suffixRegex),
              '_bigger',
            );
          }
        } else {
          if (effectiveNewUrl != null) {
            effectiveNewUrl = effectiveNewUrl.replaceFirst(
              RegExp(suffixRegex),
              '_400x400',
            );
          }
          if (effectiveOldUrl != null) {
            effectiveOldUrl = effectiveOldUrl.replaceFirst(
              RegExp(suffixRegex),
              '_400x400',
            );
          }
        }

        final bool shouldSave = _settings.saveAvatarHistory;
        final bool avatarUrlChanged = effectiveNewUrl != effectiveOldUrl;
        final bool localAvatarPathMissing =
            oldRelation == null ||
            oldRelation.avatarLocalPath == null ||
            oldRelation.avatarLocalPath!.isEmpty;

        if (shouldSave &&
            effectiveNewUrl != null &&
            effectiveNewUrl.isNotEmpty &&
            (avatarUrlChanged || localAvatarPathMissing)) {
          downloadTasks.add({
            'userId': userId,
            'newUrl': effectiveNewUrl,
            'oldUrl': oldAvatarUrl,
            'mediaType': MediaType.avatar,
          });
        }

        final String? newBannerUrl =
            (userJson['profile_banner_url'] as String?);
        final String? oldBannerUrl = oldRelation?.bannerUrl;

        final bool shouldSaveBanner = _settings.saveBannerHistory;
        final bool bannerUrlChanged = newBannerUrl != oldBannerUrl;
        final bool localBannerPathMissing =
            oldRelation == null ||
            oldRelation.bannerLocalPath == null ||
            oldRelation.bannerLocalPath == '' ||
            oldRelation.bannerLocalPath!.isEmpty;

        if (shouldSaveBanner &&
            newBannerUrl?.isNotEmpty == true &&
            (bannerUrlChanged || localBannerPathMissing)) {
          downloadTasks.add({
            'userId': userId,
            'newUrl': newBannerUrl,
            'oldUrl': oldBannerUrl,
            'mediaType': MediaType.banner,
          });
        }

        companionsToUpsert.add(
          FollowUsersCompanion(
            ownerId: Value(_ownerId),
            userId: Value(userId),
            name: Value(userJson['name'] as String?),
            screenName: Value(userJson['screen_name'] as String?),
            avatarUrl: Value(newAvatarUrl),
            bannerUrl: Value(newBannerUrl),
            bio: Value(userJson['description'] as String?),
            latestRawJson: Value(jsonEncode(userJson)),
            isFollower: Value(newFollowerIds.contains(userId)),
            isFollowing: Value(newFollowingIds.contains(userId)),
          ),
        );
      }

      final int totalToDownload = downloadTasks.length;
      _log(
        "Found $totalToDownload images to download (out of ${newIds.length} users checked).",
      );

      final group = FutureGroup<Map<String, dynamic>?>();
      final imageSemaphore = Semaphore(50);
      int completedDownloads = 0;
      final counterLock = Semaphore(1);

      for (final task in downloadTasks) {
        final userId = task['userId']! as String;
        final newUrl = task['newUrl']! as String;
        final oldUrl = task['oldUrl'] as String?;
        final mediaType = task['mediaType']! as MediaType;

        group.add(
          Future(() async {
            try {
              await imageSemaphore.acquire();
              final String? newLocalPath = await _imageService
                  .processMediaUpdate(
                    userId: userId,
                    ownerId: _ownerId,
                    mediaType: mediaType,
                    oldUrl: oldUrl,
                    newUrl: newUrl,
                    settings: _settings,
                  );

              if (newLocalPath != null) {
                await counterLock.acquire();
                completedDownloads++;
                _log(
                  "Image download progress: $completedDownloads / $totalToDownload",
                );
                counterLock.release();
                return {
                  'userId': userId,
                  'path': newLocalPath,
                  'type': mediaType,
                };
              }
            } catch (e) {
              _log("Warning: failed to process image for $userId: $e");
            } finally {
              imageSemaphore.release();
            }
            return null;
          }),
        );
      }

      _log("Starting concurrent download of $totalToDownload images");
      group.close();
      final downloadResults = await group.future;

      final Map<String, Map<MediaType, String>> downloadedPaths = {};
      for (final result in downloadResults) {
        if (result != null) {
          final String userId = result['userId'];
          final MediaType type = result['type'];
          final String path = result['path'];

          downloadedPaths.putIfAbsent(userId, () => {});
          downloadedPaths[userId]![type] = path;
        }
      }
      _log(
        "Finished downloading ${downloadResults.where((r) => r != null).length} images.",
      );

      final List<FollowUsersCompanion> finalCompanionsToUpsert = [];
      for (final companion in companionsToUpsert) {
        final userId = companion.userId.value;

        String? finalAvatarPath;
        final downloadedAvatar = downloadedPaths[userId]?[MediaType.avatar];
        if (downloadedAvatar != null) {
          finalAvatarPath = downloadedAvatar;
        } else if (oldRelationsMap.containsKey(userId) &&
            oldRelationsMap[userId]?.avatarUrl == companion.avatarUrl.value) {
          finalAvatarPath = oldRelationsMap[userId]?.avatarLocalPath;
        }

        String? finalBannerPath;
        final downloadedBanner = downloadedPaths[userId]?[MediaType.banner];
        if (downloadedBanner != null) {
          finalBannerPath = downloadedBanner;
        } else if (oldRelationsMap.containsKey(userId) &&
            oldRelationsMap[userId]?.bannerUrl == companion.bannerUrl.value) {
          finalBannerPath = oldRelationsMap[userId]?.bannerLocalPath;
        }

        finalCompanionsToUpsert.add(
          companion.copyWith(
            avatarLocalPath: finalAvatarPath == null
                ? const Value.absent()
                : Value(finalAvatarPath),
            bannerLocalPath: finalBannerPath == null
                ? const Value.absent()
                : Value(finalBannerPath),
          ),
        );
      }

      final List<ChangeReportsCompanion> reportCompanions = [];
      final now = DateTime.now();

      for (final addedId in addedIds) {
        reportCompanions.add(
          ChangeReportsCompanion(
            ownerId: Value(_ownerId),
            userId: Value(addedId),
            changeType: Value('new_followers_following'),
            timestamp: Value(now),
            userSnapshotJson: Value(jsonEncode(newUserJsons[addedId]!)),
          ),
        );
      }

      categorizedRemovals.forEach((userId, categoryKey) {
        reportCompanions.add(
          ChangeReportsCompanion(
            ownerId: Value(_ownerId),
            userId: Value(userId),
            changeType: Value(categoryKey),
            timestamp: Value(now),
            userSnapshotJson: Value(oldRelationsMap[userId]?.latestRawJson),
          ),
        );
      });

      for (final keptId in keptIds) {
        final oldRel = oldRelationsMap[keptId];
        final wasFollower = oldRel?.isFollower ?? false;
        final wasFollowing = oldRel?.isFollowing ?? false;
        final isNowFollower = newFollowerIds.contains(keptId);
        final isNowFollowing = newFollowingIds.contains(keptId);

        if (!wasFollower && wasFollowing && isNowFollower && isNowFollowing) {
          reportCompanions.add(
            ChangeReportsCompanion(
              ownerId: Value(_ownerId),
              userId: Value(keptId),
              changeType: Value('be_followed_back'),
              timestamp: Value(now),
              userSnapshotJson: Value(jsonEncode(newUserJsons[keptId]!)),
            ),
          );
        } else if (wasFollower &&
            wasFollowing &&
            isNowFollower &&
            !isNowFollowing) {
          reportCompanions.add(
            ChangeReportsCompanion(
              ownerId: Value(_ownerId),
              userId: Value(keptId),
              changeType: Value('oneway_unfollowed'),
              timestamp: Value(now),
              userSnapshotJson: Value(jsonEncode(newUserJsons[keptId]!)),
            ),
          );
        } else if (wasFollower &&
            wasFollowing &&
            !isNowFollower &&
            isNowFollowing) {
          reportCompanions.add(
            ChangeReportsCompanion(
              ownerId: Value(_ownerId),
              userId: Value(keptId),
              changeType: Value('oneway_unfollowed'),
              timestamp: Value(now),
              userSnapshotJson: Value(jsonEncode(newUserJsons[keptId]!)),
            ),
          );
        }
      }

      _log("Writing changes to database...");
      await _database.transaction(() async {
        if (removedIds.isNotEmpty) {
          await _database.deleteNetworkRelationships(
            _ownerId,
            removedIds.toList(),
          );
          _log(
            "Deleted ${removedIds.length} relationships from NetworkRelationships.",
          );
        }
        if (finalCompanionsToUpsert.isNotEmpty) {
          await _database.batchUpsertNetworkRelationships(
            finalCompanionsToUpsert,
          );
          _log(
            "Upserted ${finalCompanionsToUpsert.length} relationships into NetworkRelationships.",
          );
        }
        if (historyToInsert.isNotEmpty) {
          await _database.batchInsertFollowUsersHistory(historyToInsert);
          _log("Inserted ${historyToInsert.length} profile history records.");
        }
        await _database.replaceChangeReport(_ownerId, reportCompanions);
        _log(
          "Replaced ChangeReport with ${reportCompanions.length} new entries.",
        );
      });

      _log(
        "Analysis process completed successfully for account ID: $_ownerId.",
      );
    } catch (e, s) {
      _log(
        "!!! CRITICAL ERROR during analysis process for account ID: $_ownerId: $e",
      );
      _log("Stacktrace: $s");
      rethrow;
    }
  }
}
