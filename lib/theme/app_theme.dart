import 'package:flutter/material.dart';
import 'package:autonitor/models/app_settings.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppTheme {
  /// 将 ThemeColor 枚举转换为 Flutter Color
  static Color? getSeedColor(ThemeColor colorEnum) {
    switch (colorEnum) {
      case ThemeColor.defaultThemeColor:
        return null; // 返回 null 以指示使用系统/动态颜色
      case ThemeColor.red:
        return Colors.red;
      case ThemeColor.pink:
        return Colors.pink;
      case ThemeColor.purple:
        return Colors.purple;
      case ThemeColor.deepPurple:
        return Colors.deepPurple;
      case ThemeColor.indigo:
        return Colors.indigo;
      case ThemeColor.blue:
        return Colors.blue;
      case ThemeColor.lightBlue:
        return Colors.lightBlue;
      case ThemeColor.cyan:
        return Colors.cyan;
      case ThemeColor.teal:
        return Colors.teal;
      case ThemeColor.green:
        return Colors.green;
      case ThemeColor.lightGreen:
        return Colors.lightGreen;
      case ThemeColor.lime:
        return Colors.lime;
      case ThemeColor.yellow:
        return Colors.yellow;
      case ThemeColor.amber:
        return Colors.amber;
      case ThemeColor.orange:
        return Colors.orange;
      case ThemeColor.deepOrange:
        return Colors.deepOrange;
      case ThemeColor.brown:
        return Colors.brown;
      case ThemeColor.grey:
        return Colors.grey;
      case ThemeColor.blueGrey:
        return Colors.blueGrey;
    }
  }

  /// 生成亮色主题方案
  static ColorScheme getLightScheme({
    required ThemeColor userThemeColor,
    required ColorScheme? lightDynamic,
  }) {
    final Color? userSeedColor = getSeedColor(userThemeColor);

    if (userSeedColor != null) {
      // A. 用户指定了颜色 -> 强制使用
      return ColorScheme.fromSeed(
        seedColor: userSeedColor,
        brightness: Brightness.light,
      );
    } else {
      // B. 用户选择跟随系统 (默认)
      bool useDynamicColor = false;
      if (!kIsWeb && Platform.isAndroid) {
        useDynamicColor = true;
      }

      if (useDynamicColor && lightDynamic != null) {
        // [混合策略]
        // 1. 先用系统主色生成一套标准的 Flutter MD3 色盘 (保证灰色系对比度)
        final baseScheme = ColorScheme.fromSeed(
          seedColor: lightDynamic.primary,
          brightness: Brightness.light,
        );

        // 2. 覆盖关键品牌色，确保与系统一致
        return baseScheme.copyWith(
          primary: lightDynamic.primary,
          onPrimary: lightDynamic.onPrimary,
          primaryContainer: lightDynamic.primaryContainer,
          onPrimaryContainer: lightDynamic.onPrimaryContainer,
          secondary: lightDynamic.secondary,
          onSecondary: lightDynamic.onSecondary,
          secondaryContainer: lightDynamic.secondaryContainer,
          onSecondaryContainer: lightDynamic.onSecondaryContainer,
          tertiary: lightDynamic.tertiary,
          onTertiary: lightDynamic.onTertiary,
          tertiaryContainer: lightDynamic.tertiaryContainer,
          onTertiaryContainer: lightDynamic.onTertiaryContainer,
          error: lightDynamic.error,
          onError: lightDynamic.onError,
          errorContainer: lightDynamic.errorContainer,
          onErrorContainer: lightDynamic.onErrorContainer,
        );
      } else {
        // 默认 fallback
        return ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        );
      }
    }
  }

  /// 生成暗色主题方案
  static ColorScheme getDarkScheme({
    required ThemeColor userThemeColor,
    required ColorScheme? darkDynamic,
  }) {
    final Color? userSeedColor = getSeedColor(userThemeColor);

    if (userSeedColor != null) {
      return ColorScheme.fromSeed(
        seedColor: userSeedColor,
        brightness: Brightness.dark,
      );
    } else {
      bool useDynamicColor = false;
      if (!kIsWeb && Platform.isAndroid) {
        useDynamicColor = true;
      }

      if (useDynamicColor && darkDynamic != null) {
        // [混合策略] - Dark
        final baseScheme = ColorScheme.fromSeed(
          seedColor: darkDynamic.primary,
          brightness: Brightness.dark,
        );

        return baseScheme.copyWith(
          primary: darkDynamic.primary,
          onPrimary: darkDynamic.onPrimary,
          primaryContainer: darkDynamic.primaryContainer,
          onPrimaryContainer: darkDynamic.onPrimaryContainer,
          secondary: darkDynamic.secondary,
          onSecondary: darkDynamic.onSecondary,
          secondaryContainer: darkDynamic.secondaryContainer,
          onSecondaryContainer: darkDynamic.onSecondaryContainer,
          tertiary: darkDynamic.tertiary,
          onTertiary: darkDynamic.onTertiary,
          tertiaryContainer: darkDynamic.tertiaryContainer,
          onTertiaryContainer: darkDynamic.onTertiaryContainer,
          error: darkDynamic.error,
          onError: darkDynamic.onError,
          errorContainer: darkDynamic.errorContainer,
          onErrorContainer: darkDynamic.onErrorContainer,
        );
      } else {
        return ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        );
      }
    }
  }
}
