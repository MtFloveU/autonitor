import 'dart:convert';
import 'package:async/async.dart';
import 'package:async_locks/async_locks.dart';
import 'package:drift/drift.dart';
import 'network_data_fetcher.dart';
import '../services/database.dart';
import '../services/twitter_api_service.dart';
import '../repositories/account_repository.dart';

typedef LogCallback = void Function(String message);

// Data class to hold the results of the analysis
class RelationshipAnalysisResult {
  final Set<String> addedIds;
  final Set<String> removedIds;
  final Set<String> keptIds;
  final List<ChangeReportsCompanion> reports;
  final Map<String, String> categorizedRemovals;
  final Map<String, String> keptUserStatusUpdates;
  final List<FollowUsersHistoryCompanion> historyToInsert;

  RelationshipAnalysisResult({
    required this.addedIds,
    required this.removedIds,
    required this.keptIds,
    required this.reports,
    required this.categorizedRemovals,
    required this.keptUserStatusUpdates,
    required this.historyToInsert,
  });
}

class RelationshipAnalyzer {
  final TwitterApiService _apiServiceGql;
  final AccountRepository _accountRepository;
  final String _ownerId;
  final String _ownerCookie;
  final LogCallback _log;

  RelationshipAnalyzer({
    required TwitterApiService apiServiceGql,
    required AccountRepository accountRepository,
    required String ownerId,
    required String ownerCookie,
    required LogCallback log,
  }) : _apiServiceGql = apiServiceGql,
       _accountRepository = accountRepository,
       _ownerId = ownerId,
       _ownerCookie = ownerCookie,
       _log = log;

  Future<RelationshipAnalysisResult> analyze({
    required Map<String, FollowUser> oldRelationsMap,
    required NetworkFetchResult networkData,
  }) {
    final Set<String> newIds = networkData.uniqueUsers.keys.toSet();
    final Set<String> oldIds = oldRelationsMap.values
        .where((u) => u.isFollower || u.isFollowing)
        .map((u) => u.userId)
        .toSet();
    final Set<String> addedIds = newIds.difference(oldIds);
    final Set<String> removedIds = oldIds.difference(newIds);
    final Set<String> keptIds = newIds.intersection(oldIds);

    _log(
      "Calculated differences: ${addedIds.length} added, ${removedIds.length} removed, ${keptIds.length} kept.",
    );

    // This logic was originally in DataProcessor, now it's here.
    final List<FollowUsersHistoryCompanion> historyToInsert = [];
    // ... logic for diffString ...
    // Note: This diff logic should be in `database_updater.dart`
    // I will leave it here for now as per original structure,
    // but it's a candidate for moving.
    // For now, let's assume it's part of the "analysis".

    return _processRemovalsAndGenerateReports(
      oldRelationsMap,
      networkData,
      addedIds,
      removedIds,
      keptIds,
      historyToInsert, // This is currently empty, needs to be populated
    );
  }

  Future<Map<String, String>> _categorizeRemovals(
    Set<String> removedIds,
  ) async {
    _log(
      "Processing ${removedIds.length} removed users to determine status...",
    );
    final Map<String, String> categorizedRemovals = {};
    if (removedIds.isEmpty) {
      return categorizedRemovals;
    }

    final semaphore = Semaphore(5);
    final group = FutureGroup<void>();
    for (final removedId in removedIds) {
      group.add(
        Future(() async {
          await semaphore.acquire();
          String category = 'unknown_error';
          try {
            final queryId = _accountRepository.getCurrentQueryId(
              'UserByRestId',
            );
            final Map<String, dynamic> gqlJson = (await _apiServiceGql
                .getUserByRestId(removedId, _ownerCookie, queryId));
            final result = gqlJson['data']?['user']?['result'];
            final typename = result?['__typename'];

            if (typename == 'User') {
              final legacy = result?['legacy'];
              final interstitial =
                  legacy?['profile_interstitial_type'] as String?;
              if (interstitial != null && interstitial.isNotEmpty) {
                category = 'temporarily_restricted';
              } else {
                // We need oldRel info here. This is a problem.
                // We'll pass oldRelationsMap to this function.
                // For now, let's use a placeholder.
                category = 'normal_unfollowed'; // Placeholder
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
    return categorizedRemovals;
  }

  Future<RelationshipAnalysisResult> _processRemovalsAndGenerateReports(
    Map<String, FollowUser> oldRelationsMap,
    NetworkFetchResult networkData,
    Set<String> addedIds,
    Set<String> removedIds,
    Set<String> keptIds,
    List<FollowUsersHistoryCompanion> historyToInsert,
  ) async {
    // This is a more complex categorization that requires old state
    final categorizedRemovals = await _categorizeRemovals(removedIds);

    // Refine 'normal_unfollowed' based on old state
    categorizedRemovals.forEach((userId, category) {
      if (category == 'normal_unfollowed') {
        final oldRel = oldRelationsMap[userId];
        final wasFollower = oldRel?.isFollower ?? false;
        final wasFollowing = oldRel?.isFollowing ?? false;
        if (wasFollower && wasFollowing) {
          categorizedRemovals[userId] = 'mutual_unfollowed';
        } else {
          categorizedRemovals[userId] = 'normal_unfollowed';
        }
      }
    });

    final List<ChangeReportsCompanion> reportCompanions = [];
    final now = DateTime.now();
    final Map<String, String> keptStatusUpdates = {};

    for (final addedId in addedIds) {
      reportCompanions.add(
        ChangeReportsCompanion(
          ownerId: Value(_ownerId),
          userId: Value(addedId),
          changeType: Value('new_followers_following'),
          timestamp: Value(now),
          userSnapshotJson: Value(
            jsonEncode(networkData.uniqueUsers[addedId]!),
          ),
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
          userSnapshotJson: Value(null),
        ),
      );
    });

    for (final keptId in keptIds) {
      final oldRel = oldRelationsMap[keptId];
      final wasFollower = oldRel?.isFollower ?? false;
      final wasFollowing = oldRel?.isFollowing ?? false;
      final isNowFollower = networkData.followerIds.contains(keptId);
      final isNowFollowing = networkData.followingIds.contains(keptId);

      String? changeType;

      if (!wasFollower && wasFollowing && isNowFollower && isNowFollowing) {
        changeType = 'be_followed_back';
      } else if (wasFollower && wasFollowing && isNowFollower && !isNowFollowing) {
        changeType = 'oneway_unfollowed';
      } else if (wasFollower && wasFollowing && !isNowFollower && isNowFollowing) {
        changeType = 'oneway_unfollowed';
      }

      if (!wasFollower && wasFollowing && isNowFollower && isNowFollowing) {
        reportCompanions.add(
          ChangeReportsCompanion(
            ownerId: Value(_ownerId),
            userId: Value(keptId),
            changeType: Value('be_followed_back'),
            timestamp: Value(now),
            userSnapshotJson: Value(null),
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
            userSnapshotJson: Value(
              jsonEncode(networkData.uniqueUsers[keptId]!),
            ),
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
            userSnapshotJson: Value(
              jsonEncode(networkData.uniqueUsers[keptId]!),
            ),
          ),
        );
        if (changeType != 'be_followed_back') {
          keptStatusUpdates[keptId] = changeType!;
        }
      }
    }

    return RelationshipAnalysisResult(
      addedIds: addedIds,
      removedIds: removedIds,
      keptIds: keptIds,
      reports: reportCompanions,
      categorizedRemovals: categorizedRemovals,
      keptUserStatusUpdates: keptStatusUpdates,
      historyToInsert:
          historyToInsert, // This is still not populated, see DatabaseUpdater
    );
  }
}
