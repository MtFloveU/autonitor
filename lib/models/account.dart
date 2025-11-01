class Account {
  final String? latestRawJson;

  /// The unique Twitter User ID (Rest ID / twid).
  final String id;

  /// The full cookie string required for authentication.
  final String cookie;

  /// The user's display name (e.g., "Elon Musk"). Fetched from API.
  final String? name;

  /// The user's screen name / handle (e.g., "elonmusk"). Fetched from API.
  final String? screenName;

  /// The URL for the user's profile image. Fetched from API.
  final String? avatarUrl;

  /// The URL for the user's profile banner.
  final String? bannerUrl;

  /// The user's biography.
  final String? bio;

  /// The user's profile location.
  final String? location;

  /// The user's profile link (t.co).
  final String? link;

  /// The ISO 8601 string of when the account was created.
  final String? joinTime;

  /// The number of followers.
  final int followersCount;

  /// The number of accounts the user is following.
  final int followingCount;
  final int statusesCount;
  final int mediaCount;
  final int favouritesCount;
  final int listedCount;

  Account({
    required this.id,
    required this.cookie,
    this.name,
    this.screenName,
    this.avatarUrl,
    this.bannerUrl,
    this.bio,
    this.location,
    this.link,
    this.joinTime,
    this.followersCount = 0,
    this.followingCount = 0,
    this.statusesCount = 0,
    this.mediaCount = 0,
    this.favouritesCount = 0,
    this.listedCount = 0,
    this.latestRawJson,
  });

  /// Creates an Account instance from a JSON map.
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String? ?? '', // Provide default empty string
      cookie: json['cookie'] as String? ?? '', // Provide default empty string
      name: json['name'] as String?,
      screenName: json['screenName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      link: json['link'] as String?,
      joinTime: json['joinTime'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      statusesCount: json['statusesCount'] ?? 0,
      mediaCount: json['mediaCount'] ?? 0,
      favouritesCount: json['favouritesCount'] ?? 0,
      listedCount: json['listedCount'] ?? 0,
      latestRawJson: json['latestRawJson'] as String?,
    );
  }

  /// Converts the Account instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cookie': cookie,
      'name': name,
      'screenName': screenName,
      'avatarUrl': avatarUrl,
      'bannerUrl': bannerUrl,
      'bio': bio,
      'location': location,
      'link': link,
      'joinTime': joinTime,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'statusesCount': statusesCount,
      'mediaCount': mediaCount,
      'favouritesCount': favouritesCount,
      'listedCount': listedCount,
      'latestRawJson': latestRawJson,
    };
  }

  // Optional: Add copyWith for easier updates
  Account copyWith({
    String? id,
    String? cookie,
    String? name,
    String? screenName,
    String? avatarUrl,
    String? bannerUrl,
    String? bio,
    String? location,
    String? link,
    String? joinTime,
    int? followersCount,
    int? followingCount,
    int? statusesCount,
    int? mediaCount,
    int? favouritesCount,
    int? listedCount,
    String? latestRawJson,
  }) {
    return Account(
      id: id ?? this.id,
      cookie: cookie ?? this.cookie,
      name: name ?? this.name,
      screenName: screenName ?? this.screenName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      link: link ?? this.link,
      joinTime: joinTime ?? this.joinTime,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      statusesCount: statusesCount ?? this.statusesCount,
      mediaCount: mediaCount ?? this.mediaCount,
      favouritesCount: favouritesCount ?? this.favouritesCount,
      listedCount: listedCount ?? this.listedCount,
      latestRawJson: latestRawJson ?? this.latestRawJson,
    );
  }

  // Optional: Override toString for better debugging
  @override
  String toString() {
    return 'Account(id: $id, name: $name, screenName: $screenName, avatarUrl: $avatarUrl, cookie: ${cookie.length > 10 ? cookie.substring(0, 10) + '...' : cookie})';
  }
}
