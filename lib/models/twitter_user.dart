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
  final String? status;
  final String? keptIdsStatus;
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
    this.status,
    this.keptIdsStatus,
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
    return TwitterUser(
      restId: json['rest_id'] as String? ?? '',
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
      isVerified: json['is_verified'] as bool? ?? false,
      isProtected: json['is_protected'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      statusesCount: json['statuses_count'] as int? ?? 0,
      listedCount: json['listed_count'] as int? ?? 0,
      favouritesCount: json['favourites_count'] as int? ?? 0,
      mediaCount: json['media_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
      isFollower: json['is_follower'] as bool? ?? false,
      canDm: json['can_dm'] as bool? ?? false,
      canMediaTag: json['can_media_tag'] as bool? ?? false,
      status: json['status'] as String? ?? 'normal',
      keptIdsStatus: json['kept_ids_status'] as String? ?? 'normal',
    );
  }

  factory TwitterUser.fromV1(Map<String, dynamic> raw, String runId) {
    bool getBool(String key) => raw[key] == true || raw[key] == 'true';
    int getInt(String key) => int.tryParse(raw[key]?.toString() ?? '0') ?? 0;
    String? getString(String key) => raw[key] as String?;

    String? description = getString('description');
    final List descUrlList =
        (raw['entities']?['description']?['urls'] as List?) ?? [];
    if (description != null && descUrlList.isNotEmpty) {
      for (final urlEntry in descUrlList) {
        final String? shortUrl = urlEntry['url'] as String?;
        final String? expanded =
            urlEntry['expanded_url'] as String? ??
            urlEntry['display_url'] as String?;
        if (shortUrl != null && expanded != null && shortUrl != expanded) {
          description = description?.replaceAll(shortUrl, expanded);
        }
      }
      description = description?.trim();
    }

    return TwitterUser(
      restId: getString('id_str') ?? '',
      name: getString('name'),
      screenName: getString('screen_name'),
      avatarUrl: getString('profile_image_url_https'),
      avatarLocalPath: null,
      bannerUrl: getString('profile_banner_url'),
      bannerLocalPath: null,
      bio: description,
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
    final legacy = (result['legacy'] ?? {}) as Map<String, dynamic>;
    final core = (result['core'] ?? {}) as Map<String, dynamic>;
    final relationship =
        (result['relationship_perspectives'] ?? {}) as Map<String, dynamic>;
    final dm = (result['dm_permissions'] ?? {}) as Map<String, dynamic>;
    final media = (result['media_permissions'] ?? {}) as Map<String, dynamic>;

    int getInt(String key) => int.tryParse(legacy[key]?.toString() ?? '0') ?? 0;
    String? getString(String key) => legacy[key] as String?;

    String? description = legacy['description'] as String?;
    description ??=
        (result['profile_bio']?['description'] as String?) ?? description;
    final List descUrlList =
        (legacy['entities']?['description']?['urls'] as List?) ?? [];
    if (description != null && descUrlList.isNotEmpty) {
      for (final urlEntry in descUrlList) {
        final String? shortUrl = urlEntry['url'] as String?;
        final String? expanded =
            urlEntry['expanded_url'] as String? ??
            urlEntry['display_url'] as String?;
        if (shortUrl != null && expanded != null && shortUrl != expanded) {
          description = description?.replaceAll(shortUrl, expanded);
        }
      }
      description = description?.trim();
    }

    String? link;
    final List urlEntities =
        (legacy['entities']?['url']?['urls'] as List?) ?? [];
    if (urlEntities.isNotEmpty) {
      final first = urlEntities.firstWhere(
        (e) => e is Map && e['expanded_url'] != null,
        orElse: () => null,
      );
      if (first != null && first is Map) {
        link = first['expanded_url'] as String?;
      }
    }
    link = link ?? getString('url');

    return TwitterUser(
      restId: result['rest_id']?.toString() ?? '',
      name: core['name'] as String?,
      screenName: core['screen_name'] as String?,
      avatarUrl: result['avatar']?['image_url'] as String?,
      avatarLocalPath: null,
      bannerUrl: legacy['profile_banner_url'] as String?,
      bannerLocalPath: null,
      bio: description,
      location: result['location']?['location'] as String?,
      pinnedTweetIdStr:
          (legacy['pinned_tweet_ids_str'] as List?)?.isNotEmpty == true
          ? (legacy['pinned_tweet_ids_str'] as List).first?.toString()
          : null,
      joinedTime: core['created_at'] as String?,
      link: link,
      isVerified:
          (result['is_blue_verified'] == true) ||
          (result['verification']?['verified'] == true),
      isProtected:
          (result['privacy']?['protected'] == true) ||
          (legacy['protected'] == true),
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
      parodyCommentaryFanLabel: result['parody_commentary_fan_label']
          ?.toString(),
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
      'status': status,
      'kept_ids_status': keptIdsStatus,
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

  TwitterUser copyWith({
    String? restId,
    String? name,
    String? screenName,
    String? avatarUrl,
    String? avatarLocalPath,
    String? bannerUrl,
    String? bannerLocalPath,
    String? bio,
    String? location,
    String? pinnedTweetIdStr,
    String? parodyCommentaryFanLabel,
    String? birthdateYear,
    String? birthdateMonth,
    String? birthdateDay,
    String? automatedScreenName,
    String? joinedTime,
    String? link,
    String? status,
    String? keptIdsStatus,
    bool? isVerified,
    bool? isProtected,
    int? followersCount,
    int? followingCount,
    int? statusesCount,
    int? listedCount,
    int? favouritesCount,
    int? mediaCount,
    bool? isFollowing,
    bool? isFollower,
    bool? canDm,
    bool? canMediaTag,
  }) {
    return TwitterUser(
      restId: restId ?? this.restId,
      name: name ?? this.name,
      screenName: screenName ?? this.screenName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerLocalPath: bannerLocalPath ?? this.bannerLocalPath,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      pinnedTweetIdStr: pinnedTweetIdStr ?? this.pinnedTweetIdStr,
      parodyCommentaryFanLabel:
          parodyCommentaryFanLabel ?? this.parodyCommentaryFanLabel,
      birthdateYear: birthdateYear ?? this.birthdateYear,
      birthdateMonth: birthdateMonth ?? this.birthdateMonth,
      birthdateDay: birthdateDay ?? this.birthdateDay,
      automatedScreenName: automatedScreenName ?? this.automatedScreenName,
      joinedTime: joinedTime ?? this.joinedTime,
      link: link ?? this.link,
      status: status ?? this.status,
      keptIdsStatus: keptIdsStatus ?? this.keptIdsStatus,
      isVerified: isVerified ?? this.isVerified,
      isProtected: isProtected ?? this.isProtected,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      statusesCount: statusesCount ?? this.statusesCount,
      listedCount: listedCount ?? this.listedCount,
      favouritesCount: favouritesCount ?? this.favouritesCount,
      mediaCount: mediaCount ?? this.mediaCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
      canDm: canDm ?? this.canDm,
      canMediaTag: canMediaTag ?? this.canMediaTag,
    );
  }
}
