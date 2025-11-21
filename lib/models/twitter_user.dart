class TwitterUser {
  final String restId;
  final String? name;
  final String? screenName;
  final String? avatarUrl;
  final String? avatarLocalPath;
  final String? bannerUrl;
  final String? bannerLocalPath;
  final String? bio;
  final String? location;
  final String? pinnedTweetIdStr;
  final String? parodyCommentaryFanLabel;
  final String? birthdateYear;
  final String? birthdateMonth;
  final String? birthdateDay;
  final String? automatedScreenName;
  final String? joinedTime;
  final String? link;
  final bool isVerified;
  final bool isProtected;
  final int followersCount;
  final int followingCount;
  final int statusesCount;
  final int listedCount;
  final int favouritesCount;
  final int mediaCount;
  final bool isFollowing;
  final bool isFollower;
  final bool canDm;
  final bool canMediaTag;

  const TwitterUser({
    required this.restId,
    required this.screenName,
    this.name,
    this.avatarUrl,
    this.avatarLocalPath,
    this.bannerUrl,
    this.bannerLocalPath,
    this.bio,
    this.location,
    this.pinnedTweetIdStr,
    this.parodyCommentaryFanLabel,
    this.birthdateYear,
    this.birthdateMonth,
    this.birthdateDay,
    this.automatedScreenName,
    this.joinedTime,
    this.link,
    this.isVerified = false,
    this.isProtected = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.statusesCount = 0,
    this.listedCount = 0,
    this.favouritesCount = 0,
    this.mediaCount = 0,
    this.isFollowing = false,
    this.isFollower = false,
    this.canDm = false,
    this.canMediaTag = false,
  });

  factory TwitterUser.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return TwitterUser(
      restId: json['rest_id']?.toString() ?? '',
      name: json['name'] as String?,
      screenName: json['screen_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarLocalPath: json['avatar_local_path'] as String?,
      bannerUrl: json['banner_url'] as String?,
      bannerLocalPath: json['banner_local_path'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      pinnedTweetIdStr: json['pinned_tweet_id_str'] as String?,
      parodyCommentaryFanLabel: json['parody_commentary_fan_label'] as String?,
      birthdateYear: json['birthdate_year'] as String?,
      birthdateMonth: json['birthdate_month'] as String?,
      birthdateDay: json['birthdate_day'] as String?,
      automatedScreenName: json['automated_screen_name'] as String?,
      joinedTime: json['joined_time'] as String?,
      link: json['link'] as String?,
      isVerified: parseBool(json['is_verified']),
      isProtected: parseBool(json['is_protected']),
      followersCount: parseInt(json['followers_count']),
      followingCount: parseInt(json['following_count']),
      statusesCount: parseInt(json['statuses_count']),
      listedCount: parseInt(json['listed_count']),
      favouritesCount: parseInt(json['favourites_count']),
      mediaCount: parseInt(json['media_count']),
      isFollowing: parseBool(json['is_following']),
      isFollower: parseBool(json['is_follower']),
      canDm: parseBool(json['can_dm']),
      canMediaTag: parseBool(json['can_media_tag']),
    );
  }

  factory TwitterUser.fromV1(Map<String, dynamic> raw, String runId) {
    // Helper parsers
    bool getBool(String key) => raw[key] == true || raw[key] == 'true';
    int getInt(String key) => int.tryParse(raw[key]?.toString() ?? '0') ?? 0;
    String? getString(String key) => raw[key] as String?;

    return TwitterUser(
      restId: getString('id_str') ?? '',
      name: getString('name'),
      screenName: getString('screen_name'),
      avatarUrl: getString('profile_image_url_https'),
      avatarLocalPath: null,
      bannerUrl: getString('profile_banner_url'),
      bannerLocalPath: null,
      bio: getString('description'),
      location: getString('location'),
      pinnedTweetIdStr: (raw['pinned_tweet_ids_str'] as List?)?.firstOrNull
          ?.toString(),
      joinedTime: getString('created_at'),
      link:
          (raw['entities']?['url']?['urls'] as List?)
                  ?.firstOrNull?['expanded_url']
              as String? ??
          getString('url'),
      isVerified: getBool('verified') == true,
      isProtected: getBool('protected') == true,
      followersCount: getInt('followers_count'),
      followingCount: getInt('friends_count'),
      statusesCount: getInt('statuses_count'),
      listedCount: getInt('listed_count'),
      favouritesCount: getInt('favourites_count'),
      mediaCount: getInt('media_count'),
      isFollowing: getBool('following') == true,
      isFollower: getBool('followed_by') == true,
      canDm: getBool('can_dm') == true,
      canMediaTag: getBool('can_media_tag') == true,
    );
  }

  factory TwitterUser.fromGraphQL(Map<String, dynamic> raw, String runId) {
    final result = raw['result'] ?? raw;
    final legacy = result['legacy'] ?? {};
    final core = result['core'] ?? {};

    final relationship = result['relationship_perspectives'] ?? {};
    final dm = result['dm_permissions'] ?? {};
    final media = result['media_permissions'] ?? {};

    int getInt(String key) => int.tryParse(legacy[key]?.toString() ?? '0') ?? 0;
    String? getString(String key) => legacy[key] as String?;

    return TwitterUser(
      restId: result['rest_id']?.toString() ?? '',
      name: core['name'] as String?,
      screenName: core['screen_name'] as String?,
      avatarUrl: result['avatar']?['image_url'] as String?,
      avatarLocalPath: null,
      bannerUrl: legacy['profile_banner_url'] as String?,
      bannerLocalPath: null,
      bio: legacy['description'],
      location: result['location']?['location'] as String?,
      pinnedTweetIdStr: (legacy['pinned_tweet_ids_str'] as List?)?.firstOrNull
          ?.toString(),
      joinedTime: core['created_at'] as String?,
      link:
          (legacy['entities']?['url']?['urls'] as List?)
                  ?.cast<Map>()
                  .firstWhere(
                    (e) => e['indices']?.join(',') == '0,23',
                    orElse: () => {},
                  )['expanded_url']
              as String? ??
          getString('url'),

      isVerified: result['is_blue_verified'] == true,
      isProtected: result['privacy']?['protected'] == true,
      followersCount: getInt('followers_count'),
      followingCount: getInt('friends_count'),
      statusesCount: getInt('statuses_count'),
      listedCount: getInt('listed_count'),
      favouritesCount: getInt('favourites_count'),
      mediaCount: getInt('media_count'),
      isFollowing: relationship['following'] == true,
      isFollower: relationship['followed_by'] == true,
      canDm: dm['can_dm'] == true,
      canMediaTag: media['can_media_tag'] == true,
      parodyCommentaryFanLabel: result['parody_commentary_fan_label']?.toString(),
      automatedScreenName:
          (result['affiliates_highlighted_label']?['label']?['longDescription']?['entities']
                      as List?)
                  ?.first?['ref']?['mention_results']?['result']?['core']?['screen_name']
              as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rest_id': restId,
      'name': name,
      'screen_name': screenName,
      'avatar_url': avatarUrl,
      'avatar_local_path': avatarLocalPath,
      'banner_url': bannerUrl,
      'banner_local_path': bannerLocalPath,
      'bio': bio,
      'location': location,
      'pinned_tweet_id_str': pinnedTweetIdStr,
      'parody_commentary_fan_label': parodyCommentaryFanLabel,
      'birthdate_year': birthdateYear,
      'birthdate_month': birthdateMonth,
      'birthdate_day': birthdateDay,
      'automated_screen_name': automatedScreenName,
      'joined_time': joinedTime,
      'link': link,
      'is_verified': isVerified,
      'is_protected': isProtected,
      'followers_count': followersCount,
      'following_count': followingCount,
      'statuses_count': statusesCount,
      'listed_count': listedCount,
      'favourites_count': favouritesCount,
      'media_count': mediaCount,
      'is_following': isFollowing,
      'is_follower': isFollower,
      'can_dm': canDm,
      'can_media_tag': canMediaTag,
    };
  }
}
