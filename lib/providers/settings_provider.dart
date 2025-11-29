import 'package:autonitor/models/graphql_operation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:autonitor/services/log_service.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
      final service = ref.watch(settingsServiceProvider);
      final log = ref.watch(loggerProvider);
      return SettingsNotifier(service, log);
    });

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsService _settingsService;
  final Logger _log;

  SettingsNotifier(this._settingsService, this._log)
    : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _settingsService.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      _log.e('加载设置失败', error: e, stackTrace: s);
    }
  }

  Future<void> updateCustomGqlQueryId(
    String operationName,
    String newQueryId,
  ) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) return;

    final currentSettings = currentState.value;
    final newQueryIds = Map<String, String>.from(
      currentSettings.customGqlQueryIds,
    );
    newQueryIds[operationName] = newQueryId;

    final newState = currentSettings.copyWith(customGqlQueryIds: newQueryIds);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }

  // (新) 用于更新所有路径 (例如：API 刷新成功时)
  Future<void> updateCustomGqlQueryIds(Map<String, String> newQueryIds) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) return;

    final currentSettings = currentState.value;
    // 直接用新路径覆盖旧路径（因为这是 API 成功获取的结果）
    final newState = currentSettings.copyWith(customGqlQueryIds: newQueryIds);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }

  // In: class SettingsNotifier ...
  Future<void> updateLocale(Locale? newLocale) async {
    final currentSettings = state.value ?? AppSettings();
    final newState = AppSettings(
      locale: newLocale,
      themeMode: currentSettings.themeMode,
      saveAvatarHistory: currentSettings.saveAvatarHistory,
      saveBannerHistory: currentSettings.saveBannerHistory,
      avatarQuality: currentSettings.avatarQuality,
      historyStrategy: currentSettings.historyStrategy,
      historyLimitN: currentSettings.historyLimitN,
    );

    state = AsyncValue.data(newState);

    try {
      await _settingsService.saveSettings(newState);
    } catch (e, s) {
      state = AsyncValue.error('保存语言设置失败: $e', s);
      _log.e('保存语言设置失败', error: e, stackTrace: s);
    }
  }

  Future<void> updateSaveAvatarHistory(bool saveAvatar) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) {
      return;
    }
    final currentSettings = currentState.value;
    final newState = currentSettings.copyWith(saveAvatarHistory: saveAvatar);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }

  Future<void> updateSaveBannerHistory(bool saveBanner) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) {
      return;
    }
    final currentSettings = currentState.value;
    final newState = currentSettings.copyWith(saveBannerHistory: saveBanner);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }

  Future<void> updateAvatarQuality(AvatarQuality avatarQuality) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) {
      return;
    }
    final currentSettings = currentState.value;
    final newState = currentSettings.copyWith(avatarQuality: avatarQuality);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }

  Future<void> updateHistoryStrategy(HistoryStrategy historyStrategy) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) {
      return;
    }
    final currentSettings = currentState.value;
    final newState = currentSettings.copyWith(historyStrategy: historyStrategy);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }

  Future<void> updateHistoryLimitN(int historyLimitN) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) {
      return;
    }
    final currentSettings = currentState.value;
    final newState = currentSettings.copyWith(historyLimitN: historyLimitN);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }

  Future<void> updateThemeMode(ThemeMode newMode) async {
    final currentSettings = state.value ?? AppSettings();
    final newState = currentSettings.copyWith(themeMode: newMode);

    state = AsyncValue.data(newState);

    try {
      await _settingsService.saveSettings(newState);
    } catch (e, s) {
      state = AsyncValue.error('Failed to save theme: $e', s);
      _log.e('Failed to save themeMode setting', error: e, stackTrace: s);
    }
  }

  Future<void> resetCustomGqlQueryIds(Map<String, String> defaultPaths) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) return;

    final currentSettings = currentState.value;
    final newState = currentSettings.copyWith(customGqlQueryIds: defaultPaths);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }

  Future<void> updateGqlQueryIdSource(QueryIdSource newSource) async {
    final currentState = state;
    if (currentState is! AsyncData<AppSettings>) return;

    final currentSettings = currentState.value;
    final newState = currentSettings.copyWith(gqlQueryIdSource: newSource);
    state = AsyncValue.data(newState);
    await _settingsService.saveSettings(newState);
  }
}
