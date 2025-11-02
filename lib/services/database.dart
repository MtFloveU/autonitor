// --- 1. 导入必要的库 ---
import 'dart:io'; // 用于文件系统操作
import 'package:drift/drift.dart'; // Drift 核心
import 'package:drift/native.dart'; // Drift 的 SQLite (native) 引擎
import 'package:path_provider/path_provider.dart'; // 查找文件路径
import 'package:path/path.dart' as p; // 拼接文件路径

// --- 2. 告诉 Drift 这个文件需要一个“伙伴”文件 ---
part 'database.g.dart'; // 这个文件还不存在，代码生成器会自动创建它

// --- 3. 定义你的表 ---

// 表 1: LoggedAccounts (你的 "LoggedAccounts")
// 存储你已登录账号的个人资料
@DataClassName('LoggedAccount') // 定义生成的数据类名称
class LoggedAccounts extends Table {
  // Twitter User ID (rest_id), 我们用它作为主键
  TextColumn get id => text()();

  // 你在图中提到的 "UI 显示值"
  TextColumn get name => text().nullable()();
  TextColumn get screenName => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get link => text().nullable()();
  TextColumn get joinTime => text().nullable()();
  BoolColumn get isVerified => boolean().nullable().withDefault(const Constant(false))();
  BoolColumn get isProtected => boolean().nullable().withDefault(const Constant(false))();

  // 统计数值
  IntColumn get followersCount => integer().withDefault(const Constant(0))();
  IntColumn get followingCount => integer().withDefault(const Constant(0))();
  IntColumn get statusesCount => integer().withDefault(const Constant(0))();
  IntColumn get mediaCount => integer().withDefault(const Constant(0))();
  IntColumn get favouritesCount => integer().withDefault(const Constant(0))();
  IntColumn get listedCount => integer().withDefault(const Constant(0))();

  // 存储最新的 GraphQL JSON
  TextColumn get latestRawJson => text().named('latest_raw_json').nullable()();

  // 图片存储路径
  TextColumn get avatarUrl => text().nullable()(); // 原始网络 URL
  TextColumn get bannerUrl => text().nullable()(); // 原始网络 URL
  TextColumn get avatarLocalPath =>
      text().named('avatar_local_path').nullable()();
  TextColumn get bannerLocalPath =>
      text().named('banner_local_path').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 表 2: AccountProfileHistory (你的 JSON DIFF 表)
// 存储 LoggedAccounts 的历史版本（反向差异）
@DataClassName('AccountProfileHistoryEntry')
class AccountProfileHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 历史归属于哪个账号
  TextColumn get ownerId => text()
      .named('owner_id')
      .references(LoggedAccounts, #id, onDelete: KeyAction.cascade)();

  // 存储“反向差异”补丁
  TextColumn get reverseDiffJson => text().named('reverse_diff_json')();

  DateTimeColumn get timestamp => dateTime()();
}

// 表 3: FollowUsers (你的 "FollowUsers")
// 存储每个已登录账号的“网络池”（关注者+正在关注）
@DataClassName('FollowUser')
class FollowUsers extends Table {
  // 归属于哪个已登录账号
  TextColumn get ownerId => text()
      .named('owner_id')
      .references(LoggedAccounts, #id, onDelete: KeyAction.cascade)();

  // 列表中的用户 ID
  TextColumn get userId => text().named('user_id')();

  // 存储 API 1.1 的最新 JSON
  TextColumn get latestRawJson => text().named('latest_raw_json').nullable()();

  // "UI 显示值"，用于快速加载列表
  TextColumn get name => text().nullable()();
  TextColumn get screenName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()(); // API 1.1 提供的头像 URL
  TextColumn get bio => text().nullable()(); // (API 1.1 里的 description)

  // 图片存储路径
  TextColumn get avatarLocalPath =>
      text().named('avatar_local_path').nullable()();

  // 关键状态字段，用于计算差异
  BoolColumn get isFollower => boolean().withDefault(const Constant(false))();
  BoolColumn get isFollowing => boolean().withDefault(const Constant(false))();

  // 复合主键：(ownerId, userId) 共同保证唯一性
  @override
  Set<Column> get primaryKey => {ownerId, userId};
}

// 表 4: FollowUsersHistory (你的 JSON DIFF 表)
// 存储 FollowUsers 的历史版本（反向差异）
@DataClassName('FollowUserHistoryEntry')
class FollowUsersHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 历史归属于哪个账号的哪个用户
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get userId => text().named('user_id')();

