import 'package:autonitor/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('copyWith updates apiRequestMode while preserving other values', () {
      final original = AppSettings(
        themeMode: ThemeMode.dark,
        apiRequestMode: 'dio',
      );

      final updated = original.copyWith(apiRequestMode: 'curl_cffi');

      expect(updated.apiRequestMode, 'curl_cffi');
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.saveAvatarHistory, true);
      expect(updated.theme, ThemeColor.defaultThemeColor);
    });

    test('round-trips FastAPI settings through JSON', () {
      final settings = AppSettings(
        apiRequestMode: 'curl_cffi',
        remoteFastApiUrl: 'https://example.com/api',
        fastApiApiKey: 'secret-token',
      );

      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.apiRequestMode, 'curl_cffi');
      expect(restored.remoteFastApiUrl, 'https://example.com/api');
      expect(restored.fastApiApiKey, 'secret-token');
    });
  });
}
