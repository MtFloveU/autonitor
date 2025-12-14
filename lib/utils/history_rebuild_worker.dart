import 'dart:async';
import 'dart:isolate';
import 'dart:convert';

/// 一个纯净的 Worker，不依赖任何 Flutter 插件或数据库类
class HistoryRebuildWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  final Map<int, Completer<dynamic>> _completers = {};
  int _nextId = 0;
  bool _initializing = false;

  HistoryRebuildWorker();

  Future<void> initIfNeeded() async {
    if (_sendPort != null && _receivePort != null) return;

    _sendPort = null;
    _receivePort?.close();
    _receivePort = null;
    _isolate = null;

    if (_initializing) {
      while (_sendPort == null) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      return;
    }

    _initializing = true;

    try {
      _receivePort = ReceivePort();
      final completer = Completer<void>();

      _receivePort!.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          if (!completer.isCompleted) {
            completer.complete();
          }
        } else {
          _handleMessageFromWorker(message);
        }
      });

      _isolate = await Isolate.spawn<SendPort>(
        _historyIsolateEntry,
        _receivePort!.sendPort,
      );

      await completer.future;
    } finally {
      _initializing = false;
    }
  }

  Future<dynamic> run(Map<String, dynamic> payload) async {
    await initIfNeeded();
    final id = _nextId++;
    final completer = Completer<dynamic>();
    _completers[id] = completer;
    _sendPort!.send([id, payload]);
    return completer.future;
  }

  void _handleMessageFromWorker(dynamic message) {
    if (message is List && message.length == 2) {
      final id = message[0] as int;
      final payload = message[1];
      final completer = _completers.remove(id);
      completer?.complete(payload);
    }
  }

  void dispose() {
    for (final completer in _completers.values) {
      completer.completeError(Exception("Worker disposed"));
    }
    _completers.clear();
    _cleanup();
  }

  void _cleanup() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _receivePort?.close();
    _receivePort = null;
  }
}

// --- Isolate Entry ---
void _historyIsolateEntry(SendPort replyToMain) {
  final workerReceive = ReceivePort();
  replyToMain.send(workerReceive.sendPort);

  workerReceive.listen((message) async {
    if (message is List && message.length == 2) {
      final int id = message[0] as int;
      final Map<String, dynamic> payload = message[1] as Map<String, dynamic>;

      try {
        final result = _processHistory(payload);
        replyToMain.send([id, result]);
      } catch (_) {
        replyToMain.send([
          id,
          {'total': 0, 'items': []},
        ]);
      }
    }
  });
}

// --- 过滤配置 ---
const Set<String> _textKeys = {
  "name",
  "screen_name",
  "bio",
  "location",
  "link",
  "url",
};
final Set<String> _relevantKeys = _textKeys.union({"avatar_url", "banner_url"});

