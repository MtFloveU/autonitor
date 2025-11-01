import 'dart:convert';

/// 特殊标记，用于表示一个键在新 JSON 中存在但在旧 JSON 中不存在，
/// 因此在反向补丁中需要被删除。
const _keyToBeRemovedMarker = '__KEY_TO_BE_REMOVED__';

/// 计算两个 JSON 字符串之间的反向差异。
/// 返回一个 JSON 字符串，表示从 newJsonString 变回 oldJsonString 所需的补丁。
/// 如果没有差异，则返回 null。
String? calculateReverseDiff(String? newJsonString, String? oldJsonString) {
  if (oldJsonString == null || oldJsonString.isEmpty) {
    // 如果没有旧版本，则无法计算差异
    return null;
  }
  if (newJsonString == null || newJsonString.isEmpty) {
    // 如果新版本为空，则反向补丁就是旧版本本身（理论上不应发生）
    return oldJsonString;
  }

  try {
    final newJson = jsonDecode(newJsonString);
    final oldJson = jsonDecode(oldJsonString);

    if (newJson is! Map<String, dynamic> || oldJson is! Map<String, dynamic>) {
      // 只处理 Map 类型的 JSON 对象
      if (newJsonString != oldJsonString) {
        // 如果顶层不是 Map 且内容不同，返回整个旧 JSON 作为补丁
        return oldJsonString;
      }
      return null; // 内容相同
    }

    final diff = _compareMaps(newJson, oldJson);

    if (diff.isEmpty) {
      return null; // 没有差异
    }

    return jsonEncode(diff);
  } catch (e) {
    print("Error calculating JSON diff: $e");
    // 发生错误时，保守起见不生成补丁
    return null;
  }
}

/// 递归比较两个 Map 并生成反向差异。
Map<String, dynamic> _compareMaps(
  Map<String, dynamic> newMap,
  Map<String, dynamic> oldMap,
) {
  final diff = <String, dynamic>{};
  final allKeys = {...newMap.keys, ...oldMap.keys}; // 获取所有键的并集

  for (final key in allKeys) {
    final newValue = newMap[key];
    final oldValue = oldMap[key];

    if (oldMap.containsKey(key) && !newMap.containsKey(key)) {
      // 键只在旧 Map 中存在 (在新 Map 中被删除) -> 反向补丁记录旧值
      diff[key] = oldValue;
    } else if (newMap.containsKey(key) && !oldMap.containsKey(key)) {
      // 键只在新 Map 中存在 (是新增的) -> 反向补丁记录删除标记
      diff[key] = _keyToBeRemovedMarker;
    } else if (newMap.containsKey(key) && oldMap.containsKey(key)) {
      // 键在两者中都存在
      if (newValue is Map<String, dynamic> &&
          oldValue is Map<String, dynamic>) {
        // 如果值都是 Map，递归比较
        final nestedDiff = _compareMaps(newValue, oldValue);
        if (nestedDiff.isNotEmpty) {
          diff[key] = nestedDiff;
        }
      } else if (!_areEqual(newValue, oldValue)) {
        // 如果值不同 (且不是 Map)，反向补丁记录旧值
        diff[key] = oldValue;
      }
      // 如果值相同，则忽略，不加入 diff
    }
  }

  return diff;
}

/// 比较两个值是否相等 (考虑 List 和 Map 的深比较)
bool _areEqual(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_areEqual(a[key], b[key])) {
        return false;
      }
    }
    return true;
  } else if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_areEqual(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

/// 应用反向补丁到新的 JSON Map，以重建旧的 JSON Map。
Map<String, dynamic>? applyReversePatch(
  Map<String, dynamic>? newJson,
  String? patchString,
) {
  if (newJson == null) return null; // 无法在 null 上应用补丁
  if (patchString == null || patchString.isEmpty) return newJson; // 没有补丁，返回原样

  try {
    final patch = jsonDecode(patchString);
    if (patch is! Map<String, dynamic>) {
      // 如果补丁不是 Map，无法应用（理论上 calculateReverseDiff 不会生成这样的补丁）
      print("Error applying patch: Patch is not a Map.");
      return newJson;
    }

    // 创建一个新 Map 来存储结果，避免直接修改 newJson
    final reconstructedJson = Map<String, dynamic>.from(newJson);
    _applyPatchRecursive(reconstructedJson, patch);
    return reconstructedJson;
  } catch (e) {
    print("Error applying JSON patch: $e");
    // 发生错误时，返回原始 newJson
    return newJson;
  }
}

void _applyPatchRecursive(
  Map<String, dynamic> target,
  Map<String, dynamic> patch,
) {
  patch.forEach((key, patchValue) {
    if (patchValue == _keyToBeRemovedMarker) {
      // 如果补丁值是删除标记，则从目标中移除该键
      target.remove(key);
    } else if (patchValue is Map<String, dynamic> &&
        target[key] is Map<String, dynamic>) {
      // 如果补丁值和目标值都是 Map，递归应用补丁
      // 需要确保 target[key] 不是 null
      final targetValueMap = target[key] as Map<String, dynamic>?;
      if (targetValueMap != null) {
        _applyPatchRecursive(targetValueMap, patchValue);
      } else {
        // 如果目标值本来是 null 或不是 Map，则直接用补丁值覆盖（虽然理论上这不应发生）
        target[key] = patchValue;
      }
    } else {
      // 否则，直接用补丁值覆盖目标值（添加或修改）
      target[key] = patchValue;
    }
  });
}
