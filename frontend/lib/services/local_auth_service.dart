// frontend/lib/services/local_auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class LocalAuthService {
  static const String _boxName = 'user_accounts';
  static const String _currentAccountKey = 'current_account_id';
  Box<dynamic>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<UserProfile?> getCurrentUser() async {
    if (_box == null) await initialize();

    final currentId = _box?.get(_currentAccountKey);
    if (currentId == null) return null;

    final data = _box?.get(currentId);
    if (data == null) return null;

    return UserProfile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<UserProfile>> getAllAccounts() async {
    if (_box == null) await initialize();

    final accounts = <UserProfile>[];
    for (final key in _box!.keys) {
      if (key == _currentAccountKey) continue;

      final data = _box!.get(key);
      if (data != null) {
        accounts.add(UserProfile.fromJson(Map<String, dynamic>.from(data)));
      }
    }

    return accounts;
  }

  Future<bool> login({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      // For demo: accept any 4-digit OTP
      if (otp.length != 4) {
        return false;
      }

      // Check if account exists
      final existingAccount = await _getAccountByPhone(phoneNumber);
      
      UserProfile profile;
      if (existingAccount != null) {
        profile = existingAccount.copyWith(isActive: true);
      } else {
        // Create new account
        profile = UserProfile(
          id: 'account_${DateTime.now().millisecondsSinceEpoch}',
          storeName: 'My Store',
          ownerName: 'Owner',
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
          isActive: true,
        );
      }

      // Save account
      await _saveAccount(profile);
      await _setCurrentAccount(profile.id);

      return true;
    } catch (e) {
      debugPrint('[LocalAuthService] Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    if (_box == null) await initialize();

    final currentId = _box?.get(_currentAccountKey);
    if (currentId != null) {
      final data = _box?.get(currentId);
      if (data != null) {
        final profile = UserProfile.fromJson(Map<String, dynamic>.from(data));
        final updated = profile.copyWith(isActive: false);
        await _box!.put(currentId, updated.toJson());
      }
    }

    await _box?.delete(_currentAccountKey);
  }

  Future<void> updateProfile(UserProfile profile) async {
    if (_box == null) await initialize();
    await _saveAccount(profile);
  }

  Future<void> switchAccount(String accountId) async {
    if (_box == null) await initialize();
    await _setCurrentAccount(accountId);
  }

  Future<void> deleteAccount(String accountId) async {
    if (_box == null) await initialize();
    await _box?.delete(accountId);

    final currentId = _box?.get(_currentAccountKey);
    if (currentId == accountId) {
      await _box?.delete(_currentAccountKey);
    }
  }

  // Private helpers

  Future<UserProfile?> _getAccountByPhone(String phone) async {
    for (final key in _box!.keys) {
      if (key == _currentAccountKey) continue;

      final data = _box!.get(key);
      if (data != null) {
        final profile = UserProfile.fromJson(Map<String, dynamic>.from(data));
        if (profile.phoneNumber == phone) {
          return profile;
        }
      }
    }
    return null;
  }

  Future<void> _saveAccount(UserProfile profile) async {
    if (_box == null) await initialize();
    await _box!.put(profile.id, profile.toJson());
  }

  Future<void> _setCurrentAccount(String accountId) async {
    if (_box == null) await initialize();
    await _box!.put(_currentAccountKey, accountId);
  }
}