import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

//数据库表定义
@DataClassName('LoggedAccount')
class LoggedAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get screenName => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get link => text().nullable()();
  TextColumn get joinTime => text().nullable()();
  BoolColumn get isVerified =>
      boolean().nullable().withDefault(const Constant(false))();
  BoolColumn get isProtected =>
      boolean().nullable().withDefault(const Constant(false))();
  IntColumn get followersCount => integer().withDefault(const Constant(0))();
  IntColumn get followingCount => integer().withDefault(const Constant(0))();
  IntColumn get statusesCount => integer().withDefault(const Constant(0))();
  IntColumn get mediaCount => integer().withDefault(const Constant(0))();
  IntColumn get favouritesCount => integer().withDefault(const Constant(0))();
  IntColumn get listedCount => integer().withDefault(const Constant(0))();
  TextColumn get latestRawJson => text().named('latest_raw_json').nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bannerUrl => text().nullable()();
  TextColumn get avatarLocalPath =>
      text().named('avatar_local_path').nullable()();
  TextColumn get bannerLocalPath =>
      text().named('banner_local_path').nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccountProfileHistoryEntry')
class AccountProfileHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerId => text()
      .named('owner_id')
      .references(LoggedAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get reverseDiffJson => text().named('reverse_diff_json')();
  DateTimeColumn get timestamp => dateTime()();
}

@DataClassName('FollowUser')
class FollowUsers extends Table {
  TextColumn get ownerId => text()
      .named('owner_id')
      .references(LoggedAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().named('user_id')();
  TextColumn get latestRawJson => text().named('latest_raw_json').nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get screenName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bannerUrl => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get avatarLocalPath =>
      text().named('avatar_local_path').nullable()();
  TextColumn get bannerLocalPath =>
      text().named('banner_local_path').nullable()();
  BoolColumn get isFollower => boolean().withDefault(const Constant(false))();
  BoolColumn get isFollowing => boolean().withDefault(const Constant(false))();

  // Sort columns (Added in v2)
  IntColumn get followerSort => integer().nullable()();
  IntColumn get followingSort => integer().nullable()();

  @override
  Set<Column> get primaryKey => {ownerId, userId};
}

@DataClassName('FollowUserHistoryEntry')
class FollowUsersHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get reverseDiffJson => text().named('reverse_diff_json')();
  DateTimeColumn get timestamp => dateTime()();
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY(owner_id, user_id) REFERENCES follow_users(owner_id, user_id) ON DELETE CASCADE',
  ];
}

@DataClassName('ChangeReportEntry')
class ChangeReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ownerId => text()
      .named('owner_id')
      .references(LoggedAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().named('user_id')();
  TextColumn get changeType => text().named('change_type')();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get userSnapshotJson =>
      text().named('user_snapshot_json').nullable()();
}

@DataClassName('MediaHistoryEntry')
class MediaHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mediaType => text().named('media_type')();
  TextColumn get localFilePath => text().named('local_file_path')();
  TextColumn get remoteUrl => text().named('remote_url')();
  BoolColumn get isHighQuality =>
      boolean().named('is_high_quality').withDefault(const Constant(false))();
}

@DataClassName('SyncLogsEntry')
class SyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get runId => text().named('run_id')();
  DateTimeColumn get timestamp => dateTime().named('timestamp')();
  IntColumn get status => integer().named('status')();
  TextColumn get ownerId =>
      text().named('owner_id').withDefault(const Constant(''))();
}

@DriftDatabase(
  tables: [
    LoggedAccounts,
    AccountProfileHistory,
    FollowUsers,
    FollowUsersHistory,
    ChangeReports,
    MediaHistory,
    SyncLogs,
  ],
)
// 主class
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  // 数据库迁移
  @override
  // [Upgraded] Upgrade to version 3 to include indices
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(followUsers, followUsers.followerSort);
        await m.addColumn(followUsers, followUsers.followingSort);
      }
      if (from < 3) {
        // [Performance Fix] Create indices for sorting columns
        // This makes ORDER BY + LIMIT/OFFSET extremely fast
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_follower_sort ON follow_users (owner_id, is_follower, follower_sort)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_following_sort ON follow_users (owner_id, is_following, following_sort)',
        );
      }
    },
  );
  // 快捷方法
  Future<List<FollowUser>> getNetworkRelationships(String ownerId) async {
    return (select(
      followUsers,
    )..where((tbl) => tbl.ownerId.equals(ownerId))).get();
  }

  Future<void> batchUpsertNetworkRelationships(
    List<FollowUsersCompanion> companions,
  ) async {
    await batch((batch) {
      batch.insertAll(followUsers, companions, mode: InsertMode.replace);
    });
  }

  Future<void> deleteNetworkRelationships(
    String ownerId,
    List<String> userIdsToRemove,
  ) async {
    await (delete(followUsers)..where(
          (tbl) =>
              tbl.ownerId.equals(ownerId) & tbl.userId.isIn(userIdsToRemove),
        ))
        .go();
  }

  Future<void> batchInsertFollowUsersHistory(
    List<FollowUsersHistoryCompanion> historyCompanions,
  ) async {
    await batch((batch) {
      batch.insertAll(followUsersHistory, historyCompanions);
    });
  }

  Future<void> replaceChangeReport(
    String ownerId,
    List<ChangeReportsCompanion> reportCompanions,
  ) async {
    await transaction(() async {
      await (delete(
        changeReports,
      )..where((tbl) => tbl.ownerId.equals(ownerId))).go();

      await batch((batch) {
        batch.insertAll(changeReports, reportCompanions);
      });
    });
  }

  Future<int> insertMediaHistory(MediaHistoryCompanion companion) {
    return into(mediaHistory).insert(companion);
  }

  Future<void> updateFollowUserLocalPath({
    required String ownerId,
    required String userId,
    String? avatarPath,
    String? bannerPath,
  }) {
    final companion = FollowUsersCompanion(
      avatarLocalPath: avatarPath == null
          ? const Value.absent()
          : Value(avatarPath),
      bannerLocalPath: bannerPath == null
          ? const Value.absent()
          : Value(bannerPath),
      bannerUrl: const Value.absent(),
    );

    return (update(followUsers)..where(
          (tbl) => tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId),
        ))
        .write(companion);
  }

  Future<void> updateLoggedAccountLocalPath({
    required String accountId,
    String? avatarPath,
    String? bannerPath,
  }) {
    final companion = LoggedAccountsCompanion(
      avatarLocalPath: avatarPath == null
          ? const Value.absent()
          : Value(avatarPath),
      bannerLocalPath: bannerPath == null
          ? const Value.absent()
          : Value(bannerPath),
    );

    return (update(
      loggedAccounts,
    )..where((tbl) => tbl.id.equals(accountId))).write(companion);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    await Directory(dbFolder.path).create(recursive: true);
    final file = File(p.join(dbFolder.path, 'autonitor_data.db'));
    return NativeDatabase(file);
  });
}
