import 'package:flutter_riverpod/flutter_riverpod.dart';

// [已更新]
// 核心改动：
// 1. 移除了网络请求逻辑，不再对Cookie进行有效性验证。
final twitterApiServiceProvider = Provider((ref) => TwitterApiService());

class TwitterApiService {
  // 这个URL现在是未使用的，但我们保留它以备将来参考。
  final String _userProfileUrl = 'https://api.x.com/1.1/account/verify_credentials.json';

  /// [已修改] 此函数不再进行网络验证。
  /// 它会立即返回一个空的、非null的Map，以绕过AuthProvider中的验证检查。
  Future<Map<String, dynamic>?> getUserProfile(String cookie) async {
    // 之前这里会发送一个HTTP请求来验证Cookie。
    // 现在，我们跳过这一步，直接返回一个模拟的成功结果。
    // 这意味着任何格式正确的Cookie（只要能解析出twid）都将被视为有效。
    print("注意：Cookie有效性验证已被禁用。");
    return {}; // 返回一个非空的Map来模拟一个成功的API响应
  }
}

