import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/account.dart';

final secureStorageServiceProvider = Provider((ref) => SecureStorageService());

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  
  static const _accountsKey = 'accounts_list';
  static const _activeAccountIdKey = 'active_account_id';

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
  Future<String?> readActiveAccountId() async {
    try {
      return await _storage.read(key: _activeAccountIdKey);
    } catch (e) {
      print("Error reading active account ID: $e");
      return null;
    }
  }
  Future<void> saveActiveAccountId(String id) async {
    try {
      await _storage.write(key: _activeAccountIdKey, value: id);
    } catch (e) {
      print("Error saving active account ID: $e");
    }
  }
  Future<void> deleteActiveAccountId() async {
    try {
      await _storage.delete(key: _activeAccountIdKey);
    } catch (e) {
      print("Error deleting active account ID: $e");
    }
  }
}

