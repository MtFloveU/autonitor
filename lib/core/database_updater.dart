import 'dart:convert';
import 'media_processor.dart';
import 'network_data_fetcher.dart';
import 'relationship_analyzer.dart';
import 'package:drift/drift.dart';
import '../services/database.dart';
import '../utils/diff_utils.dart';
import '../services/image_history_service.dart'; // For MediaType enum

typedef LogCallback = void Function(String message);

class DatabaseUpdater {
  final AppDatabase _database;
  final LogCallback _log;

  DatabaseUpdater({
    required AppDatabase database,
    required LogCallback log,
  })  : _database = database,
        _log = log;

  Future<void> saveChanges({
    required String ownerId,
    required NetworkFetchResult networkData,
    required RelationshipAnalysisResult analysisResult,
    required MediaProcessingResult mediaResult,
    required Map<String, FollowUser> oldRelationsMap,
  }) async {
    // 1. Prepare JSON History Diffs
    final List<FollowUsersHistoryCompanion> historyToInsert = [];
    for (final userId in analysisResult.keptIds) {
      final oldRelation = oldRelationsMap[userId];
      final userJson = networkData.uniqueUserJsons[userId];

      if (oldRelation != null && userJson != null) {
        final oldJsonString = oldRelation.latestRawJson;
        final newJsonString = jsonEncode(userJson);
        final diffString = calculateReverseDiff(newJsonString, oldJsonString);
        if (diffString != null && diffString.isNotEmpty) {
          historyToInsert.add(
            FollowUsersHistoryCompanion(
              ownerId: Value(ownerId),
              userId: Value(userId),
              reverseDiffJson: Value(diffString),
              timestamp: Value(DateTime.now()),
            ),
          );
        }
      }
    }

    // 2. Prepare User Companions for Upsert
    final List<FollowUsersCompanion> companionsToUpsert = [];
    for (final userId in networkData.uniqueUserJsons.keys) {
      final userJson = networkData.uniqueUserJsons[userId]!;
      companionsToUpsert.add(
        FollowUsersCompanion(
          ownerId: Value(ownerId),
          userId: Value(userId),
          name: Value(userJson['name'] as String?),
          screenName: Value(userJson['screen_name'] as String?),
          avatarUrl: Value(userJson['profile_image_url_https'] as String?),
          bannerUrl: Value(userJson['profile_banner_url'] as String?),
          bio: Value(userJson['description'] as String?),
          latestRawJson: Value(jsonEncode(userJson)),
          isFollower: Value(networkData.followerIds.contains(userId)),
          isFollowing: Value(networkData.followingIds.contains(userId)),
        ),
      );
    }

    // 3. Merge Downloaded Paths into Companions
    final List<FollowUsersCompanion> finalCompanionsToUpsert = [];
    for (final companion in companionsToUpsert) {
      final userId = companion.userId.value;
      final oldRelation = oldRelationsMap[userId];

      // Check downloaded paths
      final downloadedAvatar =
          mediaResult.downloadedPaths[userId]?[MediaType.avatar];
      final downloadedBanner =
          mediaResult.downloadedPaths[userId]?[MediaType.banner];

      String? finalAvatarPath = downloadedAvatar;
      if (finalAvatarPath == null &&
          oldRelation?.avatarUrl == companion.avatarUrl.value) {
        // No new download, and URL is same, keep old path
        finalAvatarPath = oldRelation?.avatarLocalPath;
      }

      String? finalBannerPath = downloadedBanner;
      if (finalBannerPath == null &&
          oldRelation?.bannerUrl == companion.bannerUrl.value) {
        // No new download, and URL is same, keep old path
        finalBannerPath = oldRelation?.bannerLocalPath;
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

    // 4. Run Database Transaction
    await _database.transaction(() async {
      if (analysisResult.removedIds.isNotEmpty) {
        await _database.deleteNetworkRelationships(
          ownerId,
          analysisResult.removedIds.toList(),
        );
        _log(
          "Deleted ${analysisResult.removedIds.length} relationships from NetworkRelationships.",
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
      await _database.replaceChangeReport(ownerId, analysisResult.reports);
      _log(
        "Replaced ChangeReport with ${analysisResult.reports.length} new entries.",
      );
    });
  }
}