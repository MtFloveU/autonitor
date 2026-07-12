import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'log_service.dart';

final twitterApiV1ServiceProvider = Provider((ref) => TwitterApiV1Service());

class UserListResult {
  final List<Map<String, dynamic>> users;
  final String? nextCursor;
  UserListResult({required this.users, this.nextCursor});
}

class TwitterApiV1Service {
  final Dio _dio;
  // --- 重试相关常量 ---
  static const int _maxRetries = 5; // 最多重试次数
  static const Duration _retryDelay = Duration(milliseconds: 500); // 每次重试间隔

  TwitterApiV1Service() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    // 阻止 Dio 因为 404 抛出异常，我们手动检查状态码
    _dio.options.validateStatus = (status) {
      return status != null && (status >= 200 && status < 300 || status == 404);
    };
  }

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
      logger.e(
        "TwitterApiV1Service: Failed to parse ct0 token: $e",
        error: e,
        stackTrace: s,
      );
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

      // 将 endpoint 和 query 组合成完整的目标 URL
      final safeQueryParams = queryParameters.map((k, v) => MapEntry(k, v.toString()));
      final targetUrl = Uri.parse(endpoint).replace(queryParameters: safeQueryParams).toString();

      // 构建发给 FastAPI 后端的查询参数
      final proxyQueryParams = {
        'target_url': targetUrl,
        'req_headers': jsonEncode(headers),
        'apikey': cffiApiKey,
      };

      // 通过普通 Dio 请求我们的本地/远程 Python 后端
      final response = await _dio.get(cffiUrl, queryParameters: proxyQueryParams);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['proxy_status'] == 'success') {
          // 提取 Base64 并解码
          final b64Str = data['raw_response_base64'] ?? '';
          final decodedBytes = base64Decode(b64Str);
          final decodedStr = utf8.decode(decodedBytes);

          dynamic responseData;
          try {
            // 尝试将推特的原始文本解析为 JSON
            responseData = jsonDecode(decodedStr);
          } catch (_) {
            // 如果推特返回的是 404 HTML 页面等非 JSON 格式，就保留文本
            responseData = decodedStr;
          }

          // 伪造并返回一个标准的 Dio Response 供上层使用
          return Response(
            requestOptions: RequestOptions(path: endpoint),
            statusCode: data['target_status_code'], // 透传推特真实状态码
            data: responseData,
          );
        } else {
          throw Exception("FastAPI Proxy returned error: ${data['detail']}");
        }
      } else {
        throw Exception("Failed to connect to FastAPI proxy. Status: ${response.statusCode}");
      }
    } else {
      // 默认模式：走普通 Dio 请求
      return await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
    }
  }

  Future<UserListResult> _fetchList(
    String endpoint,
    String userId,
    String cookie,
    String? cursor,
    int count,
    String listTypeLogName,
    String apiRequestMode,
    String? cffiUrl,
    String? cffiApiKey,
  ) async {
    final Map<String, dynamic> queryParameters = {
      'include_profile_interstitial_type': 1, 'include_blocking': 0,
      'include_blocked_by': 0, 'include_followed_by': 1,
      'include_want_retweets': 0, 'include_mute_edge': 0,
      'include_can_dm': 1, 'include_can_media_tag': 1,
      'include_ext_is_blue_verified': 1, 'include_ext_verified_type': 1,
      'include_ext_profile_image_shape': 0, 'skip_status': 1,
      'user_id': userId, 'count': count,
    };
    
    if (cursor != null && cursor != '0') {
      queryParameters['cursor'] = cursor;
    } else if (cursor == null) {
      queryParameters['cursor'] = "-1";
    }

    final csrfToken = _parseCsrfToken(cookie);
    if (csrfToken == null) {
      logger.e(
        "TwitterApiV1Service: FATAL - ct0 token not found in cookie for $listTypeLogName.",
      );
      throw Exception("Cannot get ct0 token from cookie (x-csrf-token)");
    }

    final headers = {
      'accept': '*/*',
      'authorization':
          'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
      'Cookie': cookie,
      'dnt': '1',
      'priority': 'u=1, i',
      'sec-ch-ua':
          '"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Linux"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      'user-agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
      'x-csrf-token': csrfToken,
      'x-twitter-active-user': 'yes',
      'x-twitter-auth-type': 'OAuth2Session',
      'x-twitter-client-language': 'en',
      'Referer': 'https://x.com/',
    };

    int attempt = 0;
    while (attempt <= _maxRetries) {
      attempt++;
      logger.d(
        "TwitterApiV1Service: Fetching $listTypeLogName for $userId with cursor ${queryParameters['cursor']} (Attempt $attempt/$_maxRetries) via [$apiRequestMode]...",
      );

      try {
        // 调用我们刚才封装的分发器
        final response = await _executeRequest(
          endpoint: endpoint,
          queryParameters: queryParameters,
          headers: headers,
          apiRequestMode: apiRequestMode,
          cffiUrl: cffiUrl,
          cffiApiKey: cffiApiKey,
        );

        // --- 手动检查状态码 ---
        if (response.statusCode == 200 && response.data != null) {
          if (response.data is Map<String, dynamic>) {
            final Map<String, dynamic> data = response.data;
            final List<dynamic> userList = data['users'] ?? [];
            final dynamic nextCursorValue =
                data['next_cursor'] ?? data['next_cursor_str'];
            final String? nextCursor = nextCursorValue?.toString();
            final List<Map<String, dynamic>> usersMapList = userList
                .map((user) => user as Map<String, dynamic>)
                .toList();
            return UserListResult(
              users: usersMapList,
              nextCursor: nextCursor,
            ); // 成功，返回结果
          } else {
            _logAndThrow(
              "Error fetching $listTypeLogName - Unexpected response format: ${response.data}",
            );
          }
        } else if (response.statusCode == 404) {
          _log(
            "Warning: Received 404 fetching $listTypeLogName (Attempt $attempt). Retrying in ${_retryDelay.inSeconds}s...",
          );
          if (attempt >= _maxRetries) {
            _logAndThrow(
              "Failed fetching $listTypeLogName after $_maxRetries attempts (404).",
            );
          }
          await Future.delayed(_retryDelay); // 等待后重试
          continue; // 继续下一次循环尝试
        } else if (response.statusCode == 403 || response.statusCode == 215) {
          _logAndThrow(
            'Authorization failed (${response.statusCode}). Headers or Cookie might be incorrect/expired.',
          );
        } else if (response.statusCode == 429) {
          _logAndThrow('Rate limit exceeded (429). Please wait and try again.');
        } else {
          // 其他 4xx 错误通常不可重试
          _logAndThrow(
            'Failed to fetch $listTypeLogName: Status ${response.statusCode}, Data: ${response.data}',
          );
        }
        // --- 检查结束 ---
      } on DioException catch (e) {
        _log(
          "DioError fetching $listTypeLogName (Attempt $attempt): ${e.message}. Retrying in ${_retryDelay.inSeconds}s...",
        );
        if (attempt >= _maxRetries) {
          _logAndThrow(
            "Failed fetching $listTypeLogName after $_maxRetries attempts (Network/Server Error): ${e.message}",
          );
        }
        await Future.delayed(_retryDelay);
        continue;
      } catch (e) {
        _log(
          "Unknown error fetching $listTypeLogName (Attempt $attempt): $e. Retrying in ${_retryDelay.inSeconds}s...",
        );
        if (attempt >= _maxRetries) {
          _logAndThrow(
            "Failed fetching $listTypeLogName after $_maxRetries attempts (Unknown Error): $e",
          );
        }
        await Future.delayed(_retryDelay);
        continue;
      }
    }
    throw Exception('Failed to fetch $listTypeLogName after multiple retries.');
  }

  // --- 辅助方法用于日志记录和抛出异常 ---
  void _log(String message) {
    logger.d("TwitterApiV1Service: $message");
  }

  Never _logAndThrow(String errorMessage) {
    logger.e(
      "TwitterApiV1Service: $errorMessage",
      error: Exception(errorMessage),
      stackTrace: StackTrace.current,
    );
    throw Exception(errorMessage); // 抛出异常中断执行
  }
  // --- 辅助方法结束 ---

  Future<UserListResult> getFollowers(
    String userId,
    String cookie, {
    String? cursor,
    int count = 200,
    String apiRequestMode = 'dio',
    String? cffiUrl,
    String? cffiApiKey,
  }) async {
    return _fetchList(
      'https://api.x.com/1.1/followers/list.json',
      userId,
      cookie,
      cursor,
      count,
      'followers',
      apiRequestMode,
      cffiUrl,
      cffiApiKey,
    );
  }

  Future<UserListResult> getFollowing(
    String userId,
    String cookie, {
    String? cursor,
    int count = 200,
    String apiRequestMode = 'dio',
    String? cffiUrl,
    String? cffiApiKey,
  }) async {
    return _fetchList(
      'https://api.x.com/1.1/friends/list.json',
      userId,
      cookie,
      cursor,
      count,
      'following',
      apiRequestMode,
      cffiUrl,
      cffiApiKey,
    );
  }
}