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
        final action = payload['action'] as String? ?? 'process_history';
        dynamic result;

        if (action == 'fetch_latest_diff') {
          result = _findLatestRelevantDiff(payload);
        } else if (action == 'fetch_field_history') {
          result = _extractFieldHistory(payload);
        } else {
          result = _processHistory(payload);
        }

        replyToMain.send([id, result]);
      } catch (_) {
        final action = payload['action'] as String? ?? 'process_history';
        replyToMain.send([
          id,
          action == 'fetch_latest_diff' ? null : {'total': 0, 'items': []},
        ]);
      }
    }
  });
}

// --- Core Logic ---

List<Map<String, dynamic>> _extractFieldHistory(Map<String, dynamic> context) {
  final String latestRawJson = context['latestRawJson'];
  final List<dynamic> historyEntries = context['historyEntries'];
  final String targetKey = context['targetKey'];
  // [修复] 使用 Repository 注入的业务时间作为当前锚点
  final int currentTs =
      context['currentStateTimestampMs'] ??
      DateTime.now().millisecondsSinceEpoch;

  List<Map<String, dynamic>> series = [];
  Map<String, dynamic> stateCursor;
  try {
    stateCursor = jsonDecode(latestRawJson);
  } catch (_) {
    return [];
  }

  series.add({
    'timestamp': currentTs,
    'value':
        (double.tryParse(stateCursor[targetKey]?.toString() ?? '0') ?? 0.0),
  });

  for (var entry in historyEntries) {
    final Map<String, dynamic> entryMap = entry as Map<String, dynamic>;
    final reverseDiffJson = entryMap['reverseDiffJson'] as String;

    Map<String, dynamic> patch;
    try {
      patch = jsonDecode(reverseDiffJson);
    } catch (_) {
      patch = {};
    }

    stateCursor = _applyReversePatchInline(stateCursor, patch) ?? stateCursor;

    series.add({
      'timestamp': entryMap['timestampMs'],
      'value':
          (double.tryParse(stateCursor[targetKey]?.toString() ?? '0') ?? 0.0),
    });
  }

  return series.reversed.toList();
}

Map<String, dynamic> _processHistory(Map<String, dynamic> context) {
  final String userId = context['userId'];
  final String latestRawJson = context['latestRawJson'];
  final List<dynamic> historyEntries = context['historyEntries'];
  final List<dynamic> mediaHistory = context['mediaHistory'];
  final int page = context['page'] as int? ?? 1;
  final int pageSize = context['pageSize'] as int? ?? 20;
  final String? filterField = context['filterField'];

  if (historyEntries.isEmpty) {
    return {'total': 0, 'items': []};
  }

  // 1. 重建完整时间线节点
  List<_SnapshotNode> timeline = [];
  Map<String, dynamic> stateCursor;
  try {
    stateCursor = jsonDecode(latestRawJson);
  } catch (_) {
    return {'total': 0, 'items': []};
  }

  for (int i = 0; i < historyEntries.length; i++) {
    final entryMap = historyEntries[i] as Map<String, dynamic>;
    final reverseDiffJson = entryMap['reverseDiffJson'] as String;

    Map<String, dynamic> patchToPrev;
    try {
      patchToPrev = jsonDecode(reverseDiffJson) as Map<String, dynamic>;
    } catch (_) {
      patchToPrev = {};
    }

    // 回溯状态
    final statePrev =
        _applyReversePatchInline(stateCursor, patchToPrev) ?? stateCursor;

    timeline.add(
      _SnapshotNode(
        entryId: entryMap['id'] as int,
        // [修复] 捕获 runId
        runId: entryMap['runId'] as String?,
        timestampMs: entryMap['timestampMs'] as int,
        data: statePrev,
      ),
    );

    stateCursor = statePrev;
  }

  // 2. 基于内容的去重/过滤
  Map<String, dynamic> lastKeptData = jsonDecode(latestRawJson);
  List<_SnapshotNode> validSnapshots = [];

  for (final node in timeline) {
    if (_hasRelevantDiff(lastKeptData, node.data, filterField: filterField)) {
      validSnapshots.add(node);
      lastKeptData = node.data;
    }
  }

  // 3. 生成结果
  List<Map<String, dynamic>> results = [];

  for (int i = 0; i < validSnapshots.length; i++) {
    final currentParams = validSnapshots[i];
    final Map<String, dynamic> currentData = currentParams.data;

    Map<String, dynamic> diffMap = {};

    if (i + 1 < validSnapshots.length) {
      final olderData = validSnapshots[i + 1].data;
      diffMap = _computeForwardDiff(olderData, currentData);
    } else {
      diffMap = _computeForwardDiff({}, currentData);
    }

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
      // [修复] 返回 runId
      'runId': currentParams.runId,
      'timestampMs': currentParams.timestampMs,
      'fullJson': jsonEncode(currentData),
      'userMap': userMap,
      'diffJson': jsonEncode(diffMap),
    });
  }

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

// --- Data Structures ---

class _SnapshotNode {
  final int entryId;
  // [修复] 增加 runId 字段
  final String? runId;
  final int timestampMs;
  final Map<String, dynamic> data;
  _SnapshotNode({
    required this.entryId,
    this.runId,
    required this.timestampMs,
    required this.data,
  });
}

// --- Helpers ---

const Set<String> _textKeys = {
  "name",
  "screen_name",
  "bio",
  "location",
  "link",
  "url",
};
final Set<String> _relevantKeys = _textKeys.union({"avatar_url", "banner_url"});

bool _hasRelevantDiff(
  Map<String, dynamic> a,
  Map<String, dynamic> b, {
  String? filterField,
}) {
  // [修复] 精准过滤逻辑
  if (filterField != null) {
    final valA = a[filterField];
    final valB = b[filterField];
    if ((valA == null || valA == "") && (valB == null || valB == "")) {
      return false;
    }
    return valA != valB;
  }

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

Map<String, dynamic>? _findLatestRelevantDiff(Map<String, dynamic> context) {
  final String latestRawJson = context['latestRawJson'];
  final List<dynamic> historyEntries = context['historyEntries'];

  if (historyEntries.isEmpty) return null;

  Map<String, dynamic> stateCurrent;
  try {
    stateCurrent = jsonDecode(latestRawJson);
  } catch (_) {
    return null;
  }

  final Map<String, dynamic> stateTarget = Map.from(stateCurrent);

  for (int i = 0; i < historyEntries.length; i++) {
    final entryMap = historyEntries[i] as Map<String, dynamic>;
    final reverseDiffJson = entryMap['reverseDiffJson'] as String;

    Map<String, dynamic> patchToPrev;
    try {
      patchToPrev = jsonDecode(reverseDiffJson) as Map<String, dynamic>;
    } catch (_) {
      patchToPrev = {};
    }

    final statePrev =
        _applyReversePatchInline(stateCurrent, patchToPrev) ?? stateCurrent;

    final diff = _computeForwardDiff(statePrev, stateTarget);

    if (diff.isNotEmpty) {
      return {
        'diffJson': jsonEncode(diff),
        'fullJson': jsonEncode(stateTarget),
        'timestampMs': entryMap['timestampMs'],
      };
    }

    stateCurrent = statePrev;
  }

  return null;
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
