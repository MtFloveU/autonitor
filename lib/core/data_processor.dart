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
    await Future.delayed(const Duration(seconds: 2));
    final latestUsers = _fetchLatestUserData();
    _generateCache(latestUsers);
  }

  /// 从模拟文件系统中获取缓存数据
  Future<CacheData?> getCacheData() async {
    // 为每个账号使用独立的缓存文件
    final cacheJson = _fileSystem['cache_${account.id}.json'];
    if (cacheJson != null) {
      return CacheData.fromJson(jsonDecode(cacheJson));
    }
    return null;
  }
  
  /// [新增] 获取特定分类的用户列表
  /// 在真实应用中，这里会根据`category`读取不同的数据文件或执行不同的计算
  Future<List<TwitterUser>> getUsers(String category) async {
    print("DataProcessor: Fetching users for category '$category'");
    await Future.delayed(const Duration(milliseconds: 300)); // 模拟异步IO

    // 根据分类返回不同的模拟数据列表
    if (category == '关注者') {
      return _fetchLatestUserData().values.toList();
    }
    if (category == '普通取关') {
       return [
        const TwitterUser(id: "@unfollowed1", name: "Unfollowed User 1", restId: "u1", avatarUrl: ""),
        const TwitterUser(id: "@unfollowed2", name: "Unfollowed User 2", restId: "u2", avatarUrl: ""),
      ];
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
      followingCount: 150, // 模拟数据
      unfollowedCount: 12,
      mutualUnfollowedCount: 5,
      singleUnfollowedCount: 7,
      frozenCount: 2,
      deactivatedCount: 1,
      refollowedCount: 3,
      newFollowersCount: 8,
    );

    // 将缓存数据写入模拟文件系统
    _fileSystem['cache_${account.id}.json'] = jsonEncode(cacheContent.toJson());
  }

  /// 模拟从API获取最新的用户数据
  Map<String, TwitterUser> _fetchLatestUserData() {
    return {
      "user1": const TwitterUser(id: "@user1", name: "User One (Updated)", restId: "1", avatarUrl: ""),
      "user2": const TwitterUser(id: "@user2", name: "User Two", restId: "2", avatarUrl: ""),
      "user4": const TwitterUser(id: "@user4", name: "User Four", restId: "4", avatarUrl: ""),
    };
  }
}

