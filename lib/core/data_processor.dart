import 'dart:convert';
import '../models/account.dart';
import '../models/cache_data.dart';
import '../models/twitter_user.dart';

class DataProcessor {
  final Account account;
  DataProcessor({required this.account});

  // 模拟文件系统，用于存储缓存和commit
  final Map<String, String> _fileSystem = {};

  /// 运行核心分析流程
  Future<void> runProcess() async {
    // 模拟耗时操作，例如API请求和数据比较
    final latestUsers = _fetchLatestUserData();
    _generateCache(latestUsers);
  }

  /// 从模拟文件系统中获取缓存数据
  Future<CacheData?> getCacheData() async {
    // 为每个账号使用独立的缓存文件
    final cacheJson = _fileSystem['cache_${account.id}.json'];
    if (cacheJson != null) {
      try {
         return CacheData.fromJson(jsonDecode(cacheJson));
      } catch (e) {
         // 在真实应用中处理错误，例如删除无效缓存
         print("Error decoding cache data: $e");
         return null;
      }
    }
    return null;
  }
  
  /// 获取特定分类的用户列表
  Future<List<TwitterUser>> getUsers(String category) async {
    // 根据分类返回不同的模拟数据列表
    await Future.delayed(const Duration(seconds: 1));
    if (category == 'followers') {
      return _fetchLatestUserData().values.toList();
    }
    if (category == 'normal_unfollowed') {
       return [
        // 使用 const 构造函数，并确保所有字段都提供了值或 null
        const TwitterUser(id: "unfollowed1", name: "Unfollowed User 1", restId: "u1", avatarUrl: "", joinTime: 'Wed Apr 12 05:43:13 +0000 2023', bio: 'unfollowed 1', location: 'unfo1', bannerUrl: null, link: null, followersCount: 1200, followingCount: 100, statusesCount: 1323, mediaCount: 31, favouritesCount: 424214, listedCount: 31),
        const TwitterUser(id: "unfollowed2", name: "Unfollowed User 2", restId: "u2", avatarUrl: "", joinTime: 'Wed Apr 12 05:43:14 +0000 2023', bio: 'unfollowed 2', location: 'unfo2', bannerUrl: null, link: null, followersCount: 1200, followingCount: 100, statusesCount: 2211, mediaCount: 123, favouritesCount: 2434224, listedCount: 2),
      ];
    }
    if (category == 'following') {
        return []; // 明确返回空列表
    }
    // 对于其他未实现的分类，返回空列表
    return [];
  }

  /// 生成UI直接使用的缓存文件
  void _generateCache(Map<String, TwitterUser> latestState) {
    // 模拟从API获取用户名
    final profileNameFromApi = "User_${account.id.substring(0, 5)}";

    final cacheContent = CacheData(
      accountName: profileNameFromApi,
      accountId: account.id,
      lastUpdateTime: DateTime.now().toIso8601String(),
      followersCount: latestState.length,
      followingCount: 0, // 模拟数据
      unfollowedCount: 12,
      mutualUnfollowedCount: 5,
      singleUnfollowedCount: 7,
      frozenCount: 2,
      deactivatedCount: 1,
      refollowedCount: 3,
      newFollowersCount: 8,
    );

    // 将缓存数据写入模拟文件系统
    try {
      _fileSystem['cache_${account.id}.json'] = jsonEncode(cacheContent.toJson());
    } catch (e) {
       print("Error encoding cache data: $e");
    }
  }

  /// 模拟从API获取最新的用户数据
  Map<String, TwitterUser> _fetchLatestUserData() {
    return {
      // 使用 const 构造函数，并确保所有字段都提供了值或 null
      "user1": const TwitterUser(id: "user1", name: "User One (upd)", restId: "1234567890", bio: "Hello everyone, this is User 1 checking in. I'm here and ready to participate in the discussion.", location: "User 1 Location", joinTime: "Wed Apr 12 05:43:13 +0000 2023", avatarUrl: "", bannerUrl: null, link: 'https://example.com', followersCount: 1200, followingCount: 100, statusesCount: 3112, mediaCount: 2, favouritesCount: 3145, listedCount: 9),
      "user2": const TwitterUser(id: "user2", name: "User Two", restId: "2", bio: "This is user 2", location: "User 2 Location", joinTime: "Wed Apr 12 05:43:14 +0000 2023", avatarUrl: "", bannerUrl: null, link: null, followersCount: 1200, followingCount: 100, statusesCount: 1231, mediaCount: 13, favouritesCount: 3113313, listedCount: 12),
      "user4": const TwitterUser(id: "user4", name: "User Four", restId: "4", bio: "This is user 4", location: "User 4 Location", joinTime: "Wed Apr 12 05:43:15 +0000 2023", avatarUrl: "", bannerUrl: null, link: null, followersCount: 1200, followingCount: 100, statusesCount: 5335, mediaCount: 321, favouritesCount: 6464, listedCount: 4),
    };
  }
}

