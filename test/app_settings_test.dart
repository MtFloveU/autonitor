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

    test('copyWith updates locale while preserving sync fetch mode', () {
      final original = AppSettings(
        locale: const Locale('en'),
        syncFetchMode: SyncFetchMode.expert,
      );

      final updated = original.copyWith(locale: const Locale('zh', 'CN'));

      expect(updated.locale, const Locale('zh', 'CN'));
      expect(updated.syncFetchMode, SyncFetchMode.expert);
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

    test('round-trips selected sync fetch mode through JSON', () {
      final settings = AppSettings(syncFetchMode: SyncFetchMode.fastest);

      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.syncFetchMode, SyncFetchMode.fastest);
    });

    test('falls back to Fast when curl_cffi is unavailable', () {
      final settings = AppSettings(
        apiRequestMode: 'dio',
        syncFetchMode: SyncFetchMode.expert,
      );

      expect(settings.effectiveSyncFetchMode, SyncFetchMode.fast);
    });

    test('round-trips the media saving scope through JSON', () {
      final settings = AppSettings(
        mediaSaveScope: MediaSaveScope.followingOnly,
      );

      final restored = AppSettings.fromJson(settings.toJson());

      expect(restored.mediaSaveScope, MediaSaveScope.followingOnly);
    });

    test('defaults an unknown media saving scope to all accounts', () {
      final restored = AppSettings.fromJson({'mediaSaveScope': 'unknown'});

      expect(restored.mediaSaveScope, MediaSaveScope.all);
    });
  });
}
