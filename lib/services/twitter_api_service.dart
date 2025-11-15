import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'log_service.dart';

final twitterApiServiceProvider = Provider((ref) => TwitterApiService());

class UserListResultGql {
  final List<Map<String, dynamic>> users;
  final String? nextCursor;
  UserListResultGql({required this.users, this.nextCursor});
}

class TwitterApiService {
  final Dio _dio;

  TwitterApiService() : _dio = Dio();

  String? _parseCsrfToken(String cookie) {
    try {
      final parts = cookie.split(';');
      final csrfPart = parts.firstWhere(
        (part) => part.trim().startsWith('ct0='),
        orElse: () => '',
      );
      if (csrfPart.isNotEmpty) {
        final token = csrfPart.split('=')[1].trim();
        return token.isNotEmpty ? token : null;
      }
    } catch (e, s) {
      logger.e("Parsing the ct0 token failed: $e", error: e, stackTrace: s);
    }
    return null;
  }

  Future<Map<String, dynamic>> getUserByRestId(
    String userId,
    String cookie,
    String queryId,
  ) async {
    final csrfToken = _parseCsrfToken(cookie);
    if (csrfToken == null) {
      throw Exception("Unable to parse x-csrf-token (ct0) from Cookie");
    }

    final variables = {"userId": userId};
    final features = {
      "hidden_profile_subscriptions_enabled": true,
      "responsive_web_graphql_exclude_directive_enabled": true,
      "verified_phone_label_enabled": false,
      "highlights_tweets_tab_ui_enabled": true,
      "creator_subscriptions_tweet_preview_api_enabled": true,
      "responsive_web_graphql_skip_user_profile_image_extensions_enabled":
          false,
      "responsive_web_graphql_timeline_navigation_enabled": true,
      "rweb_tipjar_consumption_enabled": false,
      "subscriptions_feature_can_gift_premium": false,
      "payments_enabled": false,
      "responsive_web_twitter_article_notes_tab_enabled": false,
      "profile_label_improvements_pcf_label_in_post_enabled": false,
      "responsive_web_profile_redirect_enabled": false,
    };

    final queryParameters = {
      'variables': jsonEncode(variables),
      'features': jsonEncode(features),
    };

    final headers = {
      'authorization':
          'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
      'x-csrf-token': csrfToken,
      'Cookie': cookie,
      'x-twitter-active-user': 'yes',
      'x-twitter-auth-type': 'OAuth2Session',
      'x-twitter-client-language': 'en',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      'Referer': 'https://api.x.com/',
    };

    final String url = 'https://api.x.com/graphql/$queryId/UserByRestId';

    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        logger.d("Response data: ${response.data}");
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to fetch user information: Status ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      logger.e(
        "Dio Error on getUserByRestId: ${e.response?.data}",
        error: e,
        stackTrace: s,
      );
      throw Exception('Network request failed: ${e.message}');
    } catch (e, s) {
      logger.e("Unknown error on getUserByRestId", error: e, stackTrace: s);
      throw Exception('An unknown error occurred.');
    }
  }

  Future<Map<String, dynamic>> getFollowers(
    String userId,
    String cookie,
    String transactionId,
    String cursor,
    String queryId,
  ) async {
    final csrfToken = _parseCsrfToken(cookie);
    if (csrfToken == null) {
      throw Exception("Unable to parse x-csrf-token (ct0) from Cookie");
    }

    final variables = {
      "userId": userId,
      "count": 50,
      "includePromotedContent": false,
      "withGrokTranslatedBio": false,
      "cursor": cursor,
    };

    final features = {
      "hidden_profile_subscriptions_enabled": true,
      "responsive_web_graphql_exclude_directive_enabled": true,
      "verified_phone_label_enabled": false,
      "highlights_tweets_tab_ui_enabled": true,
      "creator_subscriptions_tweet_preview_api_enabled": true,
      "responsive_web_graphql_skip_user_profile_image_extensions_enabled":
          false,
      "responsive_web_graphql_timeline_navigation_enabled": true,
      "rweb_tipjar_consumption_enabled": false,
      "subscriptions_feature_can_gift_premium": false,
      "payments_enabled": false,
      "responsive_web_twitter_article_notes_tab_enabled": false,
      "profile_label_improvements_pcf_label_in_post_enabled": false,
      "responsive_web_profile_redirect_enabled": false,
    };

    final queryParameters = {
      'variables': jsonEncode(variables),
      'features': jsonEncode(features),
    };

    final headers = {
      'authorization':
          'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
      'x-csrf-token': csrfToken,
      'Cookie': cookie,
      'x-twitter-active-user': 'yes',
      'x-twitter-auth-type': 'OAuth2Session',
      'x-twitter-client-language': 'en',
      'x-client-transaction-id': transactionId,
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      'Referer': 'https://api.x.com/',
    };

    final String url = 'https://api.x.com/graphql/$queryId/Followers';

    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        logger.d("Response data: ${response.data}");
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to fetch user information: Status ${response.statusCode}',
        );
      }
    } on DioException catch (e, s) {
      logger.e(
        "Dio Error on getFollowers: ${e.response?.data}",
        error: e,
        stackTrace: s,
      );
      throw Exception('Network request failed: ${e.message}');
    } catch (e, s) {
      logger.e("Unknown error on getFollowers", error: e, stackTrace: s);
      throw Exception('An unknown error occurred.');
    }
  }

  Future<UserListResultGql> getFollowing(
    String userId,
    String cookie,
    String transactionId,
    String cursor,
    String queryId,
  ) async {
    final csrfToken = _parseCsrfToken(cookie);
    if (csrfToken == null) {
      throw Exception("Unable to parse x-csrf-token (ct0) from Cookie");
    }

    final variables = {
      "userId": userId,
      "count": 50,
      "includePromotedContent": false,
      "withGrokTranslatedBio": false,
      "cursor": cursor,
    };

    final features = {
      "hidden_profile_subscriptions_enabled": true,
      "responsive_web_graphql_exclude_directive_enabled": true,
      "verified_phone_label_enabled": false,
      "highlights_tweets_tab_ui_enabled": true,
      "creator_subscriptions_tweet_preview_api_enabled": true,
      "responsive_web_graphql_skip_user_profile_image_extensions_enabled":
          false,
      "responsive_web_graphql_timeline_navigation_enabled": true,
      "rweb_tipjar_consumption_enabled": false,
      "subscriptions_feature_can_gift_premium": false,
      "payments_enabled": false,
      "responsive_web_twitter_article_notes_tab_enabled": false,
      "profile_label_improvements_pcf_label_in_post_enabled": false,
      "responsive_web_profile_redirect_enabled": false,
      "responsive_web_grok_image_annotation_enabled": false,
      "freedom_of_speech_not_reach_fetch_enabled": false,
      "graphql_is_translatable_rweb_tweet_is_translatable_enabled": false,
      "responsive_web_grok_analyze_post_followups_enabled": false,
      "responsive_web_grok_community_note_auto_translation_is_enabled": false,
      "responsive_web_edit_tweet_api_enabled": false,
      "tweet_awards_web_tipping_enabled": false,
      "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled":
          false,
      "responsive_web_grok_share_attachment_enabled": false,
      "responsive_web_grok_analyze_button_fetch_trends_enabled": false,
      "premium_content_api_read_enabled": false,
      "responsive_web_twitter_article_tweet_consumption_enabled": false,
      "communities_web_enable_tweet_community_results_fetch": false,
      "longform_notetweets_rich_text_read_enabled": false,
      "rweb_video_screen_enabled": false,
      "responsive_web_grok_show_grok_translated_post": false,
      "c9s_tweet_anatomy_moderator_badge_enabled": false,
      "articles_preview_enabled": false,
      "responsive_web_enhance_cards_enabled": false,
      "view_counts_everywhere_api_enabled": false,
      "creator_subscriptions_quote_tweet_preview_enabled": false,
      "responsive_web_grok_analysis_button_from_backend": false,
      "standardized_nudges_misinfo": false,
      "longform_notetweets_inline_media_enabled": false,
      "responsive_web_grok_imagine_annotation_enabled": false,
      "longform_notetweets_consumption_enabled": false,
      "responsive_web_jetfuel_frame": false,
    };

    final queryParameters = {
      'variables': jsonEncode(variables),
      'features': jsonEncode(features),
    };

    final headers = {
      'authorization':
          'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
      'x-csrf-token': csrfToken,
      'Cookie': cookie,
      'x-twitter-active-user': 'yes',
      'x-twitter-auth-type': 'OAuth2Session',
      'x-twitter-client-language': 'en',
      'x-client-transaction-id': transactionId,
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      'Referer': 'https://api.x.com/',
    };

    final String url = 'https://api.x.com/graphql/$queryId/Following';

    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        logger.d("Response data: ${response.data}");
        final Map<String, dynamic> data = response.data;

        // --- START OF MODIFICATION ---

        // 1. Get the instructions list
        final List<dynamic>? instructions = data['data']?['user']?['result']
            ?['timeline']?['timeline']?['instructions'] as List<dynamic>?;

        if (instructions == null) {
          logger.w(
            "getFollowing: Could not find 'instructions' array in response.",
          );
          return UserListResultGql(users: [], nextCursor: null);
        }

        // 2. Find the correct instruction object ('TimelineAddEntries')
        final Map<String, dynamic>? addEntriesInstruction =
            instructions.firstWhere(
          (inst) =>
              inst is Map<String, dynamic> &&
              inst['type'] == 'TimelineAddEntries',
          orElse: () => null,
        );

        if (addEntriesInstruction == null) {
          logger.w(
            "getFollowing: Could not find 'TimelineAddEntries' instruction.",
          );
          return UserListResultGql(users: [], nextCursor: null);
        }

        // 3. Get entries from *that* instruction
        final List<dynamic>? entries =
            addEntriesInstruction['entries'] as List<dynamic>?;

        if (entries == null || entries.isEmpty) {
          logger.w(
            "getFollowing: 'TimelineAddEntries' instruction has no 'entries'.",
          );
          return UserListResultGql(users: [], nextCursor: null);
        }

        // 4. Find the cursor within these entries
        final dynamic nextCursorValue = (entries.lastWhere(
          (e) =>
              e is Map<String, dynamic> &&
              e['content']?['entryType'] == 'TimelineTimelineCursor' &&
              e['content']?['cursorType'] == 'Bottom',
          orElse: () => null,
        ))?['content']?['value'];

        // 5. Filter for users within these entries
        final List<Map<String, dynamic>> usersMapList = entries
            .where(
              (e) =>
                  e is Map<String, dynamic> &&
                  e['content']?['entryType'] == 'TimelineTimelineItem' &&
                  e['content']?['itemContent']?['itemType'] == 'TimelineUser' &&
                  e['content']?['itemContent']?['user_results'] != null,
            )
            .map<Map<String, dynamic>>(
              (e) => e['content']['itemContent']['user_results']
                  as Map<String, dynamic>,
            )
            .toList();

        // --- END OF MODIFICATION ---

        final String? nextCursor = nextCursorValue?.toString();
        logger.d(
          "getFollowing: Parsed ${usersMapList.length} users, nextCursor: $nextCursor",
        );
        return UserListResultGql(users: usersMapList, nextCursor: nextCursor);
      } else {
        throw Exception(
          'Failed to fetch user information: Status ${response.statusCode}, Data: ${response.data}',
        );
      }
    } on DioException catch (e, s) {
      logger.e(
        "Dio Error on getFollowing: ${e.response?.data}",
        error: e,
        stackTrace: s,
      );
      throw Exception('Network request failed: ${e.message}');
    } catch (e, s) {
      logger.e("Unknown error on getFollowing", error: e, stackTrace: s);
      throw Exception('An unknown error occurred.');
    }
  }
}