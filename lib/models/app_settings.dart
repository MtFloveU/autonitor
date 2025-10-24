import 'package:flutter/material.dart';

class AppSettings {
  /// 选择的语言 ('Auto', '简体中文', 'English' 等)。
  final Locale? locale;
  // 未来可以添加其他设置字段，例如：
  // final bool isDarkMode;

  /// 构造函数，默认语言为 'Auto'。
  AppSettings({
    this.locale,
    // 在这里初始化其他默认设置
    // this.isDarkMode = false,
  });

  /// 创建一个包含更新值的新实例。
  AppSettings copyWith({Locale? locale}) {
    return AppSettings(locale: locale);
  }

  /// 将设置对象转换为 JSON Map 以便存储。
  Map<String, dynamic> toJson() => {
    'languageCode': locale?.languageCode,
    'countryCode': locale?.countryCode,
  };

  /// 从 JSON Map 创建设置对象。
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final languageCode = json['languageCode'] as String?;
    final countryCode = json['countryCode'] as String?;
    return AppSettings(
      locale: languageCode != null ? Locale(languageCode, countryCode) : null,
    );
  }
}