  // 存储“反向差异”补丁
  TextColumn get reverseDiffJson => text().named('reverse_diff_json')();

  DateTimeColumn get timestamp => dateTime()();

  // 外键，指向 FollowUsers 表
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY(owner_id, user_id) REFERENCES follow_users(owner_id, user_id) ON DELETE CASCADE',
  ];
}

// 表 5: ChangeReport (你的 "Change Report")
// 存储已计算出的“关系变更索引”
@DataClassName('ChangeReportEntry')
class ChangeReports extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 报告归属于哪个账号
  TextColumn get ownerId => text()
      .named('owner_id')
      .references(LoggedAccounts, #id, onDelete: KeyAction.cascade)();

  // 发生变更的用户 ID
  TextColumn get userId => text().named('user_id')();

  // 变更类型 (即你的列表名)
  // e.g., "normal_unfollowed", "mutual_unfollowed", "new_follower", etc. [cite: 529-539]
  TextColumn get changeType => text().named('change_type')();

  DateTimeColumn get timestamp => dateTime()();
  TextColumn get userSnapshotJson =>
      text().named('user_snapshot_json').nullable()();
}

// --- 4. 定义数据库主类 ---
@DriftDatabase(
  tables: [
    LoggedAccounts,
    AccountProfileHistory,
    FollowUsers,
    FollowUsersHistory,
    ChangeReports,
  ],
)
@DriftDatabase(
  tables: [
    LoggedAccounts,
    AccountProfileHistory,
    FollowUsers,
    FollowUsersHistory,
    ChangeReports,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- 新增数据库操作方法 ---

  /// 查询指定 ownerId 的所有网络关系
  Future<List<FollowUser>> getNetworkRelationships(String ownerId) async {
    return (select(
      followUsers,
    )..where((tbl) => tbl.ownerId.equals(ownerId))).get();
    // select(followUsers) 开始一个查询，目标是 followUsers 表
    // ..where(...) 添加一个条件：只选择 ownerId 匹配的行
    // .get() 执行查询并返回 List<FollowUser> (FollowUser 是 Drift 自动生成的数据类)
  }

  /// 批量更新或插入网络关系 (Upsert)
  Future<void> batchUpsertNetworkRelationships(
    List<FollowUsersCompanion> companions,
  ) async {
    await batch((batch) {
      // batch.insertAll 方法用于批量插入
      // mode: InsertMode.replace 表示如果主键 (ownerId, userId) 已存在，则替换旧行
      batch.insertAll(followUsers, companions, mode: InsertMode.replace);
    });
  }

  /// 批量删除指定 ownerId 下的特定 userIds 的网络关系
  Future<void> deleteNetworkRelationships(
    String ownerId,
    List<String> userIdsToRemove,
  ) async {
    // delete 方法用于删除操作
    // ..where(...) 指定条件：ownerId 匹配 并且 userId 在 userIdsToRemove 列表中
    await (delete(followUsers)..where(
          (tbl) =>
              tbl.ownerId.equals(ownerId) & tbl.userId.isIn(userIdsToRemove),
        ))
        .go();
    // .go() 执行删除操作
  }

  /// 批量插入关注用户历史记录
  Future<void> batchInsertFollowUsersHistory(
    List<FollowUsersHistoryCompanion> historyCompanions,
  ) async {
    await batch((batch) {
      // 历史记录通常只插入，不替换
      batch.insertAll(followUsersHistory, historyCompanions);
    });
  }

  /// 替换指定 ownerId 的所有变更报告
  Future<void> replaceChangeReport(
    String ownerId,
    List<ChangeReportsCompanion> reportCompanions,
  ) async {
    // 使用事务确保原子性：要么都成功，要么都失败
    await transaction(() async {
      // 1. 删除该 ownerId 的所有旧报告
      await (delete(
        changeReports,
      )..where((tbl) => tbl.ownerId.equals(ownerId))).go();

      // 2. 批量插入新的报告
      await batch((batch) {
        batch.insertAll(changeReports, reportCompanions);
      });
    });
  }

  // --- 新增结束 ---
} // <-- AppDatabase 类的结束括号

// ... (_openConnection 函数保持不变)

// --- 5. 定义数据库连接 ---
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'autonitor_data.db')); //
    return NativeDatabase(file);
  });
}
