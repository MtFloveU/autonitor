import 'dart:convert';
import 'package:autonitor/main.dart'; // (这个可能不再需要，但留着无妨)
import 'package:autonitor/models/app_settings.dart';
import 'package:autonitor/models/history_snapshot.dart';
import 'package:autonitor/repositories/analysis_report_repository.dart';
import 'package:autonitor/services/database.dart';
import 'package:autonitor/utils/diff_utils.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// (Provider 定义不变)
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HistoryRepository(db);
});

/// (Repository 类定义不变)
class HistoryRepository {
  final AppDatabase _db; // <-- 这个字段现在会被使用了
  HistoryRepository(this._db);

  // (常量定义不变)
  static const Set<String> _textKeys = {
    "name",
    "screen_name",
    "description",
    "url",
    "location",
  };
  static const Set<String> _imageKeys = {"avatar_url", "banner_url"};
  static final Set<String> _relevantKeys = _textKeys.union(_imageKeys);

  /// 4. 这是 Provider 将调用的公共方法
  Future<List<HistorySnapshot>> getFilteredHistory(
    String ownerId,
    String userId,
    AppSettings settings,
  ) async {
    // 1. 获取最新数据 (我们的起点)
    final currentUser =
        await (_db.select(_db.followUsers)..where(
              (tbl) => tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId),
            ))
            .getSingleOrNull();

    if (currentUser == null || currentUser.latestRawJson == null) {
      return []; // 没有当前数据，无法重建
    }

    // 2. 获取所有历史补丁 (从新到旧)
    final historyEntries =
        await (_db.select(_db.followUsersHistory)
              ..where(
                (tbl) =>
                    tbl.ownerId.equals(ownerId) & tbl.userId.equals(userId),
              )
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.timestamp,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();

    // --- 新增：获取所有相关的媒体历史记录（按时间倒序） ---
    final mediaHistory =
        await (_db.select(_db.mediaHistory)..orderBy([
              (tbl) =>
                  OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
            ]))
            .get();
    // --- 新增结束 ---

    // 5. 将 *纯数据*（可发送）传递给 compute 块
    return await compute(_reconstructAndFilterHistory, {
      'settings': settings,
      'userId': userId,
      'latestRawJson': currentUser.latestRawJson!, // 传入 String
      'historyEntries': historyEntries, // 传入 List<FollowUserHistoryEntry>
      'mediaHistory': mediaHistory, // <-- NEW: 传入媒体历史记录
    });
  }
}

// --- 辅助函数：标准化 URL（移除质量后缀） ---
String _normalizeUrl(String url) {
  const String suffixRegex = r'_(normal|bigger|400x400)';
  // 移除后缀，用于比较
  return url.replaceFirst(RegExp(suffixRegex), '');
}

// --- 辅助函数：在隔离中查找匹配的本地路径 ---
String? _findLocalPath(
  List<MediaHistoryEntry> history,
  String mediaType,
  String? remoteUrl,
  DateTime snapshotTimestamp,
) {
  if (remoteUrl == null || remoteUrl.isEmpty) return null;

  final normalizedTargetUrl = _normalizeUrl(remoteUrl);

  // 1. 过滤：匹配类型和标准化后的 URL
  final filtered = history.where((e) {
    final isTypeMatch = e.mediaType == mediaType;
    if (!isTypeMatch) return false;

    final normalizedRemoteUrl = _normalizeUrl(e.remoteUrl);
    return normalizedRemoteUrl == normalizedTargetUrl;
  }).toList();

  if (filtered.isEmpty) return null;

  // 2. 查找：找到时间戳 <= 快照时间戳的最新记录
  // 由于 history 已经是按时间倒序排列的，我们找到的第一个符合条件的即为最佳匹配。
  MediaHistoryEntry? bestMatch;
  bestMatch = filtered.isNotEmpty ? filtered.first : null;

  return bestMatch?.localFilePath;
}

