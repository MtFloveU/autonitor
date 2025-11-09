import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/graphql_operation.dart';
import '../services/graphql_path_service.dart'; // 远程 API 获取
import 'settings_provider.dart'; // 访问 AppSettings
import '../services/log_service.dart';
import '../models/app_settings.dart'; // 导入 AppSettings 和 PathSource
import 'package:flutter/material.dart'; // 用于 SnackBar

// 假设这是所有需要配置的 Operation Name 列表 (与 Service 中保持一致)
const List<String> _targetOperations = [
  'UserByRestId',
  'UserByScreenName',
  'Followers',
  'Following',
];

// 辅助函数：生成默认路径（与 Service 中的默认值保持一致）
Map<String, String> _getDefaultPaths() {
  return {
    'UserByRestId': '/graphql/q9yeu7UlEs2YVx_-Z8Ps7Q/UserByRestId',
    'UserByScreenName': '/graphql/pQeI5l8v2eYn0n_v-Qv27A/UserByScreenName',
    'Followers': '/graphql/Efm7xwLreAw77q2Fq7rX-Q/Followers',
    'Following': '/graphql/Efm7xwLreAw77q2Fq7rX-Q/Following',
  };
}


class GqlPathState {
  final PathSource source;
  final List<GraphQLOperation> apiOperations; // 从 JSON 获取的列表
  final Map<String, String>
  customPaths; // operationName -> customPath (来自 Settings)
  final String? selectedOperationName; // 当前选中的 Operation Name
  final bool isLoading;
  final String? error;
  final bool isApiDataLoaded; // (新) 标记 API 数据是否已成功加载过

  GqlPathState({
    this.source = PathSource.apiDocument,
    this.apiOperations = const [],
    this.customPaths = const {},
    this.selectedOperationName,
    this.isLoading = false,
    this.error,
    this.isApiDataLoaded = false, // (新) 默认未加载
  });

  GqlPathState copyWith({
    PathSource? source,
    List<GraphQLOperation>? apiOperations,
    Map<String, String>? customPaths,
    String? selectedOperationName,
    bool? isLoading,
    String? error,
    bool? isApiDataLoaded, // (新)
  }) {
    return GqlPathState(
      source: source ?? this.source,
      apiOperations: apiOperations ?? this.apiOperations,
      customPaths: customPaths ?? this.customPaths,
      selectedOperationName:
          selectedOperationName ?? this.selectedOperationName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isApiDataLoaded: isApiDataLoaded ?? this.isApiDataLoaded, // (新)
    );
  }
}

class GqlPathNotifier extends StateNotifier<GqlPathState> {
  final Ref _ref;
  final GraphQLService _graphQLApiService;

  GqlPathNotifier(this._ref, this._graphQLApiService) : super(GqlPathState()) {
    // 1. 监听 SettingsProvider，以获取最新的 Custom Paths 和 Source
    _ref.listen<AsyncValue<AppSettings>>(settingsProvider, (previous, next) {
      if (next.hasValue) {
        final settings = next.value!;
        final newCustomPaths = _ensureAllPathsExist(settings.customGqlPaths);
        final List<GraphQLOperation> persistedApiOps =
            _convertPersistedPathsToOperations(newCustomPaths);
        // 从 Settings 中读取 source
        state = state.copyWith(
          customPaths: newCustomPaths,
          source: settings.gqlPathSource,
          apiOperations: persistedApiOps,
          isApiDataLoaded: persistedApiOps.length == _targetOperations.length,
        );
      }
    });

    // 2. 初始加载本地状态 (不自动获取 API)
    _initialLoadLocalState();
  }

  // (新) 仅加载本地状态，不自动获取 API 数据
  Future<void> _initialLoadLocalState() async {
    // 确保 Settings 已加载
    final settingsAsync = _ref.read(settingsProvider);
    if (!settingsAsync.hasValue) {
      // 如果还没有值，直接返回或抛出异常
      return;
    }
    final currentSettings = settingsAsync.value!;

    final customPaths = _ensureAllPathsExist(currentSettings.customGqlPaths);

    // 默认选择第一个 Operation Name
    final firstOpName = _targetOperations.first;

    // 需要定义 persistedApiOps
    final persistedApiOps = _convertPersistedPathsToOperations(customPaths);

    state = state.copyWith(
      customPaths: customPaths,
      isLoading: false,
      selectedOperationName: firstOpName,
      source: currentSettings.gqlPathSource,
      apiOperations: persistedApiOps,
      isApiDataLoaded: persistedApiOps.length == _targetOperations.length,
    );
  }

