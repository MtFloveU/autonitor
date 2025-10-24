// [已更新]
// 核心改动：
// 1. 添加了 `fromJson` 工厂构造函数，让这个类可以从一个Map(JSON)对象创建实例。
// 2. 添加了 `toJson` 方法，让这个类的实例可以被转换成一个Map(JSON)对象。
// 3. 这使得TwitterUser对象可以在应用中被序列化和反序列化，是数据持久化的基础。
class TwitterUser {
  final String avatarUrl;
  final String name;
  final String id;
  final String restId;
  final String joinTime;
  final String? bio;
  final String? location;
  final String? bannerUrl;
  final String? link;
  final int followingCount;
  final int followersCount;

  const TwitterUser({
    required this.avatarUrl,
    required this.name,
    required this.id,
    required this.restId,
    required this.joinTime,
    required this.bio,
    required this.location,
    required this.bannerUrl,
    required this.link,
    required this.followersCount,
    required this.followingCount,
  });

  // 从Map(JSON)创建TwitterUser实例
  factory TwitterUser.fromJson(Map<String, dynamic> json) {
    return TwitterUser(
      avatarUrl: json['avatarUrl'] ?? '',
      name: json['name'] ?? 'Unknown Name',
      id: json['id'] ?? 'Unknown ID',
      restId: json['restId'] ?? '',
      bio: json['bio'],
      location: json['location'],
      joinTime: json['joinTime'],
      bannerUrl: json['bannerUrl'],
      link: json['link'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }

  // 将TwitterUser实例转换为Map(JSON)
  Map<String, dynamic> toJson() {
    return {
      'avatarUrl': avatarUrl,
      'name': name,
      'id': id,
      'restId': restId,
      'bio': bio,
      'location': location,
      'joinTime': joinTime,
      'bannerUrl': bannerUrl,
    };
  }
}

