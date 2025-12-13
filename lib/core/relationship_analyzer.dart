import 'dart:convert';
import 'package:async/async.dart';
import 'package:async_locks/async_locks.dart';
import 'package:drift/drift.dart';
import 'network_data_fetcher.dart';
import '../services/database.dart';
import '../services/twitter_api_service.dart';
import '../repositories/account_repository.dart';

typedef LogCallback = void Function(String message);

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
  }) async {
    final Set<String> newIds = networkData.uniqueUsers.keys.toSet();
    final Set<String> oldIds = oldRelationsMap.values
        .where((u) => u.isFollower || u.isFollowing)
        .map((u) => u.userId)
        .toSet();

    final Set<String> addedIds = newIds.difference(oldIds);
    final Set<String> rawRemovedIds = oldIds.difference(newIds);
    final Set<String> keptIds = newIds.intersection(oldIds);

    // [New Logic] 过滤掉已经是 Suspended 或 Deactivated 的用户
    // 防止重复生成报告
    final Set<String> realRemovedIds = {};
    for (final id in rawRemovedIds) {
      final oldUser = oldRelationsMap[id];
      bool skip = false;

      if (oldUser?.latestRawJson != null) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(
            oldUser!.latestRawJson!,
          );
          final String? status = jsonMap['status'] as String?;

          if (status == 'suspended' || status == 'deactivated') {
            skip = true;
          }
        } catch (e) {
          _log("Error parsing JSON for user $id: $e");
        }
      }

      if (!skip) {
        realRemovedIds.add(id);
      }
    }

    _log(
      "Calculated differences: ${addedIds.length} added, "
      "${realRemovedIds.length} removed (filtered from ${rawRemovedIds.length}), "
      "${keptIds.length} kept.",
    );

    final List<FollowUsersHistoryCompanion> historyToInsert = [];

    return _processRemovalsAndGenerateReports(
      oldRelationsMap,
      networkData,
      addedIds,
      realRemovedIds,
      keptIds,
      historyToInsert,
    );
  }

  Future<Map<String, String>> _categorizeRemovals(
    Set<String> removedIds,
  ) async {
    _log("Processing ${removedIds.length} users to determine status...");
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
                category = 'normal_unfollowed';
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
            _log("Error fetching GraphQL for user $removedId: $e");
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
    final categorizedRemovals = await _categorizeRemovals(removedIds);
    final Set<String> potentialRestrictedIds = {};

    for (final keptId in keptIds) {
      final oldRel = oldRelationsMap[keptId];
      final newUser = networkData.uniqueUsers[keptId]!;

      final wasFollower = oldRel?.isFollower ?? false;
      final isNowFollower = networkData.followerIds.contains(keptId);

      if (wasFollower && !isNowFollower) {
        if (newUser.followingCount == 0 && newUser.followersCount > 0) {
          potentialRestrictedIds.add(keptId);
        }
      }
    }

    final restrictedChecks = await _categorizeRemovals(potentialRestrictedIds);

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
            jsonEncode(networkData.uniqueUsers[addedId]!.toJson()),
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

      final bool relationshipChanged =
          (wasFollower != isNowFollower) || (wasFollowing != isNowFollowing);

      String? changeType;

      String oldStatus = 'normal';
      String oldKeptStatus = 'normal';
      if (oldRel?.latestRawJson != null) {
        try {
          final Map<String, dynamic> oldJson = jsonDecode(
            oldRel!.latestRawJson!,
          );
          oldStatus = oldJson['status'] as String? ?? 'normal';
          oldKeptStatus = oldJson['kept_ids_status'] as String? ?? 'normal';
        } catch (_) {}
      }

      final bool isRecovered =
          (oldStatus != 'normal' || oldKeptStatus != 'normal') &&
          relationshipChanged;

      if (isRecovered) {
        changeType = 'recovered';
      } else if (!relationshipChanged &&
          (oldStatus != 'normal' || oldKeptStatus != 'normal')) {
        final statusToPreserve = oldKeptStatus != 'normal'
            ? oldKeptStatus
            : oldStatus;
        keptStatusUpdates[keptId] = statusToPreserve;
      } else if (restrictedChecks.containsKey(keptId) &&
          restrictedChecks[keptId] == 'temporarily_restricted') {
        changeType = 'temporarily_restricted';
      } else if (!wasFollower &&
          wasFollowing &&
          isNowFollower &&
          isNowFollowing) {
        changeType = 'be_followed_back';
      } else if (wasFollower &&
          wasFollowing &&
          isNowFollower &&
          !isNowFollowing) {
        changeType = 'oneway_unfollowed';
      } else if (wasFollower &&
          wasFollowing &&
          !isNowFollower &&
          isNowFollowing) {
        changeType = 'oneway_unfollowed';
      }

      if (changeType != null) {
        reportCompanions.add(
          ChangeReportsCompanion(
            ownerId: Value(_ownerId),
            userId: Value(keptId),
            changeType: Value(changeType),
            timestamp: Value(now),
            userSnapshotJson: Value(null),
          ),
        );

        if (changeType != 'be_followed_back' &&
            changeType != 'new_followers_following') {
          keptStatusUpdates[keptId] = changeType;
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
      historyToInsert: historyToInsert,
    );
  }
}