/// 6. 这是在独立 Isolate 中运行的重建和过滤函数
Future<List<HistorySnapshot>> _reconstructAndFilterHistory(
  Map<String, dynamic> context,
) async {
  // --- 核心修改：从 context 中解包纯数据 ---
  final AppSettings settings = context['settings'];
  final String userId = context['userId'];
  final String latestRawJson = context['latestRawJson'];
  final List<FollowUserHistoryEntry> historyEntries = context['historyEntries'];
  final List<MediaHistoryEntry> mediaHistory =
      context['mediaHistory']; // <-- NEW
  // --- 修改结束 ---

  // (从 HistoryRepository 访问常量)
  final Set<String> textKeys = HistoryRepository._textKeys;
  final Set<String> relevantKeys = HistoryRepository._relevantKeys;

  final List<HistorySnapshot> filteredSnapshots = [];
  Map<String, dynamic> currentJsonMap;
  try {
    currentJsonMap = jsonDecode(latestRawJson);
  } catch (e) {
    return []; // JSON 损坏，无法继续
  }

  // (所有剩余的循环、过滤、重建逻辑... 均保持不变)
  for (final entry in historyEntries) {
    final Map<String, dynamic> patchMap;
    try {
      patchMap = jsonDecode(entry.reverseDiffJson) as Map<String, dynamic>;
    } catch (e) {
      // 补丁损坏，跳过
      continue;
    }

    // 1. 检查相关性（在应用补丁前检查，因为 patchMap 包含了差异信息）
    final patchKeys = patchMap.keys.toSet();
    final bool hasRelevantChange = patchKeys.any(
      (k) => relevantKeys.contains(k),
    );

    // 2. 应用反向补丁：将 currentJsonMap 从新版本 'A' 变为旧版本 'B'
    final Map<String, dynamic>? oldVersionMap = applyReversePatch(
      currentJsonMap,
      entry.reverseDiffJson,
    );

    if (oldVersionMap == null) {
      // 补丁应用失败，无法继续回滚
      break;
    }
    currentJsonMap = oldVersionMap; // 更新 currentJsonMap 为旧版本 'B'

    if (!hasRelevantChange) {
      // 如果补丁不包含相关更改，则跳过保存快照，但回滚已经完成
      continue;
    }

    // 3. 检查图像过滤（使用旧版本 'B' 的信息来判断是否保存这个快照）
    final bool hasTextChange = patchKeys.any((k) => textKeys.contains(k));
    final bool onlyImageChange = !hasTextChange;

    if (onlyImageChange) {
      final bool hadAvatarChange = patchKeys.contains("avatar_url");
      final bool hadBannerChange = patchKeys.contains("banner_url");

      if (hadAvatarChange && !settings.saveAvatarHistory) {
        continue;
      }
      if (hadBannerChange && !settings.saveBannerHistory) {
        continue;
      }
    }

    // --- 新增：查找本地媒体路径 ---
    final snapshotAvatarUrl = currentJsonMap['avatar_url'] as String?;
    final snapshotBannerUrl = currentJsonMap['banner_url'] as String?;
    final snapshotTimestamp = entry.timestamp;

    final avatarPath = _findLocalPath(
      mediaHistory,
      'avatar',
      snapshotAvatarUrl,
      snapshotTimestamp,
    );
    final bannerPath = _findLocalPath(
      mediaHistory,
      'banner',
      snapshotBannerUrl,
      snapshotTimestamp,
    );
    // --- 新增结束 ---

    // 4. 将 'B' 版本（即应用补丁后的状态）作为快照保存
    if (avatarPath != null && avatarPath.isNotEmpty) {
      currentJsonMap['avatar_local_path'] = avatarPath;
    }

    if (bannerPath != null && bannerPath.isNotEmpty) {
      currentJsonMap['banner_local_path'] = bannerPath;
    }

    final params = ParseParams(
      userId: userId,
      jsonString: jsonEncode(currentJsonMap),
      dbAvatarLocalPath: avatarPath,
      dbBannerLocalPath: bannerPath,
    );

    final reconstructedUser = parseFollowUserToTwitterUser(params);

    filteredSnapshots.add(
      HistorySnapshot(
        entry: entry,
        user: reconstructedUser,
        fullJson: jsonEncode(currentJsonMap),
      ),
    );
  }

  return filteredSnapshots;
}
