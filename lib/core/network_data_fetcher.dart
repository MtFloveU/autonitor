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

class NetworkDataFetcher {
  final TwitterApiService _apiServiceGql;
  final TwitterApiV1Service _apiServiceV1;
  final Ref _ref;
  final String _ownerId;
  final String _ownerCookie;
  final LogCallback _log;

  NetworkDataFetcher({
    required TwitterApiService apiServiceGql,
    required TwitterApiV1Service apiServiceV1,
    required Ref ref,
    required String ownerId,
    required String ownerCookie,
    required LogCallback log,
  }) : _apiServiceGql = apiServiceGql,
       _apiServiceV1 = apiServiceV1,
       _ref = ref,
       _ownerId = ownerId,
       _ownerCookie = ownerCookie,
       _log = log;

  Future<NetworkFetchResult> fetchAllNetworkData() async {
    final Map<String, TwitterUser> newUsers = {};
    final Set<String> newFollowerIds = {};
    final Set<String> newFollowingIds = {};
    final String currentRunId = generateRunId();

    // Fetch Followers (V1)
    _log("Fetching new followers from API (V1)...");
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
    _log("Fetching new following from API (GQL)...");
    String? nextFollowingCursor = "-1";
    final followingQueryId = _ref
        .read(gqlQueryIdProvider.notifier)
        .getCurrentQueryIdForDisplay('Following');
    UserListResultGql followingResult;
    do {
      final transactionId = await _ref
          .read(transactionIdProvider.notifier)
          .generate(
            method: "GET",
            url: "https://api.x.com/graphql/$followingQueryId/Following",
          );
      _log("Generated Transaction ID for Following: $transactionId");

      followingResult = (await _apiServiceGql.getFollowing(
        _ownerId, // userId
        _ownerCookie, // cookie
        transactionId!,
        nextFollowingCursor!, // cursor
        followingQueryId,
      ));
      for (var userJson in followingResult.users) {
        final userId =
            userJson['result']?['rest_id']?.toString() ??
            userJson['result']?['id']?.toString();

        if (userId != null) {
          newFollowingIds.add(userId);
          newUsers[userId] = TwitterUser.fromGraphQL(userJson, currentRunId);
        }
      }
      nextFollowingCursor = followingResult.nextCursor;
      _log(
        "Fetched ${followingResult.users.length} following, next cursor: $nextFollowingCursor",
      );
    } while (nextFollowingCursor != null &&
        nextFollowingCursor.isNotEmpty &&
        !nextFollowingCursor.startsWith('0|'));
    _log(
      "Finished fetching following. Total unique users in combined list: ${newUsers.length}",
    );

    return NetworkFetchResult(
      uniqueUsers: newUsers,
      followerIds: newFollowerIds,
      followingIds: newFollowingIds,
    );
  }
}
