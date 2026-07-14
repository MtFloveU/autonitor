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

  // --- 核心改造：网络请求分发器 ---
  Future<Response<dynamic>> _executeRequest({
    required String endpoint,
    required Map<String, dynamic> queryParameters,
    required Map<String, String> headers,
    required String apiRequestMode,
    String? cffiUrl,
    String? cffiApiKey,
  }) async {
    if (apiRequestMode == 'curl_cffi') {
      if (cffiUrl == null || cffiApiKey == null || cffiUrl.isEmpty || cffiApiKey.isEmpty) {
        throw Exception("cffiUrl and cffiApiKey must be provided when using curl_cffi mode");
      }

      // 保证所有的 value 都是字符串以避免 Uri.replace 抛出异常
      final safeQueryParams = queryParameters.map((k, v) => MapEntry(k, v.toString()));
      final targetUrl = Uri.parse(endpoint).replace(queryParameters: safeQueryParams).toString();

      final proxyQueryParams = {
        'target_url': targetUrl,
        'req_headers': jsonEncode(headers),
        'apikey': cffiApiKey,
      };

      final response = await _dio.get(cffiUrl, queryParameters: proxyQueryParams);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['proxy_status'] == 'success') {
          final b64Str = data['raw_response_base64'] ?? '';
          final decodedBytes = base64Decode(b64Str);
          final decodedStr = utf8.decode(decodedBytes);

          dynamic responseData;
          try {
            responseData = jsonDecode(decodedStr);
          } catch (_) {
            responseData = decodedStr;
          }

          return Response(
            requestOptions: RequestOptions(path: endpoint),
            statusCode: data['target_status_code'],
            data: responseData,
          );
        } else {
          throw Exception("FastAPI Proxy returned error: ${data['detail']}");
        }
      } else {
        throw Exception("Failed to connect to FastAPI proxy. Status: ${response.statusCode}");
      }
    } else {
      // Dio default logic
      return await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
    }
  }

  Future<Map<String, dynamic>> getUserByRestId(
    String userId,
    String cookie,
    String queryId, {
    String apiRequestMode = 'dio',
    String? cffiUrl,
    String? cffiApiKey,
  }) async {
    final csrfToken = _parseCsrfToken(cookie);
    if (csrfToken == null) {
      throw Exception("Unable to parse x-csrf-token (ct0) from Cookie");
    }

    final variables = {
      "userId": userId,
      "withGrokTranslatedBio": true,
      "withSafetyModeUserFields": true,
    };

    final features = {
      "hidden_profile_subscriptions_enabled": true,
      "profile_label_improvements_pcf_label_in_post_enabled": true,
      "responsive_web_profile_redirect_enabled": true,
      "rweb_tipjar_consumption_enabled": true,
      "verified_phone_label_enabled": true,
      "subscriptions_verification_info_is_identity_verified_enabled": true,
      "subscriptions_verification_info_verified_since_enabled": true,
      "highlights_tweets_tab_ui_enabled": true,
      "responsive_web_twitter_article_notes_tab_enabled": true,
      "subscriptions_feature_can_gift_premium": true,
      "creator_subscriptions_tweet_preview_api_enabled": true,
      "responsive_web_graphql_skip_user_profile_image_extensions_enabled": true,
      "responsive_web_graphql_timeline_navigation_enabled": true,
      "payments_enabled": true,
      "responsive_web_graphql_exclude_directive_enabled": true,
    };

    final fieldToggles = {
      "withPayments": true,
      "withAuxiliaryUserLabels": true,
    };

    final queryParameters = {
      'variables': jsonEncode(variables),
      'features': jsonEncode(features),
      'fieldToggles': jsonEncode(fieldToggles),
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
      final response = await _executeRequest(
        endpoint: url,
        queryParameters: queryParameters,
        headers: headers,
        apiRequestMode: apiRequestMode,
        cffiUrl: cffiUrl,
        cffiApiKey: cffiApiKey,
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

  Future<Map<String, dynamic>> getUsersByRestIds(
    List<String> userIds,
    String cookie,
    String queryId,
    String transactionId, {
    String apiRequestMode = 'dio',
    String? cffiUrl,
    String? cffiApiKey,
  }) async {
    final csrfToken = _parseCsrfToken(cookie);
    if (csrfToken == null) {
      throw Exception("Unable to parse x-csrf-token (ct0) from Cookie");
    }

    final variables = {
      "userIds": userIds,
      "withGrokTranslatedBio": true,
      "withSafetyModeUserFields": true,
    };

    final features = {
      "hidden_profile_subscriptions_enabled": true,
      "profile_label_improvements_pcf_label_in_post_enabled": true,
      "responsive_web_profile_redirect_enabled": false,
      "rweb_tipjar_consumption_enabled": false,
      "verified_phone_label_enabled": false,
      "highlights_tweets_tab_ui_enabled": true,
      "responsive_web_twitter_article_notes_tab_enabled": true,
      "subscriptions_feature_can_gift_premium": true,
      "creator_subscriptions_tweet_preview_api_enabled": true,
      "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false,
      "responsive_web_graphql_timeline_navigation_enabled": true,
      "responsive_web_grok_annotations_enabled": false,
      "post_ctas_fetch_enabled": false,
    };

    final fieldToggles = {
      "withPayments": true,
      "withAuxiliaryUserLabels": true,
    };

    final queryParameters = {
      'variables': jsonEncode(variables),
      'features': jsonEncode(features),
      'fieldToggles': jsonEncode(fieldToggles),
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

    final String url = 'https://api.x.com/graphql/$queryId/UsersByRestIds';

    try {
      final response = await _executeRequest(
        endpoint: url,
        queryParameters: queryParameters,
        headers: headers,
        apiRequestMode: apiRequestMode,
        cffiUrl: cffiUrl,
        cffiApiKey: cffiApiKey,
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
        "Dio Error on getUsersByRestIds: ${e.response?.data}",
        error: e,
        stackTrace: s,
      );
      throw Exception('Network request failed: ${e.message}');
    } catch (e, s) {
      logger.e("Unknown error on getUsersByRestIds", error: e, stackTrace: s);
      throw Exception('An unknown error occurred.');
    }
  }

  Future<Map<String, dynamic>> getUsersByScreenNames(
    List<String> screenNames,
    String cookie,
    String queryId,
    String transactionId, {
    String apiRequestMode = 'curl_cffi',
    String? cffiUrl,
    String? cffiApiKey,
  }) async {
    final csrfToken = _parseCsrfToken(cookie);
    if (csrfToken == null) {
      throw Exception("Unable to parse x-csrf-token (ct0) from Cookie");
    }

    final variables = {
      "screen_names": screenNames,
      "withSafetyModeUserFields": true,
    };

    final features = {
      "responsive_web_graphql_exclude_directive_enabled": true,
      "verified_phone_label_enabled": false,
      "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false,
      "responsive_web_graphql_timeline_navigation_enabled": true,
    };

    final fieldToggles = {
      "withAuxiliaryUserLabels": false,
    };

    final queryParameters = {
      'variables': jsonEncode(variables),
      'features': jsonEncode(features),
      'fieldToggles': jsonEncode(fieldToggles),
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

    final String url = 'https://api.x.com/graphql/$queryId/UsersByScreenNames';

    try {
      final response = await _executeRequest(
        endpoint: url,
        queryParameters: queryParameters,
        headers: headers,
        apiRequestMode: apiRequestMode,
        cffiUrl: cffiUrl,
        cffiApiKey: cffiApiKey,
      );

      if (response.statusCode == 200 && response.data != null) {
        logger.d("Response data: ${response.data}");
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'UsersByScreenNames request failed: status ${response.statusCode}; '
          'response: ${response.data}',
        );
      }
    } on DioException catch (e, s) {
      logger.e(
        "Dio Error on getUsersByScreenNames: ${e.response?.data}",
        error: e,
        stackTrace: s,
      );
      throw Exception('Network request failed: ${e.message}');
    } catch (e, s) {
      logger.e("Unknown error on getUsersByScreenNames", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFollowers(
    String userId,
    String cookie,
    String transactionId,
    String cursor,
    String queryId, {
    String apiRequestMode = 'dio',
    String? cffiUrl,
    String? cffiApiKey,
  }) async {
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
      "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false,
      "responsive_web_graphql_timeline_navigation_enabled": true,
      "rweb_tipjar_consumption_enabled": false,
      "subscriptions_feature_can_gift_premium": false,
      "payments_enabled": false,
      "responsive_web_twitter_article_notes_tab_enabled": false,
      "profile_label_improvements_pcf_label_in_post_enabled": false,
      "responsive_web_profile_redirect_enabled": false,
      "responsive_web_grok_annotations_enabled": false,
      "post_ctas_fetch_enabled": false,
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
      final response = await _executeRequest(
        endpoint: url,
        queryParameters: queryParameters,
        headers: headers,
        apiRequestMode: apiRequestMode,
        cffiUrl: cffiUrl,
        cffiApiKey: cffiApiKey,
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
    String queryId, {
    String apiRequestMode = 'dio',
    String? cffiUrl,
    String? cffiApiKey,
  }) async {
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
      "verified_phone_label_enabled": true,
      "highlights_tweets_tab_ui_enabled": true,
      "creator_subscriptions_tweet_preview_api_enabled": true,
      "responsive_web_graphql_skip_user_profile_image_extensions_enabled": true,
      "responsive_web_graphql_timeline_navigation_enabled": true,
      "rweb_tipjar_consumption_enabled": true,
      "subscriptions_feature_can_gift_premium": true,
      "payments_enabled": true,
      "responsive_web_twitter_article_notes_tab_enabled": true,
      "profile_label_improvements_pcf_label_in_post_enabled": true,
      "responsive_web_profile_redirect_enabled": true,
      "responsive_web_grok_image_annotation_enabled": true,
      "freedom_of_speech_not_reach_fetch_enabled": true,
      "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true,
      "responsive_web_grok_analyze_post_followups_enabled": true,
      "responsive_web_grok_community_note_auto_translation_is_enabled": true,
      "responsive_web_edit_tweet_api_enabled": true,
      "tweet_awards_web_tipping_enabled": true,
      "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true,
      "responsive_web_grok_share_attachment_enabled": true,
      "responsive_web_grok_analyze_button_fetch_trends_enabled": true,
      "premium_content_api_read_enabled": true,
      "responsive_web_twitter_article_tweet_consumption_enabled": true,
      "communities_web_enable_tweet_community_results_fetch": true,
      "longform_notetweets_rich_text_read_enabled": true,
      "rweb_video_screen_enabled": true,
      "responsive_web_grok_show_grok_translated_post": true,
      "c9s_tweet_anatomy_moderator_badge_enabled": true,
      "articles_preview_enabled": true,
      "responsive_web_enhance_cards_enabled": true,
      "view_counts_everywhere_api_enabled": true,
      "creator_subscriptions_quote_tweet_preview_enabled": true,
      "responsive_web_grok_analysis_button_from_backend": true,
      "standardized_nudges_misinfo": true,
      "longform_notetweets_inline_media_enabled": true,
      "responsive_web_grok_imagine_annotation_enabled": true,
      "longform_notetweets_consumption_enabled": true,
      "responsive_web_jetfuel_frame": true,
      "responsive_web_grok_annotations_enabled": false,
      "post_ctas_fetch_enabled": false,
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
      final response = await _executeRequest(
        endpoint: url,
        queryParameters: queryParameters,
        headers: headers,
        apiRequestMode: apiRequestMode,
        cffiUrl: cffiUrl,
        cffiApiKey: cffiApiKey,
      );

      if (response.statusCode == 200 && response.data != null) {
        logger.d("Response data: ${response.data}");
        final Map<String, dynamic> data = response.data;

        final List<dynamic>? instructions =
            data['data']?['user']?['result']?['timeline']?['timeline']?['instructions']
                as List<dynamic>?;

        if (instructions == null) {
          logger.w(
            "getFollowing: Could not find 'instructions' array in response.",
          );
          return UserListResultGql(users: [], nextCursor: null);
        }

        final Map<String, dynamic>? addEntriesInstruction = instructions
            .firstWhere(
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

        final List<dynamic>? entries =
            addEntriesInstruction['entries'] as List<dynamic>?;

        if (entries == null || entries.isEmpty) {
          logger.w(
            "getFollowing: 'TimelineAddEntries' instruction has no 'entries'.",
          );
          return UserListResultGql(users: [], nextCursor: null);
        }

        final dynamic nextCursorValue = (entries.lastWhere(
          (e) =>
              e is Map<String, dynamic> &&
              e['content']?['entryType'] == 'TimelineTimelineCursor' &&
              e['content']?['cursorType'] == 'Bottom',
          orElse: () => null,
        ))?['content']?['value'];

        final List<Map<String, dynamic>> usersMapList = entries
            .where(
              (e) =>
                  e is Map<String, dynamic> &&
                  e['content']?['entryType'] == 'TimelineTimelineItem' &&
                  e['content']?['itemContent']?['itemType'] == 'TimelineUser' &&
                  e['content']?['itemContent']?['user_results'] != null,
            )
            .map<Map<String, dynamic>>(
              (e) =>
                  e['content']['itemContent']['user_results']
                      as Map<String, dynamic>,
            )
            .toList();

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
