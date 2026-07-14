import 'dart:math';
import 'package:autonitor/providers/graphql_queryid_provider.dart';
import 'package:autonitor/providers/x_client_transaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/twitter_api_service.dart';
import '../services/twitter_api_v1_service.dart';
import '../models/twitter_user.dart';
import '../utils/runid_generator.dart';

typedef LogCallback = void Function(String message);

// Data class to hold the results of the network fetch
class NetworkFetchResult {
  final Map<String, TwitterUser> uniqueUsers;
  final Set<String> followerIds;
  final Set<String> followingIds;

  NetworkFetchResult({
    required this.uniqueUsers,
    required this.followerIds,
    required this.followingIds,
  });
}

class NewNetworkDataFetcher {
  final TwitterApiService _apiServiceGql;
  final TwitterApiV1Service _apiServiceV1;
  final Ref _ref;
  final String _ownerId;
  final String _ownerCookie;
  final LogCallback _log;
  final String _apiRequestMode;
  final String? _cffiUrl;
  final String? _cffiApiKey;
  // [新增] 暂停回调
  final Future<void> Function() _checkPauseCallback;

  NewNetworkDataFetcher({
    required TwitterApiService apiServiceGql,
    required TwitterApiV1Service apiServiceV1,
    required Ref ref,
    required String ownerId,
    required String ownerCookie,
    required String apiRequestMode,
    String? cffiUrl,
    String? cffiApiKey,
    required LogCallback log,
    required Future<void> Function() checkPauseCallback, // [Init]
  }) : _apiServiceGql = apiServiceGql,
       _apiServiceV1 = apiServiceV1,
       _ref = ref,
       _ownerId = ownerId,
       _ownerCookie = ownerCookie,
       _log = log,
       _apiRequestMode = apiRequestMode,
       _cffiUrl = cffiUrl,
       _cffiApiKey = cffiApiKey,
       _checkPauseCallback = checkPauseCallback;

  Future<NetworkFetchResult> fetchAllNetworkData() async {
    final Map<String, TwitterUser> newUsers = {};
    final Set<String> newFollowerIds = {};
    final Set<String> newFollowingIds = {};
    final String currentRunId = generateRunId();

    // Fetch Followers (V1)
    _log("Fetching new followers list from API (V1)...");
    String? nextFollowerCursor;
    do {
      // [Check] 每次分页前检查暂停
      await _checkPauseCallback();

      final followerResult = await _apiServiceV1.getFollowers(
        _ownerId,
        _ownerCookie,
        cursor: nextFollowerCursor,
        apiRequestMode: _apiRequestMode,
        cffiUrl: _cffiUrl,
        cffiApiKey: _cffiApiKey,
      );
      for (var userJson in followerResult.users) {
        final userId =
            userJson['id_str'] as String? ?? userJson['id']?.toString();
        if (userId != null) {
          newFollowerIds.add(userId);
          newUsers[userId] = TwitterUser.fromV1(userJson, currentRunId);
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
      "Finished fetching followers. Total unique users so far: ${newUsers.length}",
    );

    // Fetch Following (GQL)
    _log("Fetching new following list from API (V1)...");
    String? nextFollowingCursor;
    do {
      // [Check] 每次分页前检查暂停
      await _checkPauseCallback();

      final followingResult = await _apiServiceV1.getFollowing(
        _ownerId,
        _ownerCookie,
        cursor: nextFollowingCursor,
        apiRequestMode: _apiRequestMode,
        cffiUrl: _cffiUrl,
        cffiApiKey: _cffiApiKey,
      );
      for (var userJson in followingResult.users) {
        final userId =
            userJson['id_str'] as String? ?? userJson['id']?.toString();
        if (userId != null) {
          newFollowingIds.add(userId);
          newUsers[userId] = TwitterUser.fromV1(userJson, currentRunId);
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
      "Finished fetching following. Total unique users so far: ${newUsers.length}",
    );

    List<String> allScreenNames = newUsers.values
        .map((user) => user.screenName ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    _log(
      "Fetched screen names. Starting to fetch profiles for ${allScreenNames.length} users...",
    );
    const int screenNamesChunkSize = 150;
    for (int i = 0; i < allScreenNames.length; i += screenNamesChunkSize) {
      int end = min(i + screenNamesChunkSize, allScreenNames.length);
      List<String> batchNames = allScreenNames.sublist(i, end);
      _log(
        'Prepared batch of ${batchNames.length} screen names (indices $i..${end - 1}).',
      );
      await _checkPauseCallback();
      final usersByScreenNamesQueryId = _ref
          .read(gqlQueryIdProvider.notifier)
          .getCurrentQueryIdForDisplay('UsersByScreenNames');
      final transactionId = await _ref
          .read(transactionIdProvider.notifier)
          .generate(
            method: "GET",
            url:
                "https://api.x.com/graphql/$usersByScreenNamesQueryId/UsersByScreenNames",
          );
      _log("Generated Transaction ID for UsersByScreenNames: $transactionId");
      Map<String, dynamic> userProfiles;
      try {
        userProfiles = await _apiServiceGql.getUsersByScreenNames(
          batchNames,
          _ownerCookie,
          usersByScreenNamesQueryId,
          transactionId!,
          apiRequestMode: _apiRequestMode,
          cffiUrl: _cffiUrl,
          cffiApiKey: _cffiApiKey,
        );
      } catch (e) {
        // 用户已在 V1 关系列表中解析；批量资料补全失败时保留该资料，
        // 避免单个失败批次导致整个同步任务中断。
        _log(
          'Failed to fetch profile batch ${i ~/ screenNamesChunkSize + 1}: '
          '$e. Keeping V1 user data for this batch.',
        );
        continue;
      }

      // UsersByScreenNames 的响应结构为 data.users -> [{ result: ... }]。
      // 使用完整的 GQL 用户资料覆盖前面从 V1 关系列表得到的简略资料。
      final usersData = userProfiles['data']?['users'];
      if (usersData is! List) {
        _log('UsersByScreenNames returned no user list for this batch.');
        continue;
      }

      int convertedCount = 0;
      for (final profileJson in usersData) {
        if (profileJson is! Map) {
          continue;
        }

        final user = TwitterUser.fromGraphQLUsersByScreenNames(
          Map<String, dynamic>.from(profileJson),
          currentRunId,
        );
        if (user.restId.isEmpty) {
          continue;
        }

        newUsers[user.restId] = user;
        convertedCount++;
      }
      _log(
        'Converted $convertedCount user profiles in batch '
        '${i ~/ screenNamesChunkSize + 1}.',
      );
    }

    return NetworkFetchResult(
      uniqueUsers: newUsers,
      followerIds: newFollowerIds,
      followingIds: newFollowingIds,
    );
  }
}
