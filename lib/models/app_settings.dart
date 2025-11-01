import 'package:flutter/material.dart';

enum AvatarQuality { low, high }

enum HistoryStrategy { saveAll, saveLatest, saveLastN }

extension _EnumParser on String? {
  T toEnum<T>(List<T> values, T defaultValue) {
    if (this == null) return defaultValue;
    return values.firstWhere(
      (e) => e.toString().split('.').last == this,
      orElse: () => defaultValue,
    );
  }
}

class AppSettings {
  final Locale? locale;
  final ThemeMode themeMode;
  final bool saveAvatarHistory;
  final bool saveBannerHistory;
  final AvatarQuality avatarQuality;
  final HistoryStrategy historyStrategy;
  final int historyLimitN;

  AppSettings({
    this.locale,
    this.themeMode = ThemeMode.system,
    this.saveAvatarHistory = true,
    this.saveBannerHistory = false,
    this.avatarQuality = AvatarQuality.low,
    this.historyStrategy = HistoryStrategy.saveAll,
    this.historyLimitN = 5,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? saveAvatarHistory,
    bool? saveBannerHistory,
    AvatarQuality? avatarQuality,
    HistoryStrategy? historyStrategy,
    int? historyLimitN,
  }) {
    return AppSettings(
      locale: this.locale,
      themeMode: themeMode ?? this.themeMode,
      saveAvatarHistory: saveAvatarHistory ?? this.saveAvatarHistory,
      saveBannerHistory: saveBannerHistory ?? this.saveBannerHistory,
      avatarQuality: avatarQuality ?? this.avatarQuality,
      historyStrategy: historyStrategy ?? this.historyStrategy,
      historyLimitN: historyLimitN ?? this.historyLimitN,
    );
  }

  Map<String, dynamic> toJson() => {
    'languageCode': locale?.languageCode,
    'countryCode': locale?.countryCode,
    'themeMode': themeMode.name,
    'saveAvatarHistory': saveAvatarHistory,
    'saveBannerHistory': saveBannerHistory,
    'avatarQuality': avatarQuality.toString().split('.').last,
    'historyStrategy': historyStrategy.toString().split('.').last,
    'historyLimitN': historyLimitN,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaultSettings = AppSettings();

    final languageCode = json['languageCode'] as String?;
    final countryCode = json['countryCode'] as String?;

    return AppSettings(
      locale: languageCode != null ? Locale(languageCode, countryCode) : null,
      themeMode: (json['themeMode'] as String?).toEnum(
        ThemeMode.values,
        defaultSettings.themeMode,
      ),
      saveAvatarHistory:
          json['saveAvatarHistory'] as bool? ??
          defaultSettings.saveAvatarHistory,
      saveBannerHistory:
          json['saveBannerHistory'] as bool? ??
          defaultSettings.saveBannerHistory,
      avatarQuality: (json['avatarQuality'] as String?).toEnum(
        AvatarQuality.values,
        defaultSettings.avatarQuality,
      ),
      historyStrategy: (json['historyStrategy'] as String?).toEnum(
        HistoryStrategy.values,
        defaultSettings.historyStrategy,
      ),
      historyLimitN:
          json['historyLimitN'] as int? ?? defaultSettings.historyLimitN,
    );
  }
}
