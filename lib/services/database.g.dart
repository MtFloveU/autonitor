// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LoggedAccountsTable extends LoggedAccounts
    with TableInfo<$LoggedAccountsTable, LoggedAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoggedAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _screenNameMeta = const VerificationMeta(
    'screenName',
  );
  @override
  late final GeneratedColumn<String> screenName = GeneratedColumn<String>(
    'screen_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _joinTimeMeta = const VerificationMeta(
    'joinTime',
  );
  @override
  late final GeneratedColumn<String> joinTime = GeneratedColumn<String>(
    'join_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isVerifiedMeta = const VerificationMeta(
    'isVerified',
  );
  @override
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
    'is_verified',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isProtectedMeta = const VerificationMeta(
    'isProtected',
  );
  @override
  late final GeneratedColumn<bool> isProtected = GeneratedColumn<bool>(
    'is_protected',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_protected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _followersCountMeta = const VerificationMeta(
    'followersCount',
  );
  @override
  late final GeneratedColumn<int> followersCount = GeneratedColumn<int>(
    'followers_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _followingCountMeta = const VerificationMeta(
    'followingCount',
  );
  @override
  late final GeneratedColumn<int> followingCount = GeneratedColumn<int>(
    'following_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusesCountMeta = const VerificationMeta(
    'statusesCount',
  );
  @override
  late final GeneratedColumn<int> statusesCount = GeneratedColumn<int>(
    'statuses_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mediaCountMeta = const VerificationMeta(
    'mediaCount',
  );
  @override
  late final GeneratedColumn<int> mediaCount = GeneratedColumn<int>(
    'media_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _favouritesCountMeta = const VerificationMeta(
    'favouritesCount',
  );
  @override
  late final GeneratedColumn<int> favouritesCount = GeneratedColumn<int>(
    'favourites_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _listedCountMeta = const VerificationMeta(
    'listedCount',
  );
  @override
  late final GeneratedColumn<int> listedCount = GeneratedColumn<int>(
    'listed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _latestRawJsonMeta = const VerificationMeta(
    'latestRawJson',
  );
  @override
  late final GeneratedColumn<String> latestRawJson = GeneratedColumn<String>(
    'latest_raw_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerUrlMeta = const VerificationMeta(
    'bannerUrl',
  );
  @override
  late final GeneratedColumn<String> bannerUrl = GeneratedColumn<String>(
    'banner_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarLocalPathMeta = const VerificationMeta(
    'avatarLocalPath',
  );
  @override
  late final GeneratedColumn<String> avatarLocalPath = GeneratedColumn<String>(
    'avatar_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerLocalPathMeta = const VerificationMeta(
    'bannerLocalPath',
  );
  @override
  late final GeneratedColumn<String> bannerLocalPath = GeneratedColumn<String>(
    'banner_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    screenName,
    bio,
    location,
    link,
    joinTime,
    isVerified,
    isProtected,
    followersCount,
    followingCount,
    statusesCount,
    mediaCount,
    favouritesCount,
    listedCount,
    latestRawJson,
    avatarUrl,
    bannerUrl,
    avatarLocalPath,
    bannerLocalPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'logged_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoggedAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('screen_name')) {
      context.handle(
        _screenNameMeta,
        screenName.isAcceptableOrUnknown(data['screen_name']!, _screenNameMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    }
    if (data.containsKey('join_time')) {
      context.handle(
        _joinTimeMeta,
        joinTime.isAcceptableOrUnknown(data['join_time']!, _joinTimeMeta),
      );
    }
    if (data.containsKey('is_verified')) {
      context.handle(
        _isVerifiedMeta,
        isVerified.isAcceptableOrUnknown(data['is_verified']!, _isVerifiedMeta),
      );
    }
    if (data.containsKey('is_protected')) {
      context.handle(
        _isProtectedMeta,
        isProtected.isAcceptableOrUnknown(
          data['is_protected']!,
          _isProtectedMeta,
        ),
      );
    }
    if (data.containsKey('followers_count')) {
      context.handle(
        _followersCountMeta,
        followersCount.isAcceptableOrUnknown(
          data['followers_count']!,
          _followersCountMeta,
        ),
      );
    }
    if (data.containsKey('following_count')) {
      context.handle(
        _followingCountMeta,
        followingCount.isAcceptableOrUnknown(
          data['following_count']!,
          _followingCountMeta,
        ),
      );
    }
    if (data.containsKey('statuses_count')) {
      context.handle(
        _statusesCountMeta,
        statusesCount.isAcceptableOrUnknown(
          data['statuses_count']!,
          _statusesCountMeta,
        ),
      );
    }
    if (data.containsKey('media_count')) {
      context.handle(
        _mediaCountMeta,
        mediaCount.isAcceptableOrUnknown(data['media_count']!, _mediaCountMeta),
      );
    }
    if (data.containsKey('favourites_count')) {
      context.handle(
        _favouritesCountMeta,
        favouritesCount.isAcceptableOrUnknown(
          data['favourites_count']!,
          _favouritesCountMeta,
        ),
      );
    }
    if (data.containsKey('listed_count')) {
      context.handle(
        _listedCountMeta,
        listedCount.isAcceptableOrUnknown(
          data['listed_count']!,
          _listedCountMeta,
        ),
      );
    }
    if (data.containsKey('latest_raw_json')) {
      context.handle(
        _latestRawJsonMeta,
        latestRawJson.isAcceptableOrUnknown(
          data['latest_raw_json']!,
          _latestRawJsonMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('banner_url')) {
      context.handle(
        _bannerUrlMeta,
        bannerUrl.isAcceptableOrUnknown(data['banner_url']!, _bannerUrlMeta),
      );
    }
    if (data.containsKey('avatar_local_path')) {
      context.handle(
        _avatarLocalPathMeta,
        avatarLocalPath.isAcceptableOrUnknown(
          data['avatar_local_path']!,
          _avatarLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('banner_local_path')) {
      context.handle(
        _bannerLocalPathMeta,
        bannerLocalPath.isAcceptableOrUnknown(
          data['banner_local_path']!,
          _bannerLocalPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoggedAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoggedAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      screenName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screen_name'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      ),
      joinTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}join_time'],
      ),
      isVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_verified'],
      ),
      isProtected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_protected'],
      ),
      followersCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}followers_count'],
      )!,
      followingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}following_count'],
      )!,
      statusesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statuses_count'],
      )!,
      mediaCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_count'],
      )!,
      favouritesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}favourites_count'],
      )!,
      listedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listed_count'],
      )!,
      latestRawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_raw_json'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      bannerUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_url'],
      ),
      avatarLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_local_path'],
      ),
      bannerLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_local_path'],
      ),
    );
  }

  @override
  $LoggedAccountsTable createAlias(String alias) {
    return $LoggedAccountsTable(attachedDatabase, alias);
  }
}

class LoggedAccount extends DataClass implements Insertable<LoggedAccount> {
  final String id;
  final String? name;
  final String? screenName;
  final String? bio;
  final String? location;
  final String? link;
  final String? joinTime;
  final bool? isVerified;
  final bool? isProtected;
  final int followersCount;
  final int followingCount;
  final int statusesCount;
  final int mediaCount;
  final int favouritesCount;
  final int listedCount;
  final String? latestRawJson;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? avatarLocalPath;
  final String? bannerLocalPath;
  const LoggedAccount({
    required this.id,
    this.name,
    this.screenName,
    this.bio,
    this.location,
    this.link,
    this.joinTime,
    this.isVerified,
    this.isProtected,
    required this.followersCount,
    required this.followingCount,
    required this.statusesCount,
    required this.mediaCount,
    required this.favouritesCount,
    required this.listedCount,
    this.latestRawJson,
    this.avatarUrl,
    this.bannerUrl,
    this.avatarLocalPath,
    this.bannerLocalPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || screenName != null) {
      map['screen_name'] = Variable<String>(screenName);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || link != null) {
      map['link'] = Variable<String>(link);
    }
    if (!nullToAbsent || joinTime != null) {
      map['join_time'] = Variable<String>(joinTime);
    }
    if (!nullToAbsent || isVerified != null) {
      map['is_verified'] = Variable<bool>(isVerified);
    }
    if (!nullToAbsent || isProtected != null) {
      map['is_protected'] = Variable<bool>(isProtected);
    }
    map['followers_count'] = Variable<int>(followersCount);
    map['following_count'] = Variable<int>(followingCount);
    map['statuses_count'] = Variable<int>(statusesCount);
    map['media_count'] = Variable<int>(mediaCount);
    map['favourites_count'] = Variable<int>(favouritesCount);
    map['listed_count'] = Variable<int>(listedCount);
    if (!nullToAbsent || latestRawJson != null) {
      map['latest_raw_json'] = Variable<String>(latestRawJson);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || bannerUrl != null) {
      map['banner_url'] = Variable<String>(bannerUrl);
    }
    if (!nullToAbsent || avatarLocalPath != null) {
      map['avatar_local_path'] = Variable<String>(avatarLocalPath);
    }
    if (!nullToAbsent || bannerLocalPath != null) {
      map['banner_local_path'] = Variable<String>(bannerLocalPath);
    }
    return map;
  }

