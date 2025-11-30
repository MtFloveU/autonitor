class TwitterUser {
  final String restId;
  final String? name;
  final String? screenName;
  final String? avatarUrl;
  final String? avatarLocalPath;
  final String? bannerUrl;
  final String? bannerLocalPath;
  final String? bio;
  final List<Map<String, String>> bioLinks;
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
    this.bioLinks = const [],
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
      bioLinks:
          (json['bio_links'] as List?)
              ?.map((e) => Map<String, String>.from(e))
              .toList() ??
          const [],
    );
  }

  factory TwitterUser.fromV1(Map<String, dynamic> raw, String runId) {
    bool getBool(String key) => raw[key] == true || raw[key] == 'true';
    int getInt(String key) => int.tryParse(raw[key]?.toString() ?? '0') ?? 0;
    String? getString(String key) => raw[key] as String?;

    String? description = getString('description');

    // [修复] 1. 统一获取 URL 列表，确保不为空
    final List descUrlList =
        (raw['entities']?['description']?['urls'] as List?) ?? [];

    // [修复] 2. 提前定义 extractedLinks，确保作用域覆盖整个方法
    final List<Map<String, String>> extractedLinks = [];

    // [修复] 3. 提取链接逻辑 (先提取，保证数据纯净)
    if (descUrlList.isNotEmpty) {
      for (final entry in descUrlList) {
        final String? expanded = entry['expanded_url']?.toString();
        if (expanded != null && expanded.isNotEmpty) {
          extractedLinks.add({'expanded_url': expanded});
        }
      }
    }

    // [逻辑保持] 4. 简介文本替换逻辑 (用于显示 expanded_url)
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
      bioLinks: extractedLinks, // [修复] 5. 确保传入 extractedLinks
      location: getString('location'),
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

  // [新增] 专门用于处理 UserByRestId 接口的深层嵌套结构
  factory TwitterUser.fromUserByRestId(Map<String, dynamic> raw) {
    // 1. 逐层拆解 JSON 结构
    final data = raw['data'];
    final user = (data is Map) ? data['user'] : null;
    final result = (user is Map) ? user['result'] : null;

    // 2. 异常处理：如果数据为空
    if (result == null || result is! Map<String, dynamic>) {
      // 返回一个空的安全对象，避免空指针崩溃
      return const TwitterUser(
        restId: '',
        screenName: 'Unknown',
        name: 'Unknown',
      );
    }

    // 3. 异常处理：如果是 UserUnavailable (账号被封禁或注销)
    if (result['__typename'] == 'UserUnavailable') {
      return const TwitterUser(
        restId: '',
        screenName: 'Unavailable',
        name: 'User Unavailable',
        status: 'unavailable',
      );
    }

    // 4. 核心复用：将提取出的 result 传给 fromGraphQL 进行通用解析
    return TwitterUser.fromGraphQL(result, '');
  }

  // [修改] 增强版 fromGraphQL：集成了 bioLinks 和 生日解析
  factory TwitterUser.fromGraphQL(Map<String, dynamic> raw, String runId) {
    // 兼容逻辑：如果 raw 本身就是 result 层，则直接使用；否则尝试查找 result 字段
    final result = raw['result'] ?? raw;

    final legacy = (result['legacy'] ?? {}) as Map<String, dynamic>;
    final core = (result['core'] ?? {}) as Map<String, dynamic>;
    final relationship =
        (result['relationship_perspectives'] ?? {}) as Map<String, dynamic>;
    final dm = (result['dm_permissions'] ?? {}) as Map<String, dynamic>;
    final media = (result['media_permissions'] ?? {}) as Map<String, dynamic>;

    int getInt(String key) => int.tryParse(legacy[key]?.toString() ?? '0') ?? 0;
    String? getString(String key) => legacy[key] as String?;

    // --- 1. 生日解析 (Birthdate) [新增] ---
    // 路径: result -> legacy_extended_profile -> birthdate
    final birthdateObj = result['legacy_extended_profile']?['birthdate'];
    String? bYear;
    String? bMonth;
    String? bDay;

    if (birthdateObj is Map) {
      bYear = birthdateObj['year']?.toString();
      bMonth = birthdateObj['month']?.toString();
      bDay = birthdateObj['day']?.toString();
    }
    // ------------------------------------

    // --- 2. 简介 (Bio) 和 链接提取 (BioLinks) ---
    String? description = legacy['description'] as String?;
    description ??=
        (result['profile_bio']?['description'] as String?) ?? description;

    // 2.1 统一获取 URL 列表
    final List descUrlList =
        (legacy['entities']?['description']?['urls'] as List?) ?? [];

    // 2.2 提取 bioLinks (优先提取，保持数据纯净)
    final List<Map<String, String>> extractedLinks = [];
    if (descUrlList.isNotEmpty) {
      for (final entry in descUrlList) {
        final String? expanded = entry['expanded_url']?.toString();
        if (expanded != null && expanded.isNotEmpty) {
          extractedLinks.add({'expanded_url': expanded});
        }
      }
    }

    // 2.3 替换简介文本中的 t.co 链接
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

    // --- 3. 其他字段解析 ---
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
      bioLinks: extractedLinks, // 传入提取的链接
      location: result['location']?['location'] as String?,
      pinnedTweetIdStr:
          (legacy['pinned_tweet_ids_str'] as List?)?.isNotEmpty == true
          ? (legacy['pinned_tweet_ids_str'] as List).first?.toString()
          : null,
      // 传入解析的生日信息
      birthdateYear: bYear,
      birthdateMonth: bMonth,
      birthdateDay: bDay,

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
      'bio_links': bioLinks,
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
    List<Map<String, String>>? bioLinks,
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
      bioLinks: bioLinks ?? this.bioLinks,
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
