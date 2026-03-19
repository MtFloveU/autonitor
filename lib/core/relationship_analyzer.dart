import 'dart:convert';
import 'package:autonitor/models/twitter_user.dart';
import 'package:autonitor/services/x_client_transaction_service.dart';
import 'package:drift/drift.dart';
import 'network_data_fetcher.dart';
import '../services/database.dart';
import '../services/twitter_api_service.dart';
import '../repositories/account_repository.dart';

const String kChangeTypeProfileUpdate = 'profile_update';
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
  final Future<void> Function() _checkPauseCallback;
  final XClientTransactionService _xctService;

  RelationshipAnalyzer({
    required TwitterApiService apiServiceGql,
    required AccountRepository accountRepository,
    required String ownerId,
    required String ownerCookie,
    required LogCallback log,
    required Future<void> Function() checkPauseCallback,
    required XClientTransactionService xctService,
  }) : _apiServiceGql = apiServiceGql,
       _accountRepository = accountRepository,
       _ownerId = ownerId,
       _ownerCookie = ownerCookie,
       _log = log,
       _checkPauseCallback = checkPauseCallback,
       _xctService = xctService;

  Future<RelationshipAnalysisResult> analyze({
    required Map<String, FollowUser> oldRelationsMap,
    required NetworkFetchResult networkData,
  }) async {
    await _checkPauseCallback();

    final Set<String> newIds = networkData.uniqueUsers.keys.toSet();
    final Set<String> oldIds = oldRelationsMap.keys.toSet();
    final Set<String> addedIds = newIds.difference(oldIds);
    final Set<String> rawRemovedIds = oldIds.difference(newIds);
    final Set<String> keptIds = newIds.intersection(oldIds);
    final Set<String> realRemovedIds = {};

    int processedCount = 0;
    for (final id in rawRemovedIds) {
      if (processedCount++ % 50 == 0) await _checkPauseCallback();
      final oldUser = oldRelationsMap[id];
      bool skip =
          (oldUser != null && !oldUser.isFollower && !oldUser.isFollowing);

      if (!skip && oldUser?.latestRawJson != null) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(
            oldUser!.latestRawJson!,
          );
          final String? status = jsonMap['status'] as String?;
          if (status == 'suspended' || status == 'deactivated') skip = true;
        } catch (e) {
          _log("Error parsing JSON for user $id: $e");
        }
      }
      if (!skip) realRemovedIds.add(id);
    }

    _log(
      "Differences: ${addedIds.length} added, ${realRemovedIds.length} removed, ${keptIds.length} kept.",
    );

    return _processRemovalsAndGenerateReports(
      oldRelationsMap,
      networkData,
      addedIds,
      realRemovedIds,
      keptIds,
      [],
    );
  }

  Future<Map<String, String>> _categorizeRemovals(Set<String> ids) async {
    final Map<String, String> results = {};
    if (ids.isEmpty) return results;

    // 如果只有一个 ID，使用单体查询方法
    if (ids.length == 1) {
      final String removedId = ids.first;
      _log("Fetching status for single user $removedId...");
      await _checkPauseCallback();
      try {
        final queryId = _accountRepository.getCurrentQueryId('UserByRestId');
        final Map<String, dynamic> gqlJson = await _apiServiceGql
            .getUserByRestId(removedId, _ownerCookie, queryId);
        final result = gqlJson['data']?['user']?['result'];
        final typename = result?['__typename'];

        if (typename == 'User') {
          final legacy = result['legacy'];
          final interstitial = legacy?['profile_interstitial_type'] as String?;
          results[removedId] = (interstitial != null && interstitial.isNotEmpty)
              ? 'temporarily_restricted'
              : 'normal_unfollowed';
        } else if (typename == 'UserUnavailable') {
          results[removedId] = 'suspended';
        } else if (gqlJson['data']?['user'] == null ||
            (gqlJson['data']?['user'] is Map &&
                (gqlJson['data']['user'] as Map).isEmpty)) {
          results[removedId] = 'deactivated';
        } else {
          results[removedId] = 'other_reasons';
        }
      } catch (e) {
        _log("Error fetching single user $removedId: $e");
        results[removedId] = 'unknown_error';
      }
      return results;
    }

    // 多个 ID 使用批量查询
    _log("Batch fetching status for ${ids.length} users...");
    await _checkPauseCallback();
    try {
      final queryId = _accountRepository.getCurrentQueryId('UsersByRestIds');
      final transactionId = _xctService.generateTransactionId(
        method: "GET",
        url: 'https://api.x.com/graphql/$queryId/UsersByRestIds',
      );
      final List<String> idList = ids.toList();
      final Map<String, dynamic> gqlJson = await _apiServiceGql
          .getUsersByRestIds(idList, _ownerCookie, queryId, transactionId);
      final List<dynamic>? usersData = gqlJson['data']?['users'];

      for (int i = 0; i < idList.length; i++) {
        final String currentId = idList[i];
        dynamic result;
        if (usersData != null && i < usersData.length) {
          result = usersData[i]?['result'];
        }

        if (result == null) {
          results[currentId] = 'deactivated';
          continue;
        }

        final String? typename = result['__typename'];
        if (typename == 'User') {
          final legacy = result['legacy'];
          final interstitial = legacy?['profile_interstitial_type'] as String?;
          results[currentId] = (interstitial != null && interstitial.isNotEmpty)
              ? 'temporarily_restricted'
              : 'normal_unfollowed';
        } else if (typename == 'UserUnavailable') {
          results[currentId] = 'suspended';
        } else {
          results[currentId] = 'unknown_gql_response';
        }
      }
    } catch (e) {
      _log("Batch fetch error: $e");
      for (final id in ids) {
        results[id] = 'unknown_error';
      }
    }
    return results;
  }

  Future<RelationshipAnalysisResult> _processRemovalsAndGenerateReports(
    Map<String, FollowUser> oldRelationsMap,
    NetworkFetchResult networkData,
    Set<String> addedIds,
    Set<String> removedIds,
    Set<String> keptIds,
    List<FollowUsersHistoryCompanion> historyToInsert,
  ) async {
    final List<ChangeReportsCompanion> reportCompanions = [];
    final now = DateTime.now();

    final categorizedRemovals = await _categorizeRemovals(removedIds);
    for (final id in removedIds) {
      categorizedRemovals.putIfAbsent(id, () => 'other_reasons');
    }

    final Set<String> potentialRestrictedIds = {};
    int loopCounter = 0;
    for (final keptId in keptIds) {
      if (loopCounter++ % 100 == 0) await _checkPauseCallback();

      final oldRel = oldRelationsMap[keptId];
      final newUser = networkData.uniqueUsers[keptId]!;
      final wasFollower = oldRel?.isFollower ?? false;
      final isNowFollower = networkData.followerIds.contains(keptId);

      if (oldRel?.latestRawJson != null) {
        try {
          final oldUser = TwitterUser.fromJson(
            jsonDecode(oldRel!.latestRawJson!),
          );
          final Map<String, Map<String, String?>> diffs = {};
          void check(String f, String? o, String? n) {
            if (o?.trim() != n?.trim()) {
              diffs[f] = {'old': o?.trim(), 'new': n?.trim()};
            }
          }

          check('name', oldUser.name, newUser.name);
          check('screen_name', oldUser.screenName, newUser.screenName);
          check('bio', oldUser.bio, newUser.bio);
          check('location', oldUser.location, newUser.location);
          check('link', oldUser.link, newUser.link);
          if (oldUser.avatarUrl != newUser.avatarUrl) {
            diffs['avatar'] = {
              'old': oldUser.avatarUrl,
              'new': newUser.avatarUrl,
            };
          }
          if (oldUser.bannerUrl != newUser.bannerUrl) {
            diffs['banner'] = {
              'old': oldUser.bannerUrl,
              'new': newUser.bannerUrl,
            };
          }

          if (diffs.isNotEmpty) {
            reportCompanions.add(
              ChangeReportsCompanion(
                ownerId: Value(_ownerId),
                userId: Value(keptId),
                changeType: Value(kChangeTypeProfileUpdate),
                timestamp: Value(now),
                userSnapshotJson: Value(
                  jsonEncode({'diff': diffs, 'user': newUser.toJson()}),
                ),
              ),
            );
          }
        } catch (e) {
          _log("Profile compare error $keptId: $e");
        }
      }

      if (wasFollower &&
          !isNowFollower &&
          newUser.followingCount == 0 &&
          newUser.followersCount > 0) {
        potentialRestrictedIds.add(keptId);
      }
    }

    final restrictedChecks = await _categorizeRemovals(potentialRestrictedIds);

    categorizedRemovals.forEach((userId, category) {
      if (category == 'normal_unfollowed') {
        final rel = oldRelationsMap[userId];
        categorizedRemovals[userId] =
            (rel?.isFollower == true && rel?.isFollowing == true)
            ? 'mutual_unfollowed'
            : 'normal_unfollowed';
      }
    });

    for (final id in addedIds) {
      reportCompanions.add(
        ChangeReportsCompanion(
          ownerId: Value(_ownerId),
          userId: Value(id),
          changeType: Value('new_followers_following'),
          timestamp: Value(now),
          userSnapshotJson: Value(
            jsonEncode(networkData.uniqueUsers[id]!.toJson()),
          ),
        ),
      );
    }

    categorizedRemovals.forEach((uid, cat) {
      reportCompanions.add(
        ChangeReportsCompanion(
          ownerId: Value(_ownerId),
          userId: Value(uid),
          changeType: Value(cat),
          timestamp: Value(now),
          userSnapshotJson: const Value(null),
        ),
      );
    });

    final Map<String, String> keptStatusUpdates = {};
    for (final keptId in keptIds) {
      final oldRel = oldRelationsMap[keptId];
      final wasFollower = oldRel?.isFollower ?? false;
      final wasFollowing = oldRel?.isFollowing ?? false;
      final isNowFollower = networkData.followerIds.contains(keptId);
      final isNowFollowing = networkData.followingIds.contains(keptId);
      final bool relationshipChanged =
          (wasFollower != isNowFollower) || (wasFollowing != isNowFollowing);

      String oldStatus = 'normal';
      String oldKeptStatus = 'normal';
      if (oldRel?.latestRawJson != null) {
        try {
          final Map<String, dynamic> j = jsonDecode(oldRel!.latestRawJson!);
          oldStatus = j['status'] ?? 'normal';
          oldKeptStatus = j['kept_ids_status'] ?? 'normal';
        } catch (_) {}
      }

      String? changeType;
      if ((oldStatus != 'normal' || oldKeptStatus != 'normal') &&
          relationshipChanged) {
        changeType = 'recovered';
      } else if (!relationshipChanged &&
          (oldStatus != 'normal' || oldKeptStatus != 'normal')) {
        keptStatusUpdates[keptId] = oldKeptStatus != 'normal'
            ? oldKeptStatus
            : oldStatus;
      } else if (restrictedChecks[keptId] == 'temporarily_restricted') {
        changeType = 'temporarily_restricted';
      } else if (!wasFollower &&
          wasFollowing &&
          isNowFollower &&
          isNowFollowing) {
        changeType = 'be_followed_back';
      } else if (relationshipChanged &&
          wasFollower &&
          wasFollowing &&
          (isNowFollower != isNowFollowing)) {
        changeType = 'oneway_unfollowed';
      }

      if (changeType != null) {
        reportCompanions.add(
          ChangeReportsCompanion(
            ownerId: Value(_ownerId),
            userId: Value(keptId),
            changeType: Value(changeType),
            timestamp: Value(now),
            userSnapshotJson: const Value(null),
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