  LoggedAccountsCompanion toCompanion(bool nullToAbsent) {
    return LoggedAccountsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      screenName: screenName == null && nullToAbsent
          ? const Value.absent()
          : Value(screenName),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      link: link == null && nullToAbsent ? const Value.absent() : Value(link),
      joinTime: joinTime == null && nullToAbsent
          ? const Value.absent()
          : Value(joinTime),
      isVerified: isVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(isVerified),
      isProtected: isProtected == null && nullToAbsent
          ? const Value.absent()
          : Value(isProtected),
      followersCount: Value(followersCount),
      followingCount: Value(followingCount),
      statusesCount: Value(statusesCount),
      mediaCount: Value(mediaCount),
      favouritesCount: Value(favouritesCount),
      listedCount: Value(listedCount),
      latestRawJson: latestRawJson == null && nullToAbsent
          ? const Value.absent()
          : Value(latestRawJson),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      bannerUrl: bannerUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerUrl),
      avatarLocalPath: avatarLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarLocalPath),
      bannerLocalPath: bannerLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerLocalPath),
    );
  }

  factory LoggedAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoggedAccount(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      screenName: serializer.fromJson<String?>(json['screenName']),
      bio: serializer.fromJson<String?>(json['bio']),
      location: serializer.fromJson<String?>(json['location']),
      link: serializer.fromJson<String?>(json['link']),
      joinTime: serializer.fromJson<String?>(json['joinTime']),
      isVerified: serializer.fromJson<bool?>(json['isVerified']),
      isProtected: serializer.fromJson<bool?>(json['isProtected']),
      followersCount: serializer.fromJson<int>(json['followersCount']),
      followingCount: serializer.fromJson<int>(json['followingCount']),
      statusesCount: serializer.fromJson<int>(json['statusesCount']),
      mediaCount: serializer.fromJson<int>(json['mediaCount']),
      favouritesCount: serializer.fromJson<int>(json['favouritesCount']),
      listedCount: serializer.fromJson<int>(json['listedCount']),
      latestRawJson: serializer.fromJson<String?>(json['latestRawJson']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      bannerUrl: serializer.fromJson<String?>(json['bannerUrl']),
      avatarLocalPath: serializer.fromJson<String?>(json['avatarLocalPath']),
      bannerLocalPath: serializer.fromJson<String?>(json['bannerLocalPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'screenName': serializer.toJson<String?>(screenName),
      'bio': serializer.toJson<String?>(bio),
      'location': serializer.toJson<String?>(location),
      'link': serializer.toJson<String?>(link),
      'joinTime': serializer.toJson<String?>(joinTime),
      'isVerified': serializer.toJson<bool?>(isVerified),
      'isProtected': serializer.toJson<bool?>(isProtected),
      'followersCount': serializer.toJson<int>(followersCount),
      'followingCount': serializer.toJson<int>(followingCount),
      'statusesCount': serializer.toJson<int>(statusesCount),
      'mediaCount': serializer.toJson<int>(mediaCount),
      'favouritesCount': serializer.toJson<int>(favouritesCount),
      'listedCount': serializer.toJson<int>(listedCount),
      'latestRawJson': serializer.toJson<String?>(latestRawJson),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'bannerUrl': serializer.toJson<String?>(bannerUrl),
      'avatarLocalPath': serializer.toJson<String?>(avatarLocalPath),
      'bannerLocalPath': serializer.toJson<String?>(bannerLocalPath),
    };
  }

  LoggedAccount copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> screenName = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> link = const Value.absent(),
    Value<String?> joinTime = const Value.absent(),
    Value<bool?> isVerified = const Value.absent(),
    Value<bool?> isProtected = const Value.absent(),
    int? followersCount,
    int? followingCount,
    int? statusesCount,
    int? mediaCount,
    int? favouritesCount,
    int? listedCount,
    Value<String?> latestRawJson = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> bannerUrl = const Value.absent(),
    Value<String?> avatarLocalPath = const Value.absent(),
    Value<String?> bannerLocalPath = const Value.absent(),
  }) => LoggedAccount(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    screenName: screenName.present ? screenName.value : this.screenName,
    bio: bio.present ? bio.value : this.bio,
    location: location.present ? location.value : this.location,
    link: link.present ? link.value : this.link,
    joinTime: joinTime.present ? joinTime.value : this.joinTime,
    isVerified: isVerified.present ? isVerified.value : this.isVerified,
    isProtected: isProtected.present ? isProtected.value : this.isProtected,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount ?? this.followingCount,
    statusesCount: statusesCount ?? this.statusesCount,
    mediaCount: mediaCount ?? this.mediaCount,
    favouritesCount: favouritesCount ?? this.favouritesCount,
    listedCount: listedCount ?? this.listedCount,
    latestRawJson: latestRawJson.present
        ? latestRawJson.value
        : this.latestRawJson,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    bannerUrl: bannerUrl.present ? bannerUrl.value : this.bannerUrl,
    avatarLocalPath: avatarLocalPath.present
        ? avatarLocalPath.value
        : this.avatarLocalPath,
    bannerLocalPath: bannerLocalPath.present
        ? bannerLocalPath.value
        : this.bannerLocalPath,
  );
  LoggedAccount copyWithCompanion(LoggedAccountsCompanion data) {
    return LoggedAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      screenName: data.screenName.present
          ? data.screenName.value
          : this.screenName,
      bio: data.bio.present ? data.bio.value : this.bio,
      location: data.location.present ? data.location.value : this.location,
      link: data.link.present ? data.link.value : this.link,
      joinTime: data.joinTime.present ? data.joinTime.value : this.joinTime,
      isVerified: data.isVerified.present
          ? data.isVerified.value
          : this.isVerified,
      isProtected: data.isProtected.present
          ? data.isProtected.value
          : this.isProtected,
      followersCount: data.followersCount.present
          ? data.followersCount.value
          : this.followersCount,
      followingCount: data.followingCount.present
          ? data.followingCount.value
          : this.followingCount,
      statusesCount: data.statusesCount.present
          ? data.statusesCount.value
          : this.statusesCount,
      mediaCount: data.mediaCount.present
          ? data.mediaCount.value
          : this.mediaCount,
      favouritesCount: data.favouritesCount.present
          ? data.favouritesCount.value
          : this.favouritesCount,
      listedCount: data.listedCount.present
          ? data.listedCount.value
          : this.listedCount,
      latestRawJson: data.latestRawJson.present
          ? data.latestRawJson.value
          : this.latestRawJson,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      bannerUrl: data.bannerUrl.present ? data.bannerUrl.value : this.bannerUrl,
      avatarLocalPath: data.avatarLocalPath.present
          ? data.avatarLocalPath.value
          : this.avatarLocalPath,
      bannerLocalPath: data.bannerLocalPath.present
          ? data.bannerLocalPath.value
          : this.bannerLocalPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoggedAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('screenName: $screenName, ')
          ..write('bio: $bio, ')
          ..write('location: $location, ')
          ..write('link: $link, ')
          ..write('joinTime: $joinTime, ')
          ..write('isVerified: $isVerified, ')
          ..write('isProtected: $isProtected, ')
          ..write('followersCount: $followersCount, ')
          ..write('followingCount: $followingCount, ')
          ..write('statusesCount: $statusesCount, ')
          ..write('mediaCount: $mediaCount, ')
          ..write('favouritesCount: $favouritesCount, ')
          ..write('listedCount: $listedCount, ')
          ..write('latestRawJson: $latestRawJson, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('avatarLocalPath: $avatarLocalPath, ')
          ..write('bannerLocalPath: $bannerLocalPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    screenName,
    bio,
    location,
    link,
    joinTime,
    isVerified,
    isProtected,
    followersCount,
    followingCount,
    statusesCount,
    mediaCount,
    favouritesCount,
    listedCount,
    latestRawJson,
    avatarUrl,
    bannerUrl,
    avatarLocalPath,
    bannerLocalPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoggedAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.screenName == this.screenName &&
          other.bio == this.bio &&
          other.location == this.location &&
          other.link == this.link &&
          other.joinTime == this.joinTime &&
          other.isVerified == this.isVerified &&
          other.isProtected == this.isProtected &&
          other.followersCount == this.followersCount &&
          other.followingCount == this.followingCount &&
          other.statusesCount == this.statusesCount &&
          other.mediaCount == this.mediaCount &&
          other.favouritesCount == this.favouritesCount &&
          other.listedCount == this.listedCount &&
          other.latestRawJson == this.latestRawJson &&
          other.avatarUrl == this.avatarUrl &&
          other.bannerUrl == this.bannerUrl &&
          other.avatarLocalPath == this.avatarLocalPath &&
          other.bannerLocalPath == this.bannerLocalPath);
}

class LoggedAccountsCompanion extends UpdateCompanion<LoggedAccount> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> screenName;
  final Value<String?> bio;
  final Value<String?> location;
  final Value<String?> link;
  final Value<String?> joinTime;
  final Value<bool?> isVerified;
  final Value<bool?> isProtected;
  final Value<int> followersCount;
  final Value<int> followingCount;
  final Value<int> statusesCount;
  final Value<int> mediaCount;
  final Value<int> favouritesCount;
  final Value<int> listedCount;
  final Value<String?> latestRawJson;
  final Value<String?> avatarUrl;
  final Value<String?> bannerUrl;
  final Value<String?> avatarLocalPath;
  final Value<String?> bannerLocalPath;
  final Value<int> rowid;
  const LoggedAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.screenName = const Value.absent(),
    this.bio = const Value.absent(),
    this.location = const Value.absent(),
    this.link = const Value.absent(),
    this.joinTime = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.followersCount = const Value.absent(),
    this.followingCount = const Value.absent(),
    this.statusesCount = const Value.absent(),
    this.mediaCount = const Value.absent(),
    this.favouritesCount = const Value.absent(),
    this.listedCount = const Value.absent(),
    this.latestRawJson = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.avatarLocalPath = const Value.absent(),
    this.bannerLocalPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoggedAccountsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.screenName = const Value.absent(),
    this.bio = const Value.absent(),
    this.location = const Value.absent(),
    this.link = const Value.absent(),
    this.joinTime = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.followersCount = const Value.absent(),
    this.followingCount = const Value.absent(),
    this.statusesCount = const Value.absent(),
    this.mediaCount = const Value.absent(),
    this.favouritesCount = const Value.absent(),
    this.listedCount = const Value.absent(),
    this.latestRawJson = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.avatarLocalPath = const Value.absent(),
    this.bannerLocalPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<LoggedAccount> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? screenName,
    Expression<String>? bio,
    Expression<String>? location,
    Expression<String>? link,
    Expression<String>? joinTime,
    Expression<bool>? isVerified,
    Expression<bool>? isProtected,
    Expression<int>? followersCount,
    Expression<int>? followingCount,
    Expression<int>? statusesCount,
    Expression<int>? mediaCount,
    Expression<int>? favouritesCount,
    Expression<int>? listedCount,
    Expression<String>? latestRawJson,
    Expression<String>? avatarUrl,
    Expression<String>? bannerUrl,
    Expression<String>? avatarLocalPath,
    Expression<String>? bannerLocalPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (screenName != null) 'screen_name': screenName,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
      if (link != null) 'link': link,
      if (joinTime != null) 'join_time': joinTime,
      if (isVerified != null) 'is_verified': isVerified,
      if (isProtected != null) 'is_protected': isProtected,
      if (followersCount != null) 'followers_count': followersCount,
      if (followingCount != null) 'following_count': followingCount,
      if (statusesCount != null) 'statuses_count': statusesCount,
      if (mediaCount != null) 'media_count': mediaCount,
      if (favouritesCount != null) 'favourites_count': favouritesCount,
      if (listedCount != null) 'listed_count': listedCount,
      if (latestRawJson != null) 'latest_raw_json': latestRawJson,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      if (avatarLocalPath != null) 'avatar_local_path': avatarLocalPath,
      if (bannerLocalPath != null) 'banner_local_path': bannerLocalPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoggedAccountsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? screenName,
    Value<String?>? bio,
    Value<String?>? location,
    Value<String?>? link,
    Value<String?>? joinTime,
    Value<bool?>? isVerified,
    Value<bool?>? isProtected,
    Value<int>? followersCount,
    Value<int>? followingCount,
    Value<int>? statusesCount,
    Value<int>? mediaCount,
    Value<int>? favouritesCount,
    Value<int>? listedCount,
    Value<String?>? latestRawJson,
    Value<String?>? avatarUrl,
    Value<String?>? bannerUrl,
    Value<String?>? avatarLocalPath,
    Value<String?>? bannerLocalPath,
    Value<int>? rowid,
  }) {
    return LoggedAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      screenName: screenName ?? this.screenName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      link: link ?? this.link,
      joinTime: joinTime ?? this.joinTime,
      isVerified: isVerified ?? this.isVerified,
      isProtected: isProtected ?? this.isProtected,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      statusesCount: statusesCount ?? this.statusesCount,
      mediaCount: mediaCount ?? this.mediaCount,
      favouritesCount: favouritesCount ?? this.favouritesCount,
      listedCount: listedCount ?? this.listedCount,
      latestRawJson: latestRawJson ?? this.latestRawJson,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      bannerLocalPath: bannerLocalPath ?? this.bannerLocalPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (screenName.present) {
      map['screen_name'] = Variable<String>(screenName.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (joinTime.present) {
      map['join_time'] = Variable<String>(joinTime.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (isProtected.present) {
      map['is_protected'] = Variable<bool>(isProtected.value);
    }
    if (followersCount.present) {
      map['followers_count'] = Variable<int>(followersCount.value);
    }
    if (followingCount.present) {
      map['following_count'] = Variable<int>(followingCount.value);
    }
    if (statusesCount.present) {
      map['statuses_count'] = Variable<int>(statusesCount.value);
    }
    if (mediaCount.present) {
      map['media_count'] = Variable<int>(mediaCount.value);
    }
    if (favouritesCount.present) {
      map['favourites_count'] = Variable<int>(favouritesCount.value);
    }
    if (listedCount.present) {
      map['listed_count'] = Variable<int>(listedCount.value);
    }
    if (latestRawJson.present) {
      map['latest_raw_json'] = Variable<String>(latestRawJson.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (bannerUrl.present) {
      map['banner_url'] = Variable<String>(bannerUrl.value);
    }
    if (avatarLocalPath.present) {
      map['avatar_local_path'] = Variable<String>(avatarLocalPath.value);
    }
    if (bannerLocalPath.present) {
      map['banner_local_path'] = Variable<String>(bannerLocalPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoggedAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('screenName: $screenName, ')
          ..write('bio: $bio, ')
          ..write('location: $location, ')
          ..write('link: $link, ')
          ..write('joinTime: $joinTime, ')
          ..write('isVerified: $isVerified, ')
          ..write('isProtected: $isProtected, ')
          ..write('followersCount: $followersCount, ')
          ..write('followingCount: $followingCount, ')
          ..write('statusesCount: $statusesCount, ')
          ..write('mediaCount: $mediaCount, ')
          ..write('favouritesCount: $favouritesCount, ')
          ..write('listedCount: $listedCount, ')
          ..write('latestRawJson: $latestRawJson, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('avatarLocalPath: $avatarLocalPath, ')
          ..write('bannerLocalPath: $bannerLocalPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountProfileHistoryTable extends AccountProfileHistory
    with TableInfo<$AccountProfileHistoryTable, AccountProfileHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountProfileHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES logged_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reverseDiffJsonMeta = const VerificationMeta(
    'reverseDiffJson',
  );
  @override
  late final GeneratedColumn<String> reverseDiffJson = GeneratedColumn<String>(
    'reverse_diff_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    reverseDiffJson,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_profile_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountProfileHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('reverse_diff_json')) {
      context.handle(
        _reverseDiffJsonMeta,
        reverseDiffJson.isAcceptableOrUnknown(
          data['reverse_diff_json']!,
          _reverseDiffJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reverseDiffJsonMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountProfileHistoryEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountProfileHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      reverseDiffJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reverse_diff_json'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $AccountProfileHistoryTable createAlias(String alias) {
    return $AccountProfileHistoryTable(attachedDatabase, alias);
  }
}

class AccountProfileHistoryEntry extends DataClass
    implements Insertable<AccountProfileHistoryEntry> {
  final int id;
  final String ownerId;
  final String reverseDiffJson;
  final DateTime timestamp;
  const AccountProfileHistoryEntry({
    required this.id,
    required this.ownerId,
    required this.reverseDiffJson,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['reverse_diff_json'] = Variable<String>(reverseDiffJson);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AccountProfileHistoryCompanion toCompanion(bool nullToAbsent) {
    return AccountProfileHistoryCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      reverseDiffJson: Value(reverseDiffJson),
      timestamp: Value(timestamp),
    );
  }

  factory AccountProfileHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountProfileHistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      reverseDiffJson: serializer.fromJson<String>(json['reverseDiffJson']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'reverseDiffJson': serializer.toJson<String>(reverseDiffJson),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AccountProfileHistoryEntry copyWith({
    int? id,
    String? ownerId,
    String? reverseDiffJson,
    DateTime? timestamp,
  }) => AccountProfileHistoryEntry(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    reverseDiffJson: reverseDiffJson ?? this.reverseDiffJson,
    timestamp: timestamp ?? this.timestamp,
  );
  AccountProfileHistoryEntry copyWithCompanion(
    AccountProfileHistoryCompanion data,
  ) {
    return AccountProfileHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      reverseDiffJson: data.reverseDiffJson.present
          ? data.reverseDiffJson.value
          : this.reverseDiffJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountProfileHistoryEntry(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('reverseDiffJson: $reverseDiffJson, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ownerId, reverseDiffJson, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountProfileHistoryEntry &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.reverseDiffJson == this.reverseDiffJson &&
          other.timestamp == this.timestamp);
}

class AccountProfileHistoryCompanion
    extends UpdateCompanion<AccountProfileHistoryEntry> {
  final Value<int> id;
  final Value<String> ownerId;
  final Value<String> reverseDiffJson;
  final Value<DateTime> timestamp;
  const AccountProfileHistoryCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.reverseDiffJson = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  AccountProfileHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String ownerId,
    required String reverseDiffJson,
    required DateTime timestamp,
  }) : ownerId = Value(ownerId),
       reverseDiffJson = Value(reverseDiffJson),
       timestamp = Value(timestamp);
  static Insertable<AccountProfileHistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? ownerId,
    Expression<String>? reverseDiffJson,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (reverseDiffJson != null) 'reverse_diff_json': reverseDiffJson,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  AccountProfileHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? ownerId,
    Value<String>? reverseDiffJson,
    Value<DateTime>? timestamp,
  }) {
    return AccountProfileHistoryCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      reverseDiffJson: reverseDiffJson ?? this.reverseDiffJson,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (reverseDiffJson.present) {
      map['reverse_diff_json'] = Variable<String>(reverseDiffJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountProfileHistoryCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('reverseDiffJson: $reverseDiffJson, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $FollowUsersTable extends FollowUsers
    with TableInfo<$FollowUsersTable, FollowUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES logged_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latestRawJsonMeta = const VerificationMeta(
    'latestRawJson',
  );
  @override
  late final GeneratedColumn<String> latestRawJson = GeneratedColumn<String>(
    'latest_raw_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _screenNameMeta = const VerificationMeta(
    'screenName',
  );
  @override
  late final GeneratedColumn<String> screenName = GeneratedColumn<String>(
    'screen_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarLocalPathMeta = const VerificationMeta(
    'avatarLocalPath',
  );
  @override
  late final GeneratedColumn<String> avatarLocalPath = GeneratedColumn<String>(
    'avatar_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFollowerMeta = const VerificationMeta(
    'isFollower',
  );
  @override
  late final GeneratedColumn<bool> isFollower = GeneratedColumn<bool>(
    'is_follower',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_follower" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isFollowingMeta = const VerificationMeta(
    'isFollowing',
  );
  @override
  late final GeneratedColumn<bool> isFollowing = GeneratedColumn<bool>(
    'is_following',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_following" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    userId,
    latestRawJson,
    name,
    screenName,
    avatarUrl,
    bio,
    avatarLocalPath,
    isFollower,
    isFollowing,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follow_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('latest_raw_json')) {
      context.handle(
        _latestRawJsonMeta,
        latestRawJson.isAcceptableOrUnknown(
          data['latest_raw_json']!,
          _latestRawJsonMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('screen_name')) {
      context.handle(
        _screenNameMeta,
        screenName.isAcceptableOrUnknown(data['screen_name']!, _screenNameMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('avatar_local_path')) {
      context.handle(
        _avatarLocalPathMeta,
        avatarLocalPath.isAcceptableOrUnknown(
          data['avatar_local_path']!,
          _avatarLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('is_follower')) {
      context.handle(
        _isFollowerMeta,
        isFollower.isAcceptableOrUnknown(data['is_follower']!, _isFollowerMeta),
      );
    }
    if (data.containsKey('is_following')) {
      context.handle(
        _isFollowingMeta,
        isFollowing.isAcceptableOrUnknown(
          data['is_following']!,
          _isFollowingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, userId};
  @override
  FollowUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowUser(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      latestRawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_raw_json'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      screenName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screen_name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      avatarLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_local_path'],
      ),
      isFollower: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_follower'],
      )!,
      isFollowing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_following'],
      )!,
    );
  }

  @override
  $FollowUsersTable createAlias(String alias) {
    return $FollowUsersTable(attachedDatabase, alias);
  }
}

class FollowUser extends DataClass implements Insertable<FollowUser> {
  final String ownerId;
  final String userId;
  final String? latestRawJson;
  final String? name;
  final String? screenName;
  final String? avatarUrl;
  final String? bio;
  final String? avatarLocalPath;
  final bool isFollower;
  final bool isFollowing;
  const FollowUser({
    required this.ownerId,
    required this.userId,
    this.latestRawJson,
    this.name,
    this.screenName,
    this.avatarUrl,
    this.bio,
    this.avatarLocalPath,
    required this.isFollower,
    required this.isFollowing,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || latestRawJson != null) {
      map['latest_raw_json'] = Variable<String>(latestRawJson);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || screenName != null) {
      map['screen_name'] = Variable<String>(screenName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || avatarLocalPath != null) {
      map['avatar_local_path'] = Variable<String>(avatarLocalPath);
    }
    map['is_follower'] = Variable<bool>(isFollower);
    map['is_following'] = Variable<bool>(isFollowing);
    return map;
  }

  FollowUsersCompanion toCompanion(bool nullToAbsent) {
    return FollowUsersCompanion(
      ownerId: Value(ownerId),
      userId: Value(userId),
      latestRawJson: latestRawJson == null && nullToAbsent
          ? const Value.absent()
          : Value(latestRawJson),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      screenName: screenName == null && nullToAbsent
          ? const Value.absent()
          : Value(screenName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      avatarLocalPath: avatarLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarLocalPath),
      isFollower: Value(isFollower),
      isFollowing: Value(isFollowing),
    );
  }

  factory FollowUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowUser(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      userId: serializer.fromJson<String>(json['userId']),
      latestRawJson: serializer.fromJson<String?>(json['latestRawJson']),
      name: serializer.fromJson<String?>(json['name']),
      screenName: serializer.fromJson<String?>(json['screenName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      bio: serializer.fromJson<String?>(json['bio']),
      avatarLocalPath: serializer.fromJson<String?>(json['avatarLocalPath']),
      isFollower: serializer.fromJson<bool>(json['isFollower']),
      isFollowing: serializer.fromJson<bool>(json['isFollowing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'userId': serializer.toJson<String>(userId),
      'latestRawJson': serializer.toJson<String?>(latestRawJson),
      'name': serializer.toJson<String?>(name),
      'screenName': serializer.toJson<String?>(screenName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'bio': serializer.toJson<String?>(bio),
      'avatarLocalPath': serializer.toJson<String?>(avatarLocalPath),
      'isFollower': serializer.toJson<bool>(isFollower),
      'isFollowing': serializer.toJson<bool>(isFollowing),
    };
  }

  FollowUser copyWith({
    String? ownerId,
    String? userId,
    Value<String?> latestRawJson = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> screenName = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<String?> avatarLocalPath = const Value.absent(),
    bool? isFollower,
    bool? isFollowing,
  }) => FollowUser(
    ownerId: ownerId ?? this.ownerId,
    userId: userId ?? this.userId,
    latestRawJson: latestRawJson.present
        ? latestRawJson.value
        : this.latestRawJson,
    name: name.present ? name.value : this.name,
    screenName: screenName.present ? screenName.value : this.screenName,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    bio: bio.present ? bio.value : this.bio,
    avatarLocalPath: avatarLocalPath.present
        ? avatarLocalPath.value
        : this.avatarLocalPath,
    isFollower: isFollower ?? this.isFollower,
    isFollowing: isFollowing ?? this.isFollowing,
  );
  FollowUser copyWithCompanion(FollowUsersCompanion data) {
    return FollowUser(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      userId: data.userId.present ? data.userId.value : this.userId,
      latestRawJson: data.latestRawJson.present
          ? data.latestRawJson.value
          : this.latestRawJson,
      name: data.name.present ? data.name.value : this.name,
      screenName: data.screenName.present
          ? data.screenName.value
          : this.screenName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      bio: data.bio.present ? data.bio.value : this.bio,
      avatarLocalPath: data.avatarLocalPath.present
          ? data.avatarLocalPath.value
          : this.avatarLocalPath,
      isFollower: data.isFollower.present
          ? data.isFollower.value
          : this.isFollower,
      isFollowing: data.isFollowing.present
          ? data.isFollowing.value
          : this.isFollowing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowUser(')
          ..write('ownerId: $ownerId, ')
          ..write('userId: $userId, ')
          ..write('latestRawJson: $latestRawJson, ')
          ..write('name: $name, ')
          ..write('screenName: $screenName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bio: $bio, ')
          ..write('avatarLocalPath: $avatarLocalPath, ')
          ..write('isFollower: $isFollower, ')
          ..write('isFollowing: $isFollowing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    userId,
    latestRawJson,
    name,
    screenName,
    avatarUrl,
    bio,
    avatarLocalPath,
    isFollower,
    isFollowing,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowUser &&
          other.ownerId == this.ownerId &&
          other.userId == this.userId &&
          other.latestRawJson == this.latestRawJson &&
          other.name == this.name &&
          other.screenName == this.screenName &&
          other.avatarUrl == this.avatarUrl &&
          other.bio == this.bio &&
          other.avatarLocalPath == this.avatarLocalPath &&
          other.isFollower == this.isFollower &&
          other.isFollowing == this.isFollowing);
}

class FollowUsersCompanion extends UpdateCompanion<FollowUser> {
  final Value<String> ownerId;
  final Value<String> userId;
  final Value<String?> latestRawJson;
  final Value<String?> name;
  final Value<String?> screenName;
  final Value<String?> avatarUrl;
  final Value<String?> bio;
  final Value<String?> avatarLocalPath;
  final Value<bool> isFollower;
  final Value<bool> isFollowing;
  final Value<int> rowid;
  const FollowUsersCompanion({
    this.ownerId = const Value.absent(),
    this.userId = const Value.absent(),
    this.latestRawJson = const Value.absent(),
    this.name = const Value.absent(),
    this.screenName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.avatarLocalPath = const Value.absent(),
    this.isFollower = const Value.absent(),
    this.isFollowing = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FollowUsersCompanion.insert({
    required String ownerId,
    required String userId,
    this.latestRawJson = const Value.absent(),
    this.name = const Value.absent(),
    this.screenName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.avatarLocalPath = const Value.absent(),
    this.isFollower = const Value.absent(),
    this.isFollowing = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       userId = Value(userId);
  static Insertable<FollowUser> custom({
    Expression<String>? ownerId,
    Expression<String>? userId,
    Expression<String>? latestRawJson,
    Expression<String>? name,
    Expression<String>? screenName,
    Expression<String>? avatarUrl,
    Expression<String>? bio,
    Expression<String>? avatarLocalPath,
    Expression<bool>? isFollower,
    Expression<bool>? isFollowing,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (userId != null) 'user_id': userId,
      if (latestRawJson != null) 'latest_raw_json': latestRawJson,
      if (name != null) 'name': name,
      if (screenName != null) 'screen_name': screenName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      if (avatarLocalPath != null) 'avatar_local_path': avatarLocalPath,
      if (isFollower != null) 'is_follower': isFollower,
      if (isFollowing != null) 'is_following': isFollowing,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FollowUsersCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? userId,
    Value<String?>? latestRawJson,
    Value<String?>? name,
    Value<String?>? screenName,
    Value<String?>? avatarUrl,
    Value<String?>? bio,
    Value<String?>? avatarLocalPath,
    Value<bool>? isFollower,
    Value<bool>? isFollowing,
    Value<int>? rowid,
  }) {
    return FollowUsersCompanion(
      ownerId: ownerId ?? this.ownerId,
      userId: userId ?? this.userId,
      latestRawJson: latestRawJson ?? this.latestRawJson,
      name: name ?? this.name,
      screenName: screenName ?? this.screenName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      isFollower: isFollower ?? this.isFollower,
      isFollowing: isFollowing ?? this.isFollowing,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (latestRawJson.present) {
      map['latest_raw_json'] = Variable<String>(latestRawJson.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (screenName.present) {
      map['screen_name'] = Variable<String>(screenName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (avatarLocalPath.present) {
      map['avatar_local_path'] = Variable<String>(avatarLocalPath.value);
    }
    if (isFollower.present) {
      map['is_follower'] = Variable<bool>(isFollower.value);
    }
    if (isFollowing.present) {
      map['is_following'] = Variable<bool>(isFollowing.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowUsersCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('userId: $userId, ')
          ..write('latestRawJson: $latestRawJson, ')
          ..write('name: $name, ')
          ..write('screenName: $screenName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bio: $bio, ')
          ..write('avatarLocalPath: $avatarLocalPath, ')
          ..write('isFollower: $isFollower, ')
          ..write('isFollowing: $isFollowing, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FollowUsersHistoryTable extends FollowUsersHistory
    with TableInfo<$FollowUsersHistoryTable, FollowUserHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowUsersHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reverseDiffJsonMeta = const VerificationMeta(
    'reverseDiffJson',
  );
  @override
  late final GeneratedColumn<String> reverseDiffJson = GeneratedColumn<String>(
    'reverse_diff_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    userId,
    reverseDiffJson,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follow_users_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowUserHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('reverse_diff_json')) {
      context.handle(
        _reverseDiffJsonMeta,
        reverseDiffJson.isAcceptableOrUnknown(
          data['reverse_diff_json']!,
          _reverseDiffJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reverseDiffJsonMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FollowUserHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowUserHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      reverseDiffJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reverse_diff_json'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $FollowUsersHistoryTable createAlias(String alias) {
    return $FollowUsersHistoryTable(attachedDatabase, alias);
  }
}

class FollowUserHistoryEntry extends DataClass
    implements Insertable<FollowUserHistoryEntry> {
  final int id;
  final String ownerId;
  final String userId;
  final String reverseDiffJson;
  final DateTime timestamp;
  const FollowUserHistoryEntry({
    required this.id,
    required this.ownerId,
    required this.userId,
    required this.reverseDiffJson,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['user_id'] = Variable<String>(userId);
    map['reverse_diff_json'] = Variable<String>(reverseDiffJson);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  FollowUsersHistoryCompanion toCompanion(bool nullToAbsent) {
    return FollowUsersHistoryCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      userId: Value(userId),
      reverseDiffJson: Value(reverseDiffJson),
      timestamp: Value(timestamp),
    );
  }

  factory FollowUserHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowUserHistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      userId: serializer.fromJson<String>(json['userId']),
      reverseDiffJson: serializer.fromJson<String>(json['reverseDiffJson']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'userId': serializer.toJson<String>(userId),
      'reverseDiffJson': serializer.toJson<String>(reverseDiffJson),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  FollowUserHistoryEntry copyWith({
    int? id,
    String? ownerId,
    String? userId,
    String? reverseDiffJson,
    DateTime? timestamp,
  }) => FollowUserHistoryEntry(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    userId: userId ?? this.userId,
    reverseDiffJson: reverseDiffJson ?? this.reverseDiffJson,
    timestamp: timestamp ?? this.timestamp,
  );
  FollowUserHistoryEntry copyWithCompanion(FollowUsersHistoryCompanion data) {
    return FollowUserHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      userId: data.userId.present ? data.userId.value : this.userId,
      reverseDiffJson: data.reverseDiffJson.present
          ? data.reverseDiffJson.value
          : this.reverseDiffJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowUserHistoryEntry(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('userId: $userId, ')
          ..write('reverseDiffJson: $reverseDiffJson, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ownerId, userId, reverseDiffJson, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowUserHistoryEntry &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.userId == this.userId &&
          other.reverseDiffJson == this.reverseDiffJson &&
          other.timestamp == this.timestamp);
}

class FollowUsersHistoryCompanion
    extends UpdateCompanion<FollowUserHistoryEntry> {
  final Value<int> id;
  final Value<String> ownerId;
  final Value<String> userId;
  final Value<String> reverseDiffJson;
  final Value<DateTime> timestamp;
  const FollowUsersHistoryCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.userId = const Value.absent(),
    this.reverseDiffJson = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  FollowUsersHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String ownerId,
    required String userId,
    required String reverseDiffJson,
    required DateTime timestamp,
  }) : ownerId = Value(ownerId),
       userId = Value(userId),
       reverseDiffJson = Value(reverseDiffJson),
       timestamp = Value(timestamp);
  static Insertable<FollowUserHistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? ownerId,
    Expression<String>? userId,
    Expression<String>? reverseDiffJson,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (userId != null) 'user_id': userId,
      if (reverseDiffJson != null) 'reverse_diff_json': reverseDiffJson,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  FollowUsersHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? ownerId,
    Value<String>? userId,
    Value<String>? reverseDiffJson,
    Value<DateTime>? timestamp,
  }) {
    return FollowUsersHistoryCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      userId: userId ?? this.userId,
      reverseDiffJson: reverseDiffJson ?? this.reverseDiffJson,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (reverseDiffJson.present) {
      map['reverse_diff_json'] = Variable<String>(reverseDiffJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowUsersHistoryCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('userId: $userId, ')
          ..write('reverseDiffJson: $reverseDiffJson, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $ChangeReportsTable extends ChangeReports
    with TableInfo<$ChangeReportsTable, ChangeReportEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChangeReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES logged_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeTypeMeta = const VerificationMeta(
    'changeType',
  );
  @override
  late final GeneratedColumn<String> changeType = GeneratedColumn<String>(
    'change_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userSnapshotJsonMeta = const VerificationMeta(
    'userSnapshotJson',
  );
  @override
  late final GeneratedColumn<String> userSnapshotJson = GeneratedColumn<String>(
    'user_snapshot_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    userId,
    changeType,
    timestamp,
    userSnapshotJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeReportEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('change_type')) {
      context.handle(
        _changeTypeMeta,
        changeType.isAcceptableOrUnknown(data['change_type']!, _changeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_changeTypeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('user_snapshot_json')) {
      context.handle(
        _userSnapshotJsonMeta,
        userSnapshotJson.isAcceptableOrUnknown(
          data['user_snapshot_json']!,
          _userSnapshotJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChangeReportEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeReportEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      changeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      userSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_snapshot_json'],
      ),
    );
  }

  @override
  $ChangeReportsTable createAlias(String alias) {
    return $ChangeReportsTable(attachedDatabase, alias);
  }
}

class ChangeReportEntry extends DataClass
    implements Insertable<ChangeReportEntry> {
  final int id;
  final String ownerId;
  final String userId;
  final String changeType;
  final DateTime timestamp;
  final String? userSnapshotJson;
  const ChangeReportEntry({
    required this.id,
    required this.ownerId,
    required this.userId,
    required this.changeType,
    required this.timestamp,
    this.userSnapshotJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['user_id'] = Variable<String>(userId);
    map['change_type'] = Variable<String>(changeType);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || userSnapshotJson != null) {
      map['user_snapshot_json'] = Variable<String>(userSnapshotJson);
    }
    return map;
  }

  ChangeReportsCompanion toCompanion(bool nullToAbsent) {
    return ChangeReportsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      userId: Value(userId),
      changeType: Value(changeType),
      timestamp: Value(timestamp),
      userSnapshotJson: userSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(userSnapshotJson),
    );
  }

  factory ChangeReportEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeReportEntry(
      id: serializer.fromJson<int>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      userId: serializer.fromJson<String>(json['userId']),
      changeType: serializer.fromJson<String>(json['changeType']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      userSnapshotJson: serializer.fromJson<String?>(json['userSnapshotJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'userId': serializer.toJson<String>(userId),
      'changeType': serializer.toJson<String>(changeType),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'userSnapshotJson': serializer.toJson<String?>(userSnapshotJson),
    };
  }

  ChangeReportEntry copyWith({
    int? id,
    String? ownerId,
    String? userId,
    String? changeType,
    DateTime? timestamp,
    Value<String?> userSnapshotJson = const Value.absent(),
  }) => ChangeReportEntry(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    userId: userId ?? this.userId,
    changeType: changeType ?? this.changeType,
    timestamp: timestamp ?? this.timestamp,
    userSnapshotJson: userSnapshotJson.present
        ? userSnapshotJson.value
        : this.userSnapshotJson,
  );
  ChangeReportEntry copyWithCompanion(ChangeReportsCompanion data) {
    return ChangeReportEntry(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      userId: data.userId.present ? data.userId.value : this.userId,
      changeType: data.changeType.present
          ? data.changeType.value
          : this.changeType,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      userSnapshotJson: data.userSnapshotJson.present
          ? data.userSnapshotJson.value
          : this.userSnapshotJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeReportEntry(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('userId: $userId, ')
          ..write('changeType: $changeType, ')
          ..write('timestamp: $timestamp, ')
          ..write('userSnapshotJson: $userSnapshotJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ownerId, userId, changeType, timestamp, userSnapshotJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeReportEntry &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.userId == this.userId &&
          other.changeType == this.changeType &&
          other.timestamp == this.timestamp &&
          other.userSnapshotJson == this.userSnapshotJson);
}

class ChangeReportsCompanion extends UpdateCompanion<ChangeReportEntry> {
  final Value<int> id;
  final Value<String> ownerId;
  final Value<String> userId;
  final Value<String> changeType;
  final Value<DateTime> timestamp;
  final Value<String?> userSnapshotJson;
  const ChangeReportsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.userId = const Value.absent(),
    this.changeType = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.userSnapshotJson = const Value.absent(),
  });
  ChangeReportsCompanion.insert({
    this.id = const Value.absent(),
    required String ownerId,
    required String userId,
    required String changeType,
    required DateTime timestamp,
    this.userSnapshotJson = const Value.absent(),
  }) : ownerId = Value(ownerId),
       userId = Value(userId),
       changeType = Value(changeType),
       timestamp = Value(timestamp);
  static Insertable<ChangeReportEntry> custom({
    Expression<int>? id,
    Expression<String>? ownerId,
    Expression<String>? userId,
    Expression<String>? changeType,
    Expression<DateTime>? timestamp,
    Expression<String>? userSnapshotJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (userId != null) 'user_id': userId,
      if (changeType != null) 'change_type': changeType,
      if (timestamp != null) 'timestamp': timestamp,
      if (userSnapshotJson != null) 'user_snapshot_json': userSnapshotJson,
    });
  }

  ChangeReportsCompanion copyWith({
    Value<int>? id,
    Value<String>? ownerId,
    Value<String>? userId,
    Value<String>? changeType,
    Value<DateTime>? timestamp,
    Value<String?>? userSnapshotJson,
  }) {
    return ChangeReportsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      userId: userId ?? this.userId,
      changeType: changeType ?? this.changeType,
      timestamp: timestamp ?? this.timestamp,
      userSnapshotJson: userSnapshotJson ?? this.userSnapshotJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (changeType.present) {
      map['change_type'] = Variable<String>(changeType.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (userSnapshotJson.present) {
      map['user_snapshot_json'] = Variable<String>(userSnapshotJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeReportsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('userId: $userId, ')
          ..write('changeType: $changeType, ')
          ..write('timestamp: $timestamp, ')
          ..write('userSnapshotJson: $userSnapshotJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LoggedAccountsTable loggedAccounts = $LoggedAccountsTable(this);
  late final $AccountProfileHistoryTable accountProfileHistory =
      $AccountProfileHistoryTable(this);
  late final $FollowUsersTable followUsers = $FollowUsersTable(this);
  late final $FollowUsersHistoryTable followUsersHistory =
      $FollowUsersHistoryTable(this);
  late final $ChangeReportsTable changeReports = $ChangeReportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    loggedAccounts,
    accountProfileHistory,
    followUsers,
    followUsersHistory,
    changeReports,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'logged_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('account_profile_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'logged_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('follow_users', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'logged_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('change_reports', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LoggedAccountsTableCreateCompanionBuilder =
    LoggedAccountsCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> screenName,
      Value<String?> bio,
      Value<String?> location,
      Value<String?> link,
      Value<String?> joinTime,
      Value<bool?> isVerified,
      Value<bool?> isProtected,
      Value<int> followersCount,
      Value<int> followingCount,
      Value<int> statusesCount,
      Value<int> mediaCount,
      Value<int> favouritesCount,
      Value<int> listedCount,
      Value<String?> latestRawJson,
      Value<String?> avatarUrl,
      Value<String?> bannerUrl,
      Value<String?> avatarLocalPath,
      Value<String?> bannerLocalPath,
      Value<int> rowid,
    });
typedef $$LoggedAccountsTableUpdateCompanionBuilder =
    LoggedAccountsCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> screenName,
      Value<String?> bio,
      Value<String?> location,
      Value<String?> link,
      Value<String?> joinTime,
      Value<bool?> isVerified,
      Value<bool?> isProtected,
      Value<int> followersCount,
      Value<int> followingCount,
      Value<int> statusesCount,
      Value<int> mediaCount,
      Value<int> favouritesCount,
      Value<int> listedCount,
      Value<String?> latestRawJson,
      Value<String?> avatarUrl,
      Value<String?> bannerUrl,
      Value<String?> avatarLocalPath,
      Value<String?> bannerLocalPath,
      Value<int> rowid,
    });

final class $$LoggedAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $LoggedAccountsTable, LoggedAccount> {
  $$LoggedAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $AccountProfileHistoryTable,
    List<AccountProfileHistoryEntry>
  >
  _accountProfileHistoryRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accountProfileHistory,
        aliasName: $_aliasNameGenerator(
          db.loggedAccounts.id,
          db.accountProfileHistory.ownerId,
        ),
      );

  $$AccountProfileHistoryTableProcessedTableManager
  get accountProfileHistoryRefs {
    final manager = $$AccountProfileHistoryTableTableManager(
      $_db,
      $_db.accountProfileHistory,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountProfileHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FollowUsersTable, List<FollowUser>>
  _followUsersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.followUsers,
    aliasName: $_aliasNameGenerator(
      db.loggedAccounts.id,
      db.followUsers.ownerId,
    ),
  );

  $$FollowUsersTableProcessedTableManager get followUsersRefs {
    final manager = $$FollowUsersTableTableManager(
      $_db,
      $_db.followUsers,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_followUsersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChangeReportsTable, List<ChangeReportEntry>>
  _changeReportsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.changeReports,
    aliasName: $_aliasNameGenerator(
      db.loggedAccounts.id,
      db.changeReports.ownerId,
    ),
  );

  $$ChangeReportsTableProcessedTableManager get changeReportsRefs {
    final manager = $$ChangeReportsTableTableManager(
      $_db,
      $_db.changeReports,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_changeReportsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LoggedAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $LoggedAccountsTable> {
  $$LoggedAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joinTime => $composableBuilder(
    column: $table.joinTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get followersCount => $composableBuilder(
    column: $table.followersCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get followingCount => $composableBuilder(
    column: $table.followingCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusesCount => $composableBuilder(
    column: $table.statusesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get favouritesCount => $composableBuilder(
    column: $table.favouritesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listedCount => $composableBuilder(
    column: $table.listedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestRawJson => $composableBuilder(
    column: $table.latestRawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerUrl => $composableBuilder(
    column: $table.bannerUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarLocalPath => $composableBuilder(
    column: $table.avatarLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerLocalPath => $composableBuilder(
    column: $table.bannerLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountProfileHistoryRefs(
    Expression<bool> Function($$AccountProfileHistoryTableFilterComposer f) f,
  ) {
    final $$AccountProfileHistoryTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountProfileHistory,
          getReferencedColumn: (t) => t.ownerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountProfileHistoryTableFilterComposer(
                $db: $db,
                $table: $db.accountProfileHistory,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> followUsersRefs(
    Expression<bool> Function($$FollowUsersTableFilterComposer f) f,
  ) {
    final $$FollowUsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.followUsers,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FollowUsersTableFilterComposer(
            $db: $db,
            $table: $db.followUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> changeReportsRefs(
    Expression<bool> Function($$ChangeReportsTableFilterComposer f) f,
  ) {
    final $$ChangeReportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.changeReports,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChangeReportsTableFilterComposer(
            $db: $db,
            $table: $db.changeReports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoggedAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoggedAccountsTable> {
  $$LoggedAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joinTime => $composableBuilder(
    column: $table.joinTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get followersCount => $composableBuilder(
    column: $table.followersCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get followingCount => $composableBuilder(
    column: $table.followingCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusesCount => $composableBuilder(
    column: $table.statusesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get favouritesCount => $composableBuilder(
    column: $table.favouritesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listedCount => $composableBuilder(
    column: $table.listedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestRawJson => $composableBuilder(
    column: $table.latestRawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerUrl => $composableBuilder(
    column: $table.bannerUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarLocalPath => $composableBuilder(
    column: $table.avatarLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerLocalPath => $composableBuilder(
    column: $table.bannerLocalPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoggedAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoggedAccountsTable> {
  $$LoggedAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get joinTime =>
      $composableBuilder(column: $table.joinTime, builder: (column) => column);

  GeneratedColumn<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => column,
  );

  GeneratedColumn<int> get followersCount => $composableBuilder(
    column: $table.followersCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get followingCount => $composableBuilder(
    column: $table.followingCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statusesCount => $composableBuilder(
    column: $table.statusesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaCount => $composableBuilder(
    column: $table.mediaCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get favouritesCount => $composableBuilder(
    column: $table.favouritesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get listedCount => $composableBuilder(
    column: $table.listedCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latestRawJson => $composableBuilder(
    column: $table.latestRawJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get bannerUrl =>
      $composableBuilder(column: $table.bannerUrl, builder: (column) => column);

  GeneratedColumn<String> get avatarLocalPath => $composableBuilder(
    column: $table.avatarLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bannerLocalPath => $composableBuilder(
    column: $table.bannerLocalPath,
    builder: (column) => column,
  );

  Expression<T> accountProfileHistoryRefs<T extends Object>(
    Expression<T> Function($$AccountProfileHistoryTableAnnotationComposer a) f,
  ) {
    final $$AccountProfileHistoryTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accountProfileHistory,
          getReferencedColumn: (t) => t.ownerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccountProfileHistoryTableAnnotationComposer(
                $db: $db,
                $table: $db.accountProfileHistory,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> followUsersRefs<T extends Object>(
    Expression<T> Function($$FollowUsersTableAnnotationComposer a) f,
  ) {
    final $$FollowUsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.followUsers,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FollowUsersTableAnnotationComposer(
            $db: $db,
            $table: $db.followUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> changeReportsRefs<T extends Object>(
    Expression<T> Function($$ChangeReportsTableAnnotationComposer a) f,
  ) {
    final $$ChangeReportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.changeReports,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChangeReportsTableAnnotationComposer(
            $db: $db,
            $table: $db.changeReports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoggedAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoggedAccountsTable,
          LoggedAccount,
          $$LoggedAccountsTableFilterComposer,
          $$LoggedAccountsTableOrderingComposer,
          $$LoggedAccountsTableAnnotationComposer,
          $$LoggedAccountsTableCreateCompanionBuilder,
          $$LoggedAccountsTableUpdateCompanionBuilder,
          (LoggedAccount, $$LoggedAccountsTableReferences),
          LoggedAccount,
          PrefetchHooks Function({
            bool accountProfileHistoryRefs,
            bool followUsersRefs,
            bool changeReportsRefs,
          })
        > {
  $$LoggedAccountsTableTableManager(
    _$AppDatabase db,
    $LoggedAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoggedAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoggedAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoggedAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> screenName = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> link = const Value.absent(),
                Value<String?> joinTime = const Value.absent(),
                Value<bool?> isVerified = const Value.absent(),
                Value<bool?> isProtected = const Value.absent(),
                Value<int> followersCount = const Value.absent(),
                Value<int> followingCount = const Value.absent(),
                Value<int> statusesCount = const Value.absent(),
                Value<int> mediaCount = const Value.absent(),
                Value<int> favouritesCount = const Value.absent(),
                Value<int> listedCount = const Value.absent(),
                Value<String?> latestRawJson = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bannerUrl = const Value.absent(),
                Value<String?> avatarLocalPath = const Value.absent(),
                Value<String?> bannerLocalPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoggedAccountsCompanion(
                id: id,
                name: name,
                screenName: screenName,
                bio: bio,
                location: location,
                link: link,
                joinTime: joinTime,
                isVerified: isVerified,
                isProtected: isProtected,
                followersCount: followersCount,
                followingCount: followingCount,
                statusesCount: statusesCount,
                mediaCount: mediaCount,
                favouritesCount: favouritesCount,
                listedCount: listedCount,
                latestRawJson: latestRawJson,
                avatarUrl: avatarUrl,
                bannerUrl: bannerUrl,
                avatarLocalPath: avatarLocalPath,
                bannerLocalPath: bannerLocalPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> screenName = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> link = const Value.absent(),
                Value<String?> joinTime = const Value.absent(),
                Value<bool?> isVerified = const Value.absent(),
                Value<bool?> isProtected = const Value.absent(),
                Value<int> followersCount = const Value.absent(),
                Value<int> followingCount = const Value.absent(),
                Value<int> statusesCount = const Value.absent(),
                Value<int> mediaCount = const Value.absent(),
                Value<int> favouritesCount = const Value.absent(),
                Value<int> listedCount = const Value.absent(),
                Value<String?> latestRawJson = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bannerUrl = const Value.absent(),
                Value<String?> avatarLocalPath = const Value.absent(),
                Value<String?> bannerLocalPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoggedAccountsCompanion.insert(
                id: id,
                name: name,
                screenName: screenName,
                bio: bio,
                location: location,
                link: link,
                joinTime: joinTime,
                isVerified: isVerified,
                isProtected: isProtected,
                followersCount: followersCount,
                followingCount: followingCount,
                statusesCount: statusesCount,
                mediaCount: mediaCount,
                favouritesCount: favouritesCount,
                listedCount: listedCount,
                latestRawJson: latestRawJson,
                avatarUrl: avatarUrl,
                bannerUrl: bannerUrl,
                avatarLocalPath: avatarLocalPath,
                bannerLocalPath: bannerLocalPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LoggedAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountProfileHistoryRefs = false,
                followUsersRefs = false,
                changeReportsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (accountProfileHistoryRefs) db.accountProfileHistory,
                    if (followUsersRefs) db.followUsers,
                    if (changeReportsRefs) db.changeReports,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountProfileHistoryRefs)
                        await $_getPrefetchedData<
                          LoggedAccount,
                          $LoggedAccountsTable,
                          AccountProfileHistoryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LoggedAccountsTableReferences
                              ._accountProfileHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LoggedAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).accountProfileHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (followUsersRefs)
                        await $_getPrefetchedData<
                          LoggedAccount,
                          $LoggedAccountsTable,
                          FollowUser
                        >(
                          currentTable: table,
                          referencedTable: $$LoggedAccountsTableReferences
                              ._followUsersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LoggedAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).followUsersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (changeReportsRefs)
                        await $_getPrefetchedData<
                          LoggedAccount,
                          $LoggedAccountsTable,
                          ChangeReportEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LoggedAccountsTableReferences
                              ._changeReportsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LoggedAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).changeReportsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ownerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LoggedAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoggedAccountsTable,
      LoggedAccount,
      $$LoggedAccountsTableFilterComposer,
      $$LoggedAccountsTableOrderingComposer,
      $$LoggedAccountsTableAnnotationComposer,
      $$LoggedAccountsTableCreateCompanionBuilder,
      $$LoggedAccountsTableUpdateCompanionBuilder,
      (LoggedAccount, $$LoggedAccountsTableReferences),
      LoggedAccount,
      PrefetchHooks Function({
        bool accountProfileHistoryRefs,
        bool followUsersRefs,
        bool changeReportsRefs,
      })
    >;
typedef $$AccountProfileHistoryTableCreateCompanionBuilder =
    AccountProfileHistoryCompanion Function({
      Value<int> id,
      required String ownerId,
      required String reverseDiffJson,
      required DateTime timestamp,
    });
typedef $$AccountProfileHistoryTableUpdateCompanionBuilder =
    AccountProfileHistoryCompanion Function({
      Value<int> id,
      Value<String> ownerId,
      Value<String> reverseDiffJson,
      Value<DateTime> timestamp,
    });

final class $$AccountProfileHistoryTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AccountProfileHistoryTable,
          AccountProfileHistoryEntry
        > {
  $$AccountProfileHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LoggedAccountsTable _ownerIdTable(_$AppDatabase db) =>
      db.loggedAccounts.createAlias(
        $_aliasNameGenerator(
          db.accountProfileHistory.ownerId,
          db.loggedAccounts.id,
        ),
      );

  $$LoggedAccountsTableProcessedTableManager get ownerId {
    final $_column = $_itemColumn<String>('owner_id')!;

    final manager = $$LoggedAccountsTableTableManager(
      $_db,
      $_db.loggedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AccountProfileHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $AccountProfileHistoryTable> {
  $$AccountProfileHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reverseDiffJson => $composableBuilder(
    column: $table.reverseDiffJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$LoggedAccountsTableFilterComposer get ownerId {
    final $$LoggedAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableFilterComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountProfileHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountProfileHistoryTable> {
  $$AccountProfileHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reverseDiffJson => $composableBuilder(
    column: $table.reverseDiffJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$LoggedAccountsTableOrderingComposer get ownerId {
    final $$LoggedAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountProfileHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountProfileHistoryTable> {
  $$AccountProfileHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reverseDiffJson => $composableBuilder(
    column: $table.reverseDiffJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$LoggedAccountsTableAnnotationComposer get ownerId {
    final $$LoggedAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountProfileHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountProfileHistoryTable,
          AccountProfileHistoryEntry,
          $$AccountProfileHistoryTableFilterComposer,
          $$AccountProfileHistoryTableOrderingComposer,
          $$AccountProfileHistoryTableAnnotationComposer,
          $$AccountProfileHistoryTableCreateCompanionBuilder,
          $$AccountProfileHistoryTableUpdateCompanionBuilder,
          (AccountProfileHistoryEntry, $$AccountProfileHistoryTableReferences),
          AccountProfileHistoryEntry,
          PrefetchHooks Function({bool ownerId})
        > {
  $$AccountProfileHistoryTableTableManager(
    _$AppDatabase db,
    $AccountProfileHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountProfileHistoryTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AccountProfileHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AccountProfileHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> reverseDiffJson = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => AccountProfileHistoryCompanion(
                id: id,
                ownerId: ownerId,
                reverseDiffJson: reverseDiffJson,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ownerId,
                required String reverseDiffJson,
                required DateTime timestamp,
              }) => AccountProfileHistoryCompanion.insert(
                id: id,
                ownerId: ownerId,
                reverseDiffJson: reverseDiffJson,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountProfileHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ownerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ownerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ownerId,
                                referencedTable:
                                    $$AccountProfileHistoryTableReferences
                                        ._ownerIdTable(db),
                                referencedColumn:
                                    $$AccountProfileHistoryTableReferences
                                        ._ownerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AccountProfileHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountProfileHistoryTable,
      AccountProfileHistoryEntry,
      $$AccountProfileHistoryTableFilterComposer,
      $$AccountProfileHistoryTableOrderingComposer,
      $$AccountProfileHistoryTableAnnotationComposer,
      $$AccountProfileHistoryTableCreateCompanionBuilder,
      $$AccountProfileHistoryTableUpdateCompanionBuilder,
      (AccountProfileHistoryEntry, $$AccountProfileHistoryTableReferences),
      AccountProfileHistoryEntry,
      PrefetchHooks Function({bool ownerId})
    >;
typedef $$FollowUsersTableCreateCompanionBuilder =
    FollowUsersCompanion Function({
      required String ownerId,
      required String userId,
      Value<String?> latestRawJson,
      Value<String?> name,
      Value<String?> screenName,
      Value<String?> avatarUrl,
      Value<String?> bio,
      Value<String?> avatarLocalPath,
      Value<bool> isFollower,
      Value<bool> isFollowing,
      Value<int> rowid,
    });
typedef $$FollowUsersTableUpdateCompanionBuilder =
    FollowUsersCompanion Function({
      Value<String> ownerId,
      Value<String> userId,
      Value<String?> latestRawJson,
      Value<String?> name,
      Value<String?> screenName,
      Value<String?> avatarUrl,
      Value<String?> bio,
      Value<String?> avatarLocalPath,
      Value<bool> isFollower,
      Value<bool> isFollowing,
      Value<int> rowid,
    });

final class $$FollowUsersTableReferences
    extends BaseReferences<_$AppDatabase, $FollowUsersTable, FollowUser> {
  $$FollowUsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LoggedAccountsTable _ownerIdTable(_$AppDatabase db) =>
      db.loggedAccounts.createAlias(
        $_aliasNameGenerator(db.followUsers.ownerId, db.loggedAccounts.id),
      );

  $$LoggedAccountsTableProcessedTableManager get ownerId {
    final $_column = $_itemColumn<String>('owner_id')!;

    final manager = $$LoggedAccountsTableTableManager(
      $_db,
      $_db.loggedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FollowUsersTableFilterComposer
    extends Composer<_$AppDatabase, $FollowUsersTable> {
  $$FollowUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestRawJson => $composableBuilder(
    column: $table.latestRawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarLocalPath => $composableBuilder(
    column: $table.avatarLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFollower => $composableBuilder(
    column: $table.isFollower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFollowing => $composableBuilder(
    column: $table.isFollowing,
    builder: (column) => ColumnFilters(column),
  );

  $$LoggedAccountsTableFilterComposer get ownerId {
    final $$LoggedAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableFilterComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FollowUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowUsersTable> {
  $$FollowUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestRawJson => $composableBuilder(
    column: $table.latestRawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarLocalPath => $composableBuilder(
    column: $table.avatarLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFollower => $composableBuilder(
    column: $table.isFollower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFollowing => $composableBuilder(
    column: $table.isFollowing,
    builder: (column) => ColumnOrderings(column),
  );

  $$LoggedAccountsTableOrderingComposer get ownerId {
    final $$LoggedAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FollowUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowUsersTable> {
  $$FollowUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get latestRawJson => $composableBuilder(
    column: $table.latestRawJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get screenName => $composableBuilder(
    column: $table.screenName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get avatarLocalPath => $composableBuilder(
    column: $table.avatarLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFollower => $composableBuilder(
    column: $table.isFollower,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFollowing => $composableBuilder(
    column: $table.isFollowing,
    builder: (column) => column,
  );

  $$LoggedAccountsTableAnnotationComposer get ownerId {
    final $$LoggedAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FollowUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowUsersTable,
          FollowUser,
          $$FollowUsersTableFilterComposer,
          $$FollowUsersTableOrderingComposer,
          $$FollowUsersTableAnnotationComposer,
          $$FollowUsersTableCreateCompanionBuilder,
          $$FollowUsersTableUpdateCompanionBuilder,
          (FollowUser, $$FollowUsersTableReferences),
          FollowUser,
          PrefetchHooks Function({bool ownerId})
        > {
  $$FollowUsersTableTableManager(_$AppDatabase db, $FollowUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> latestRawJson = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> screenName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> avatarLocalPath = const Value.absent(),
                Value<bool> isFollower = const Value.absent(),
                Value<bool> isFollowing = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowUsersCompanion(
                ownerId: ownerId,
                userId: userId,
                latestRawJson: latestRawJson,
                name: name,
                screenName: screenName,
                avatarUrl: avatarUrl,
                bio: bio,
                avatarLocalPath: avatarLocalPath,
                isFollower: isFollower,
                isFollowing: isFollowing,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String userId,
                Value<String?> latestRawJson = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> screenName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> avatarLocalPath = const Value.absent(),
                Value<bool> isFollower = const Value.absent(),
                Value<bool> isFollowing = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowUsersCompanion.insert(
                ownerId: ownerId,
                userId: userId,
                latestRawJson: latestRawJson,
                name: name,
                screenName: screenName,
                avatarUrl: avatarUrl,
                bio: bio,
                avatarLocalPath: avatarLocalPath,
                isFollower: isFollower,
                isFollowing: isFollowing,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FollowUsersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ownerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ownerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ownerId,
                                referencedTable: $$FollowUsersTableReferences
                                    ._ownerIdTable(db),
                                referencedColumn: $$FollowUsersTableReferences
                                    ._ownerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FollowUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowUsersTable,
      FollowUser,
      $$FollowUsersTableFilterComposer,
      $$FollowUsersTableOrderingComposer,
      $$FollowUsersTableAnnotationComposer,
      $$FollowUsersTableCreateCompanionBuilder,
      $$FollowUsersTableUpdateCompanionBuilder,
      (FollowUser, $$FollowUsersTableReferences),
      FollowUser,
      PrefetchHooks Function({bool ownerId})
    >;
typedef $$FollowUsersHistoryTableCreateCompanionBuilder =
    FollowUsersHistoryCompanion Function({
      Value<int> id,
      required String ownerId,
      required String userId,
      required String reverseDiffJson,
      required DateTime timestamp,
    });
typedef $$FollowUsersHistoryTableUpdateCompanionBuilder =
    FollowUsersHistoryCompanion Function({
      Value<int> id,
      Value<String> ownerId,
      Value<String> userId,
      Value<String> reverseDiffJson,
      Value<DateTime> timestamp,
    });

class $$FollowUsersHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $FollowUsersHistoryTable> {
  $$FollowUsersHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reverseDiffJson => $composableBuilder(
    column: $table.reverseDiffJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowUsersHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowUsersHistoryTable> {
  $$FollowUsersHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reverseDiffJson => $composableBuilder(
    column: $table.reverseDiffJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowUsersHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowUsersHistoryTable> {
  $$FollowUsersHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get reverseDiffJson => $composableBuilder(
    column: $table.reverseDiffJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$FollowUsersHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowUsersHistoryTable,
          FollowUserHistoryEntry,
          $$FollowUsersHistoryTableFilterComposer,
          $$FollowUsersHistoryTableOrderingComposer,
          $$FollowUsersHistoryTableAnnotationComposer,
          $$FollowUsersHistoryTableCreateCompanionBuilder,
          $$FollowUsersHistoryTableUpdateCompanionBuilder,
          (
            FollowUserHistoryEntry,
            BaseReferences<
              _$AppDatabase,
              $FollowUsersHistoryTable,
              FollowUserHistoryEntry
            >,
          ),
          FollowUserHistoryEntry,
          PrefetchHooks Function()
        > {
  $$FollowUsersHistoryTableTableManager(
    _$AppDatabase db,
    $FollowUsersHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowUsersHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowUsersHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowUsersHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> reverseDiffJson = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => FollowUsersHistoryCompanion(
                id: id,
                ownerId: ownerId,
                userId: userId,
                reverseDiffJson: reverseDiffJson,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ownerId,
                required String userId,
                required String reverseDiffJson,
                required DateTime timestamp,
              }) => FollowUsersHistoryCompanion.insert(
                id: id,
                ownerId: ownerId,
                userId: userId,
                reverseDiffJson: reverseDiffJson,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowUsersHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowUsersHistoryTable,
      FollowUserHistoryEntry,
      $$FollowUsersHistoryTableFilterComposer,
      $$FollowUsersHistoryTableOrderingComposer,
      $$FollowUsersHistoryTableAnnotationComposer,
      $$FollowUsersHistoryTableCreateCompanionBuilder,
      $$FollowUsersHistoryTableUpdateCompanionBuilder,
      (
        FollowUserHistoryEntry,
        BaseReferences<
          _$AppDatabase,
          $FollowUsersHistoryTable,
          FollowUserHistoryEntry
        >,
      ),
      FollowUserHistoryEntry,
      PrefetchHooks Function()
    >;
typedef $$ChangeReportsTableCreateCompanionBuilder =
    ChangeReportsCompanion Function({
      Value<int> id,
      required String ownerId,
      required String userId,
      required String changeType,
      required DateTime timestamp,
      Value<String?> userSnapshotJson,
    });
typedef $$ChangeReportsTableUpdateCompanionBuilder =
    ChangeReportsCompanion Function({
      Value<int> id,
      Value<String> ownerId,
      Value<String> userId,
      Value<String> changeType,
      Value<DateTime> timestamp,
      Value<String?> userSnapshotJson,
    });

final class $$ChangeReportsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChangeReportsTable, ChangeReportEntry> {
  $$ChangeReportsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LoggedAccountsTable _ownerIdTable(_$AppDatabase db) =>
      db.loggedAccounts.createAlias(
        $_aliasNameGenerator(db.changeReports.ownerId, db.loggedAccounts.id),
      );

  $$LoggedAccountsTableProcessedTableManager get ownerId {
    final $_column = $_itemColumn<String>('owner_id')!;

    final manager = $$LoggedAccountsTableTableManager(
      $_db,
      $_db.loggedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChangeReportsTableFilterComposer
    extends Composer<_$AppDatabase, $ChangeReportsTable> {
  $$ChangeReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userSnapshotJson => $composableBuilder(
    column: $table.userSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  $$LoggedAccountsTableFilterComposer get ownerId {
    final $$LoggedAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableFilterComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChangeReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChangeReportsTable> {
  $$ChangeReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userSnapshotJson => $composableBuilder(
    column: $table.userSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$LoggedAccountsTableOrderingComposer get ownerId {
    final $$LoggedAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChangeReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChangeReportsTable> {
  $$ChangeReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get userSnapshotJson => $composableBuilder(
    column: $table.userSnapshotJson,
    builder: (column) => column,
  );

  $$LoggedAccountsTableAnnotationComposer get ownerId {
    final $$LoggedAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.loggedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.loggedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChangeReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChangeReportsTable,
          ChangeReportEntry,
          $$ChangeReportsTableFilterComposer,
          $$ChangeReportsTableOrderingComposer,
          $$ChangeReportsTableAnnotationComposer,
          $$ChangeReportsTableCreateCompanionBuilder,
          $$ChangeReportsTableUpdateCompanionBuilder,
          (ChangeReportEntry, $$ChangeReportsTableReferences),
          ChangeReportEntry,
          PrefetchHooks Function({bool ownerId})
        > {
  $$ChangeReportsTableTableManager(_$AppDatabase db, $ChangeReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChangeReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChangeReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChangeReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> changeType = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> userSnapshotJson = const Value.absent(),
              }) => ChangeReportsCompanion(
                id: id,
                ownerId: ownerId,
                userId: userId,
                changeType: changeType,
                timestamp: timestamp,
                userSnapshotJson: userSnapshotJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ownerId,
                required String userId,
                required String changeType,
                required DateTime timestamp,
                Value<String?> userSnapshotJson = const Value.absent(),
              }) => ChangeReportsCompanion.insert(
                id: id,
                ownerId: ownerId,
                userId: userId,
                changeType: changeType,
                timestamp: timestamp,
                userSnapshotJson: userSnapshotJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChangeReportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ownerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ownerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ownerId,
                                referencedTable: $$ChangeReportsTableReferences
                                    ._ownerIdTable(db),
                                referencedColumn: $$ChangeReportsTableReferences
                                    ._ownerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChangeReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChangeReportsTable,
      ChangeReportEntry,
      $$ChangeReportsTableFilterComposer,
      $$ChangeReportsTableOrderingComposer,
      $$ChangeReportsTableAnnotationComposer,
      $$ChangeReportsTableCreateCompanionBuilder,
      $$ChangeReportsTableUpdateCompanionBuilder,
      (ChangeReportEntry, $$ChangeReportsTableReferences),
      ChangeReportEntry,
      PrefetchHooks Function({bool ownerId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LoggedAccountsTableTableManager get loggedAccounts =>
      $$LoggedAccountsTableTableManager(_db, _db.loggedAccounts);
  $$AccountProfileHistoryTableTableManager get accountProfileHistory =>
      $$AccountProfileHistoryTableTableManager(_db, _db.accountProfileHistory);
  $$FollowUsersTableTableManager get followUsers =>
      $$FollowUsersTableTableManager(_db, _db.followUsers);
  $$FollowUsersHistoryTableTableManager get followUsersHistory =>
      $$FollowUsersHistoryTableTableManager(_db, _db.followUsersHistory);
  $$ChangeReportsTableTableManager get changeReports =>
      $$ChangeReportsTableTableManager(_db, _db.changeReports);
}
