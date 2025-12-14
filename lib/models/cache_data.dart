// [已更新]
// 核心改动：
// 1. 新增了 `toJson` 方法，用于将 CacheData 对象实例序列化为 Map<String, dynamic>。
// 2. 这是解决 `The method 'toJson' isn't defined` 编译错误所必需的。

class CacheData {
  final String accountId;
  final String accountName;
  final String lastUpdateTime;
  final int followersCount;
  final int followingCount;
  final int unfollowedCount;
  final int mutualUnfollowedCount;
  final int singleUnfollowedCount;
  final int frozenCount;
  final int deactivatedCount;
  final int refollowedCount;
  final int newFollowersCount;
  final int temporarilyRestrictedCount;
  final int recoveredCount;
  final int profileUpdatedCount;

  CacheData({
    required this.accountId,
    required this.accountName,
    required this.lastUpdateTime,
    required this.followersCount,
    required this.followingCount,
    required this.unfollowedCount,
    required this.mutualUnfollowedCount,
    required this.singleUnfollowedCount,
    required this.frozenCount,
    required this.deactivatedCount,
    required this.refollowedCount,
    required this.newFollowersCount,
    required this.temporarilyRestrictedCount,
    required this.recoveredCount,
    required this.profileUpdatedCount,
  });

  factory CacheData.fromJson(Map<String, dynamic> json) {
    return CacheData(
      accountId: json['accountId'] ?? '',
      accountName: json['accountName'] ?? 'Unknown',
      lastUpdateTime: json['lastUpdateTime'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      unfollowedCount: json['unfollowedCount'] ?? 0,
      mutualUnfollowedCount: json['mutualUnfollowedCount'] ?? 0,
      singleUnfollowedCount: json['singleUnfollowedCount'] ?? 0,
      frozenCount: json['frozenCount'] ?? 0,
      deactivatedCount: json['deactivatedCount'] ?? 0,
      refollowedCount: json['refollowedCount'] ?? 0,
      newFollowersCount: json['newFollowersCount'] ?? 0,
      temporarilyRestrictedCount: json['temporarilyRestrictedCount'] ?? 0,
      recoveredCount: json['recoveredCount'] ?? 0,
      profileUpdatedCount: json['profileUpdatedCount'] ?? 0,
    );
  }

  /// [新增] 将 CacheData 实例转换为 Map 的方法
  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'lastUpdateTime': lastUpdateTime,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'unfollowedCount': unfollowedCount,
      'mutualUnfollowedCount': mutualUnfollowedCount,
      'singleUnfollowedCount': singleUnfollowedCount,
      'frozenCount': frozenCount,
      'deactivatedCount': deactivatedCount,
      'refollowedCount': refollowedCount,
      'newFollowersCount': newFollowersCount,
      'temporarilyRestrictedCount': temporarilyRestrictedCount,
      'recoveredCount': recoveredCount,
      'profileUpdatedCount': profileUpdatedCount,
    };
  }
}
