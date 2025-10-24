import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 导入 Riverpod
import '../models/app_settings.dart'; // 导入模型
import '../services/settings_service.dart'; // 导入服务

// 提供 SettingsService 实例的 Provider
final settingsServiceProvider = Provider((ref) => SettingsService());

// 用于管理 AppSettings 状态并通知变化的 StateNotifierProvider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  // 依赖 settingsServiceProvider 来获取服务实例
  final service = ref.watch(settingsServiceProvider);
  // 创建 SettingsNotifier 并传入服务
  return SettingsNotifier(service);
});

// StateNotifier 类，包含加载和更新设置的逻辑
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsService _settingsService;

  // 构造函数，初始化状态为加载中，并立即开始加载设置
  SettingsNotifier(this._settingsService) : super(const AsyncValue.loading()) {
    _load(); 
  }

  /// 异步加载设置并更新状态
  Future<void> _load() async {
    state = const AsyncValue.loading(); // 设置为加载中状态
    try {
      final settings = await _settingsService.loadSettings(); // 调用服务加载
      state = AsyncValue.data(settings); // 加载成功，更新状态为数据
    } catch (e, s) {
      state = AsyncValue.error(e, s); // 加载失败，更新状态为错误
      print('加载设置失败: $e');
    }
  }

  /// 更新应用语言设置
  Future<void> updateLocale(Locale? newLocale) async {
    // 获取当前状态的数据，如果状态是加载中或错误，则使用默认设置
    final currentSettings = state.value ?? AppSettings(); 

    // 使用 copyWith 创建包含新语言的设置对象
    final newState = currentSettings.copyWith(locale: newLocale);

    // 立即乐观地更新 UI 状态为新数据
    state = AsyncValue.data(newState);

    // 调用服务将新状态持久化保存
    try {
      await _settingsService.saveSettings(newState);
    } catch (e, s) {
      // 如果保存失败，将状态设置为错误，并打印日志
      state = AsyncValue.error('保存语言设置失败: $e', s);
      // （可选）可以考虑重新加载之前的状态：await _load();
      print('保存语言设置失败: $e');
    }
  }

  // 未来可以在这里添加更新其他设置的方法
  // Future<void> updateDarkMode(bool isDark) async { ... }
}