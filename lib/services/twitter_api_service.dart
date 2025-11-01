import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'log_service.dart';

final twitterApiServiceProvider = Provider((ref) => TwitterApiService());

class TwitterApiService {
  final Dio _dio;

  TwitterApiService() : _dio = Dio() {
    // 在这里可以为 Dio 设置一些基础配置，比如超时时间
    //_dio.options.connectTimeout = const Duration(seconds: 10);
    //_dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// 从 Cookie 字符串中解析 'ct0' CSRF token。
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

  /// 通过 Rest ID (twid) 获取用户 Profile 信息
  ///
  /// 成功时返回解码后的 JSON Map，失败时抛出异常。
  Future<Map<String, dynamic>> getUserByRestId(
    String userId,
    String cookie,
  ) async {
    final csrfToken = _parseCsrfToken(cookie);
    if (csrfToken == null) {
      throw Exception("Unable to parse x-csrf-token (ct0) from Cookie");
    }

    // 1. 准备 Query Parameters
    final variables = {
      "userId": userId,
      // "withSafetyModeUserFields": true // 可以根据需要添加
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
      // ... 可以从您提供的 URL 中复制更多 feature flags
    };

    final queryParameters = {
      'variables': jsonEncode(variables),
      'features': jsonEncode(features),
    };

    // 2. 准备 Headers
    final headers = {
      'authorization':
          'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
      'x-csrf-token': csrfToken,
      'Cookie': cookie,
      // --- 从您命令中复制的其他 Headers ---
      'x-twitter-active-user': 'yes',
      'x-twitter-auth-type': 'OAuth2Session',
      'x-twitter-client-language': 'en',
      // --- 推荐添加的浏览器 Headers ---
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      'Referer': 'https://x.com/',
    };

    // 3. 定义 URL
    const String url =
        'https://x.com/i/api/graphql/q9yeu7UlEs2YVx_-Z8Ps7Q/UserByRestId';

    try {
      // 4. 发送 GET 请求
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      // 5. 检查响应并返回数据
      if (response.statusCode == 200 && response.data != null) {
        logger.d("Response data: ${response.data}");
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch user information: Status ${response.statusCode}');
      }
    } on DioException catch (e, s) {
      logger.e("Dio Error on getUserByRestId: ${e.response?.data}", error: e, stackTrace: s);
      throw Exception('Network request failed: ${e.message}');
    } catch (e, s) {
      // 捕获其他未知错误
      logger.e("Unknown error on getUserByRestId", error: e, stackTrace: s);
      throw Exception('An unknown error occurred.');
    }
  }
}