// --- 核心逻辑 ---
Map<String, dynamic> _processHistory(Map<String, dynamic> context) {
  final String userId = context['userId'];
  final String latestRawJson = context['latestRawJson'];
  final List<dynamic> historyEntries = context['historyEntries'];
  final List<dynamic> mediaHistory = context['mediaHistory'];
  final int page = context['page'] as int? ?? 1;
  final int pageSize = context['pageSize'] as int? ?? 20;

  if (historyEntries.isEmpty) {
    return {'total': 0, 'items': []};
  }

  // 1. [第一步] 重建完整的时间线快照 (Timeline Reconstruction)
  // 我们先生成所有的状态点，暂不考虑过滤，确立完整的时间轴
  // Snapshots: [Current, T-1, T-2, ..., Genesis]
  List<_SnapshotNode> timeline = [];

  Map<String, dynamic> stateCursor;
  try {
    stateCursor = jsonDecode(latestRawJson);
  } catch (_) {
    return {'total': 0, 'items': []};
  }

  // 当前最新状态不放入历史列表，但它是去重的基准
  // timeline.add(...) // 不添加 Current

  for (int i = 0; i < historyEntries.length; i++) {
    final entryMap = historyEntries[i] as Map<String, dynamic>;
    final reverseDiffJson = entryMap['reverseDiffJson'] as String;

    Map<String, dynamic> patchToPrev;
    try {
      patchToPrev = jsonDecode(reverseDiffJson) as Map<String, dynamic>;
    } catch (_) {
      patchToPrev = {};
    }

    // 回滚到上一刻状态
    final statePrev =
        _applyReversePatchInline(stateCursor, patchToPrev) ?? stateCursor;

    // 记录这个快照
    timeline.add(
      _SnapshotNode(
        entryId: entryMap['id'] as int,
        timestampMs: entryMap['timestampMs'] as int,
        data: statePrev,
      ),
    );

    // 迭代
    stateCursor = statePrev;
  }

  // 2. [第二步] 基于内容的去重 (Content-based Deduplication)
  // 我们只保留那些与"上一个保留节点"在 _relevantKeys 上有差异的节点。
  // 对于历史列表，"上一个保留节点"初始就是 Current State (也就是 latestRawJson)

  Map<String, dynamic> lastKeptData = jsonDecode(latestRawJson);
  List<_SnapshotNode> validSnapshots = [];

  for (final node in timeline) {
    if (_hasRelevantDiff(lastKeptData, node.data)) {
      validSnapshots.add(node);
      lastKeptData = node.data; // 更新基准
    }
    // 如果没有差异 (例如只变了 followers)，则丢弃该节点，基准保持不变
    // 这样如果 Genesis 和 Current 一模一样，Genesis 也会被丢弃，完美修复了你的 Bug。
  }

  // 3. [第三步] 计算 Diff 并生成结果
  // 对于保留下来的节点 S_i，它的 Diff 应该是 S_{i+1} (更旧的有效节点) -> S_i

  List<Map<String, dynamic>> results = [];

  for (int i = 0; i < validSnapshots.length; i++) {
    final currentParams = validSnapshots[i];
    final Map<String, dynamic> currentData = currentParams.data;

    Map<String, dynamic> diffMap = {};

    // 寻找更旧的有效节点来计算 Diff
    if (i + 1 < validSnapshots.length) {
      final olderData = validSnapshots[i + 1].data;
      diffMap = _computeForwardDiff(olderData, currentData);
    } else {
      // 这是一个 Genesis 节点 (最旧的有效节点)
      diffMap = _computeForwardDiff({}, currentData);
    }

    // 注入媒体路径 & 构造 User Map (保持原有逻辑)
    final snapshotTimestamp = DateTime.fromMillisecondsSinceEpoch(
      currentParams.timestampMs,
    );
    final currentAvatarUrl = currentData['avatar_url'] as String?;
    final currentBannerUrl = currentData['banner_url'] as String?;

    final avatarPath = _findLocalPath(
      mediaHistory,
      'avatar',
      currentAvatarUrl,
      snapshotTimestamp,
    );
    final bannerPath = _findLocalPath(
      mediaHistory,
      'banner',
      currentBannerUrl,
      snapshotTimestamp,
    );

    if (avatarPath != null) currentData['avatar_local_path'] = avatarPath;
    if (bannerPath != null) currentData['banner_local_path'] = bannerPath;

    final userMap = _constructUserMap(
      userId: userId,
      dbScreenName: currentData['screen_name'],
      dbName: currentData['name'],
      dbAvatarUrl: currentData['avatar_url'],
      dbAvatarLocalPath: avatarPath,
      dbBannerLocalPath: bannerPath,
      dbBio: currentData['bio'],
      jsonMap: currentData,
    );

    results.add({
      'entryId': currentParams.entryId,
      'fullJson': jsonEncode(currentData),
      'userMap': userMap,
      'diffJson': jsonEncode(diffMap),
    });
  }

  // 4. [第四步] 内存分页
  final int totalCount = results.length;
  final int startIndex = (page - 1) * pageSize;

  List<Map<String, dynamic>> pagedItems = [];
  if (startIndex < totalCount) {
    int endIndex = startIndex + pageSize;
    if (endIndex > totalCount) endIndex = totalCount;
    pagedItems = results.sublist(startIndex, endIndex);
  }

  return {'total': totalCount, 'items': pagedItems};
}

