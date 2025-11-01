import 'dart:convert'; // 用于 JSON 编解码
import 'package:shared_preferences/shared_preferences.dart'; // 导入插件
import '../models/app_settings.dart'; // 导入设置模型

/// 用于加载和保存应用设置的服务类。
class SettingsService {
  // 用于在 shared_preferences 中存储设置的键
  static const _settingsKey = 'app_settings_v1';

  /// 从 shared preferences 加载设置。
  /// 如果找不到或发生错误，则返回默认设置。
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      if (jsonString != null) {
        // 如果找到了 JSON 字符串，解码并用 fromJson 创建 AppSettings 对象
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return AppSettings.fromJson(jsonMap);
      }
    } catch (e) {
      // 记录错误或处理损坏的数据
      print('加载设置时出错: $e');
    }
    // 如果加载失败或不存在设置，则返回默认设置
    return AppSettings();
  }

  /// 将给定的设置保存到 shared preferences。
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 将 AppSettings 对象用 toJson 转换为 JSON Map，然后编码为字符串
      final jsonString = jsonEncode(settings.toJson());
      // 将 JSON 字符串保存到 shared preferences
      await prefs.setString(_settingsKey, jsonString);
    } catch (e) {
      // 记录错误或处理保存失败
      print('保存设置时出错: $e');
    }
  }
}
