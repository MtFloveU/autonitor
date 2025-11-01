import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
      final service = ref.watch(settingsServiceProvider);
      return SettingsNotifier(service);
    });

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsService _settingsService;

  SettingsNotifier(this._settingsService) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _settingsService.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      print('加载设置失败: $e');
    }
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
      print('保存语言设置失败: $e');
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
      print('Failed to save themeMode setting: $e');
    }
  }
}