// --- 内部类 ---
class _SnapshotNode {
  final int entryId;
  final int timestampMs;
  final Map<String, dynamic> data;
  _SnapshotNode({
    required this.entryId,
    required this.timestampMs,
    required this.data,
  });
}

// --- 辅助函数 ---

// [新增] 检查两个 Map 在 relevantKeys 上是否有差异
bool _hasRelevantDiff(Map<String, dynamic> a, Map<String, dynamic> b) {
  for (final key in _relevantKeys) {
    final valA = a[key];
    final valB = b[key];
    if ((valA == null || valA == "") && (valB == null || valB == "")) continue;
    if (valA != valB) return true;
  }
  return false;
}

Map<String, dynamic> _computeForwardDiff(
  Map<String, dynamic> oldMap,
  Map<String, dynamic> newMap,
) {
  final diff = <String, dynamic>{};
  for (final key in _relevantKeys) {
    final oldVal = oldMap[key];
    final newVal = newMap[key];
    if ((oldVal == null || oldVal == "") && (newVal == null || newVal == "")) {
      continue;
    }
    if (oldVal != newVal) {
      diff[key] = {'old': oldVal, 'new': newVal};
    }
  }
  return diff;
}

Map<String, dynamic> _constructUserMap({
  required String userId,
  String? dbScreenName,
  String? dbName,
  String? dbAvatarUrl,
  String? dbAvatarLocalPath,
  String? dbBannerLocalPath,
  String? dbBio,
  required Map<String, dynamic> jsonMap,
}) {
  final merged = Map<String, dynamic>.from(jsonMap);
  merged['rest_id'] ??= userId;
  merged['screen_name'] ??= dbScreenName;
  merged['name'] ??= dbName;
  merged['avatar_url'] ??= dbAvatarUrl;
  merged['bio'] ??= dbBio;
  if (dbAvatarLocalPath != null) {
    merged['avatar_local_path'] = dbAvatarLocalPath;
  }
  if (dbBannerLocalPath != null) {
    merged['banner_local_path'] = dbBannerLocalPath;
  }
  return merged;
}

String? _findLocalPath(
  List<dynamic> history,
  String mediaType,
  String? remoteUrl,
  DateTime snapshotTimestamp,
) {
  if (remoteUrl == null || remoteUrl.isEmpty) return null;
  final normalizedTargetUrl = _normalizeUrl(remoteUrl);
  final filtered = history.where((e) {
    final m = e as Map<String, dynamic>;
    if (m['mediaType'] != mediaType) return false;
    final normalizedRemoteUrl = _normalizeUrl(m['remoteUrl']);
    return normalizedRemoteUrl == normalizedTargetUrl;
  }).toList();
  if (filtered.isEmpty) return null;
  return (filtered.first as Map<String, dynamic>)['localFilePath'] as String?;
}

String _normalizeUrl(String url) {
  const String suffixRegex = r'_(normal|bigger|400x400)';
  return url.replaceFirst(RegExp(suffixRegex), '');
}

Map<String, dynamic>? _applyReversePatchInline(
  Map<String, dynamic> target,
  Map<String, dynamic> patch,
) {
  try {
    final reconstructedJson = Map<String, dynamic>.from(target);
    _applyPatchRecursive(reconstructedJson, patch);
    return reconstructedJson;
  } catch (_) {
    return null;
  }
}

const _keyToBeRemovedMarker = '__KEY_TO_BE_REMOVED__';

void _applyPatchRecursive(
  Map<String, dynamic> target,
  Map<String, dynamic> patch,
) {
  patch.forEach((key, patchValue) {
    if (patchValue == _keyToBeRemovedMarker) {
      target.remove(key);
    } else if (patchValue is Map<String, dynamic> &&
        target[key] is Map<String, dynamic>) {
      final targetValueMap = target[key] as Map<String, dynamic>?;
      if (targetValueMap != null) {
        _applyPatchRecursive(targetValueMap, patchValue);
      } else {
        target[key] = patchValue;
      }
    } else {
      target[key] = patchValue;
    }
  });
}
