import 'dart:async';
import 'dart:isolate';
import 'dart:convert';

/// 一个纯净的 Worker，不依赖任何 Flutter 插件或数据库类
class HistoryRebuildWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort; // 动态接收端口
  final Map<int, Completer<dynamic>> _completers = {};
  int _nextId = 0;
  bool _initializing = false;

  HistoryRebuildWorker();

  Future<void> initIfNeeded() async {
    // ✅ 如果 sendPort 还活着，直接用
    if (_sendPort != null && _receivePort != null) return;

    // ✅ 如果之前被 dispose 过，允许重建
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

      // ✅ 不再使用 timeout，等待真实初始化完成
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

// --- Isolate 入口 ---
@pragma('vm:entry-point')
void _historyIsolateEntry(SendPort replyToMain) {
  final workerReceive = ReceivePort();

  // ✅ 把 worker 的 SendPort 发回主 isolate
  replyToMain.send(workerReceive.sendPort);

  workerReceive.listen((message) async {
    if (message is List && message.length == 2) {
      final int id = message[0] as int;
      final Map<String, dynamic> payload = message[1] as Map<String, dynamic>;

      try {
        final result = _processHistory(payload);
        replyToMain.send([id, result]);
      } catch (_) {
        replyToMain.send([id, []]);
      }
    }
  });
}

// --- 纯逻辑处理函数 ---
List<Map<String, dynamic>> _processHistory(Map<String, dynamic> context) {
  final String userId = context['userId'];
  final String latestRawJson = context['latestRawJson'];
  // 强转 List
  final List<dynamic> historyEntries = context['historyEntries'];
  final List<dynamic> mediaHistory = context['mediaHistory'];

  if (historyEntries.isEmpty) return [];

  Map<String, dynamic> currentJsonMap;
  try {
    currentJsonMap = jsonDecode(latestRawJson);
  } catch (_) {
    return [];
  }

  final List<Map<String, dynamic>> results = [];

  for (final entry in historyEntries) {
    // entry 也是 Map<String, dynamic>，因为它是从主isolate传过来的纯数据
    final entryMap = entry as Map<String, dynamic>;
    final reverseDiffJson = entryMap['reverseDiffJson'] as String;

    Map<String, dynamic> patchMap;
    try {
      patchMap = jsonDecode(reverseDiffJson) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }

    final patchKeys = patchMap.keys.toSet();
    final hasRelevantChange = patchKeys.any((k) => _relevantKeys.contains(k));

    // 使用本地内联的 applyReversePatch，避免引用外部文件
    final Map<String, dynamic>? oldVersionMap = _applyReversePatchInline(
      currentJsonMap,
      patchMap, // 传递解码后的 map 提高效率
    );

    if (oldVersionMap == null) continue;
    currentJsonMap = oldVersionMap; // 回溯状态

    if (!hasRelevantChange) continue;

    final snapshotAvatarUrl = currentJsonMap['avatar_url'] as String?;
    final snapshotBannerUrl = currentJsonMap['banner_url'] as String?;
    final snapshotTimestamp = DateTime.fromMillisecondsSinceEpoch(
      entryMap['timestampMs'],
    );

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

    if (avatarPath != null) currentJsonMap['avatar_local_path'] = avatarPath;
    if (bannerPath != null) currentJsonMap['banner_local_path'] = bannerPath;

    // 构造 User 对象所需的 Map
    final userMap = _constructUserMap(
      userId: userId,
      dbScreenName: currentJsonMap['screen_name'],
      dbName: currentJsonMap['name'],
      dbAvatarUrl: currentJsonMap['avatar_url'],
      dbAvatarLocalPath: avatarPath,
      dbBannerLocalPath: bannerPath,
      dbBio: currentJsonMap['bio'],
      jsonMap: currentJsonMap,
    );

    // 返回纯数据
    results.add({
      'entryId': entryMap['id'],
      'fullJson': jsonEncode(currentJsonMap),
      'userMap': userMap,
    });
  }

  return results;
}

// --- 辅助函数 (全部内联，不依赖外部) ---

const Set<String> _textKeys = {"name", "screen_name", "bio", "url", "location"};
final Set<String> _relevantKeys = _textKeys.union({"avatar_url", "banner_url"});

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
  // 优先使用 jsonMap 中的数据
  final merged = Map<String, dynamic>.from(jsonMap);

  // 确保关键字段存在（如果 jsonMap 中缺失，回退到 DB 字段）
  merged['rest_id'] ??= userId;
  merged['screen_name'] ??= dbScreenName;
  merged['name'] ??= dbName;
  merged['avatar_url'] ??= dbAvatarUrl;
  merged['bio'] ??= dbBio;

  // 注入本地路径
  if (dbAvatarLocalPath != null)
    merged['avatar_local_path'] = dbAvatarLocalPath;
  if (dbBannerLocalPath != null)
    merged['banner_local_path'] = dbBannerLocalPath;

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

  // 这里 history 是 List<Map<String, dynamic>>
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

// 内联的 Diff 应用逻辑，移除 logging，移除 diff_utils 依赖
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
