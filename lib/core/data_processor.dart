import 'dart:convert';
import 'package:async/async.dart';
import 'package:drift/drift.dart';
import '../models/account.dart';
import '../services/database.dart';
import '../services/twitter_api_service.dart';
import '../services/twitter_api_v1_service.dart';
import '../utils/diff_utils.dart';
import 'package:async_locks/async_locks.dart';

typedef LogCallback = void Function(String message);

class DataProcessor {
  final AppDatabase _database;
  final TwitterApiService _apiServiceGql;
  final TwitterApiV1Service _apiServiceV1;
  final String _ownerId;
  final String _ownerCookie;
  final LogCallback _log;

  DataProcessor({
    required AppDatabase database,
    required TwitterApiService apiServiceGql,
    required TwitterApiV1Service apiServiceV1,
    required Account ownerAccount,
    required LogCallback logCallback,
  }) : _database = database,
       _apiServiceGql = apiServiceGql,
       _apiServiceV1 = apiServiceV1,
       _ownerId = ownerAccount.id,
       _ownerCookie = ownerAccount.cookie,
       _log = logCallback;

  Future<void> runFullProcess() async {
    _log("Starting analysis process for account ID: $_ownerId...");

    try {
      _log("Fetching old relationships from database...");
      final List<FollowUser> oldRelationsList = await _database
          .getNetworkRelationships(_ownerId);
      final Map<String, FollowUser> oldRelationsMap = {
        for (var relation in oldRelationsList) relation.userId: relation,
      };
      _log("Found ${oldRelationsMap.length} existing relationships.");

      _log("Fetching new followers list from API...");
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
      _log("Fetching new following list from API...");

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
                    // --- Final Removed Logic ---
                    final oldRel = oldRelationsMap[removedId];
                    final wasFollower = oldRel?.isFollower ?? false;
                    final wasFollowing = oldRel?.isFollowing ?? false;

                    if (wasFollower && wasFollowing)
                      category = 'mutual_unfollowed'; // Old: Mutual -> Gone
                    else if (wasFollower)
                      category =
                          'normal_unfollowed'; // Old: They Followed -> Gone (They unfollowed)
                    else if (wasFollowing)
                      category =
                          'normal_unfollowed'; // Old: You Followed -> Gone (You unfollowed) <-- CHANGE
                    else
                      category = 'unknown_removed_state';
                    // --- Final End ---
                  }
                } else if (typename == 'UserUnavailable') {
                  category = 'suspended';
                } else if (gqlJson['data']?['user'] == null ||
                    (gqlJson['data']?['user'] is Map &&
                        gqlJson['data']['user'].isEmpty)) {
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

      _log("Calculating profile diffs for ${keptIds.length} kept users...");
      final List<FollowUsersHistoryCompanion> historyToInsert = [];
      for (final keptId in keptIds) {
        final newJsonMap = newUserJsons[keptId];
        final oldJsonString = oldRelationsMap[keptId]?.latestRawJson;
        final newJsonString = newJsonMap != null
            ? jsonEncode(newJsonMap)
            : null;
        final diffString = calculateReverseDiff(newJsonString, oldJsonString);
        if (diffString != null && diffString.isNotEmpty) {
          historyToInsert.add(
            FollowUsersHistoryCompanion(
              ownerId: Value(_ownerId),
              userId: Value(keptId),
              reverseDiffJson: Value(diffString),
              timestamp: Value(DateTime.now()),
            ),
          );
        }
      }
      _log("Found ${historyToInsert.length} profile changes among kept users.");

      _log("Preparing data for database update...");
      final List<FollowUsersCompanion> companionsToUpsert = [];
      for (final userId in newIds) {
        final userJson = newUserJsons[userId]!;
        companionsToUpsert.add(
          FollowUsersCompanion(
            ownerId: Value(_ownerId),
            userId: Value(userId),
            name: Value(userJson['name'] as String?),
            screenName: Value(userJson['screen_name'] as String?),
            avatarUrl: Value(userJson['profile_image_url_https'] as String?),
            bio: Value(userJson['description'] as String?),
            latestRawJson: Value(jsonEncode(userJson)),
            isFollower: Value(newFollowerIds.contains(userId)),
            isFollowing: Value(newFollowingIds.contains(userId)),
            avatarLocalPath: const Value.absent(),
          ),
        );
      }

      final List<ChangeReportsCompanion> reportCompanions = [];
      final now = DateTime.now();

      // --- Final Added Logic ---
      for (final addedId in addedIds) {
        reportCompanions.add(
          ChangeReportsCompanion(
            ownerId: Value(_ownerId),
            userId: Value(addedId),
            changeType: Value(
              'new_followers_following',
            ), // <-- Unified type for all added
            timestamp: Value(now),
          ),
        );
      }
      // --- Final End ---

      // Removals (using categorized results from above)
      categorizedRemovals.forEach((userId, categoryKey) {
        reportCompanions.add(
          ChangeReportsCompanion(
            ownerId: Value(_ownerId),
            userId: Value(userId),
            changeType: Value(categoryKey),
            timestamp: Value(now),
          ),
        );
      });

      // --- Final Kept Logic for state changes ---
      for (final keptId in keptIds) {
        final oldRel = oldRelationsMap[keptId];
        final wasFollower = oldRel?.isFollower ?? false;
        final wasFollowing = oldRel?.isFollowing ?? false;
        final isNowFollower = newFollowerIds.contains(keptId);
        final isNowFollowing = newFollowingIds.contains(keptId);

        // Check for 'be_followed_back'
        if (!wasFollower && wasFollowing && isNowFollower && isNowFollowing) {
          // Old: You followed only -> New: Mutual
          reportCompanions.add(
            ChangeReportsCompanion(
              ownerId: Value(_ownerId),
              userId: Value(keptId),
              changeType: Value('be_followed_back'),
              timestamp: Value(now),
            ),
          );
        }
        // Check for 'oneway_unfollowed' (Mutual -> Single)
        else if (wasFollower &&
            wasFollowing &&
            isNowFollower &&
            !isNowFollowing) {
          // Old: Mutual -> New: They follow only (You unfollowed)
          reportCompanions.add(
            ChangeReportsCompanion(
              ownerId: Value(_ownerId),
              userId: Value(keptId),
              changeType: Value('oneway_unfollowed'),
              timestamp: Value(now),
            ),
          );
        } else if (wasFollower &&
            wasFollowing &&
            !isNowFollower &&
            isNowFollowing) {
          // Old: Mutual -> New: You follow only (They unfollowed)
          reportCompanions.add(
            ChangeReportsCompanion(
              ownerId: Value(_ownerId),
              userId: Value(keptId),
              changeType: Value('oneway_unfollowed'),
              timestamp: Value(now),
            ),
          );
        }
        // Add other state change detections here if needed (e.g., normal_unfollowed for kept users?)
      }
      // --- Final End ---

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
        if (companionsToUpsert.isNotEmpty) {
          await _database.batchUpsertNetworkRelationships(companionsToUpsert);
          _log(
            "Upserted ${companionsToUpsert.length} relationships into NetworkRelationships.",
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
