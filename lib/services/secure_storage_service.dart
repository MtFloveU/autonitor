import 'package:autonitor/services/log_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider((ref) => SecureStorageService());

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _activeAccountIdKey = 'active_account_id';

  /// 保存指定 ID 的 cookie
  Future<void> saveCookie(String id, String cookie) async {
    try {
      // 使用账号 ID 作为 key 的一部分，确保唯一性
      await _storage.write(key: 'cookie_$id', value: cookie);
    } catch (e, s) {
      logger.e("Error saving cookie for ID $id", error: e, stackTrace: s);
      // 可以考虑向上抛出异常，让调用者知道失败了
      // throw Exception('Failed to save cookie: $e');
    }
  }

  /// 读取指定 ID 的 cookie
  Future<String?> getCookie(String id) async {
    try {
      return await _storage.read(key: 'cookie_$id');
    } catch (e, s) {
      logger.e("Error reading cookie for ID $id: $e", error: e, stackTrace: s);
      return null;
    }
  }

  /// 删除指定 ID 的 cookie
  Future<void> deleteCookie(String id) async {
    try {
      await _storage.delete(key: 'cookie_$id');
    } catch (e, s) {
      logger.e("Error deleting cookie for ID $id: $e", error: e, stackTrace: s);
      // 可以考虑向上抛出异常
      // throw Exception('Failed to delete cookie: $e');
    }
  }

  Future<Map<String, String>> getAllCookies() async {
    try {
      // 读取所有 secure storage 中的键值对
      final allValues = await _storage.readAll();
      final Map<String, String> cookies = {};
      // 筛选出以 'cookie_' 开头的键
      allValues.forEach((key, value) {
        if (key.startsWith('cookie_')) {
          // 提取 ID (去掉 'cookie_' 前缀)
          final id = key.substring('cookie_'.length);
          cookies[id] = value;
        }
      });
      return cookies;
    } catch (e, s) {
      logger.e("Error reading all cookies", error: e, stackTrace: s);
      return {}; // 出错时返回空 Map
    }
  }

  Future<String?> readActiveAccountId() async {
    try {
      return await _storage.read(key: _activeAccountIdKey);
    } catch (e, s) {
      logger.e("Error reading active account ID", error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> saveActiveAccountId(String id) async {
    try {
      await _storage.write(key: _activeAccountIdKey, value: id);
    } catch (e, s) {
      logger.e("Error saving active account ID", error: e, stackTrace: s);
    }
  }

  Future<void> deleteActiveAccountId() async {
    try {
      await _storage.delete(key: _activeAccountIdKey);
    } catch (e, s) {
      logger.e("Error deleting active account ID", error: e, stackTrace: s);
    }
  }
}