  List<GraphQLOperation> _convertPersistedPathsToOperations(
    Map<String, String> paths,
  ) {
    final List<GraphQLOperation> ops = [];
    for (final opName in _targetOperations) {
      final path = paths[opName];
      if (path != null && path.isNotEmpty && path.contains('/graphql/')) {
        // 尝试从路径中解析 queryId
        final parts = path.split('/');
        if (parts.length >= 4) {
          final queryId = parts[parts.length - 2];
          ops.add(
            GraphQLOperation(
              queryId: queryId,
              operationName: opName,
              path: path,
            ),
          );
        }
      }
    }
    return ops;
  }

  // 确保 customPaths 包含所有 targetOperations 的默认值
  Map<String, String> _ensureAllPathsExist(Map<String, String> paths) {
    final defaults = _getDefaultPaths();
    final Map<String, String> result = Map.from(paths);
    for (final opName in _targetOperations) {
      if (!result.containsKey(opName) || result[opName]!.isEmpty) {
        result[opName] = defaults[opName]!;
      }
    }
    return result;
  }

  // 用户点击 Refresh 按钮时调用
  Future<void> loadApiData(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      final operations = await _graphQLApiService.fetchAndParseOperations();
      final Map<String, String> newApiPaths = {
        for (var op in operations) op.operationName: op.path,
      };
      _ref.read(settingsProvider.notifier).updateCustomGqlPaths(newApiPaths);

      state = state.copyWith(
        apiOperations: operations,
        isLoading: false,
        error: null,
        isApiDataLoaded: true, // 成功加载
      );
      state = state.copyWith(
        apiOperations: operations,
        isLoading: false,
        error: null,
        isApiDataLoaded: true, // 成功加载
      );
    } catch (e, s) {
      logger.e(
        "User refresh of GraphQL API paths failed: $e",
        error: e,
        stackTrace: s,
      );

      // 1. SnackBar 报错
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            "API Refresh Failed: ${e.toString()}",
            style: TextStyle(color: theme.colorScheme.onError),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );

      // 2. 停止获取，并确保 API 列表为空，isApiDataLoaded 为 false
      state = state.copyWith(
        isLoading: false,
        error: "API Refresh Failed: ${e.toString()}",
        apiOperations: [], // 清空 API 列表
        isApiDataLoaded: false, // 标记为加载失败
      );
    }
  }

  void setSource(PathSource newSource) {
    // 1. 更新 Settings (持久化)
    _ref.read(settingsProvider.notifier).updateGqlPathSource(newSource);
    // 2. state 会通过 listen 自动更新
  }

  void setSelectedOperation(String name) {
    state = state.copyWith(selectedOperationName: name);
  }

  // 更新单个自定义路径并持久化 (调用 SettingsNotifier)
  void updateCustomPath(String operationName, String newPath) {
    _ref
        .read(settingsProvider.notifier)
        .updateCustomGqlPath(operationName, newPath);
    // state 会通过 listen 自动更新
  }

  // 重置所有自定义路径到默认值 (调用 SettingsNotifier)
  void resetCustomPaths() {
    _ref
        .read(settingsProvider.notifier)
        .resetCustomGqlPaths(_getDefaultPaths());
    // state 会通过 listen 自动更新
  }

  // 辅助方法：获取当前选定操作的实际路径 (用于 UI 显示)
  String getCurrentPathForDisplay(String operationName) {
    if (state.source == PathSource.apiDocument) {
      // 如果 API 数据未加载，或者当前操作不在已加载的列表中，则显示默认路径
      final op = state.apiOperations.firstWhere(
        (e) => e.operationName == operationName,
        orElse: () => GraphQLOperation(
          queryId: '',
          operationName: '',
          path:
              _getDefaultPaths()[operationName] ??
              'N/A: API Data Not Available',
        ),
      );
      return op.path;
    } else {
      return state.customPaths[operationName] ?? '';
    }
  }

  // 辅助方法：获取当前选定操作的实际路径 (用于生成 ID)
  String getCurrentPathForGeneration() {
    final selectedName = state.selectedOperationName;
    if (selectedName == null) return '';

    if (state.source == PathSource.apiDocument) {
      final op = state.apiOperations.firstWhere(
        (e) => e.operationName == selectedName,
        orElse: () => GraphQLOperation(
          queryId: '',
          operationName: '',
          path: _getDefaultPaths()[selectedName] ?? '', // 失败时使用默认路径
        ),
      );
      return op.path;
    } else {
      return state.customPaths[selectedName] ?? '';
    }
  }

  List<String> get targetOperations => _targetOperations;
}

final gqlPathProvider =
    StateNotifierProvider.autoDispose<GqlPathNotifier, GqlPathState>((ref) {
      return GqlPathNotifier(
        ref,
        ref.read(graphQLServiceProvider), // 来自 graphql_path_service.dart
      );
    });
