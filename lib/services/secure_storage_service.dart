import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/account.dart';

// [已更新]
// 核心改动：
// 1. 移除了单Cookie的管理方法 (save/get/delete Cookie)，因为现在由 `AuthProvider` 统一管理。
// 2. `saveAccounts` 方法现在是公开的，以便 `AuthProvider` 可以调用。

final secureStorageServiceProvider = Provider((ref) => SecureStorageService());

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  
  static const _accountsKey = 'accounts_list';

  Future<List<Account>> getAccounts() async {
    try {
      final jsonString = await _storage.read(key: _accountsKey);
      if (jsonString == null) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Account.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> saveAccounts(List<Account> accounts) async {
    try {
      final List<Map<String, dynamic>> jsonList =
          accounts.map((account) => account.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _storage.write(key: _accountsKey, value: jsonString);
    } catch (e) {
      // handle error
    }
  }
}

