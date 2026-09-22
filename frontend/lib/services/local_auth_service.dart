import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';

/// Handles local account/session management for VyapaarSaathi.
///
/// This service is intentionally offline-first:
/// - Account profiles are stored locally in Hive.
/// - Email login does not require a network request.
/// - Phone OTP generation/verification is local.
/// - The currently selected business account is persisted locally.
///
/// Important:
/// This service manages ACCOUNT PROFILES only.
/// Business data such as transactions, customers and Khata must still be
/// scoped by account ID in their respective persistence layers.
class LocalAuthService {
  static const String _boxName = 'user_accounts';
  static const String _currentAccountKey = 'current_account_id';

  static const Duration _otpValidity = Duration(minutes: 5);
  static const int _maxOtpAttempts = 5;

  Box<dynamic>? _box;

  String? _otp;
  String? _otpPhone;
  DateTime? _otpExpiresAt;
  int _otpAttempts = 0;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the local account database.
  ///
  /// Safe to call multiple times.
  Future<void> initialize() async {
    if (_box?.isOpen == true) {
      return;
    }

    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<dynamic>(_boxName);
      return;
    }

    _box = await Hive.openBox<dynamic>(_boxName);
  }

  // ---------------------------------------------------------------------------
  // Current account
  // ---------------------------------------------------------------------------

  /// Returns the currently selected business account.
  Future<UserProfile?> getCurrentUser() async {
    await initialize();

    final accountId = _box!.get(_currentAccountKey);

    if (accountId == null) {
      return null;
    }

    return _getAccount(accountId.toString());
  }

  /// Returns the ID of the currently selected account.
  ///
  /// Returns `null` when no account is currently selected.
  ///
  /// This is intentionally exposed as a small session-level API so other
  /// persistence services can scope business data to the active account
  /// without accessing this service's private Hive box.
  Future<String?> getCurrentAccountId() async {
    await initialize();

    final value = _box!.get(_currentAccountKey);

    if (value == null) {
      return null;
    }

    final accountId = value.toString().trim();

    return accountId.isEmpty ? null : accountId;
  }

  /// Returns all locally stored business accounts.
  ///
  /// Invalid/corrupt Hive entries are ignored instead of crashing the app.
  Future<List<UserProfile>> getAllAccounts() async {
    await initialize();

    final accounts = <UserProfile>[];

    for (final key in _box!.keys) {
      if (key == _currentAccountKey) {
        continue;
      }

      final account = _getAccount(key.toString());

      if (account != null) {
        accounts.add(account);
      }
    }

    accounts.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return accounts;
  }

  /// Creates a new local business account and makes it active.
  ///
  /// This is the method Settings should use for "Add business account".
  Future<UserProfile> createLocalAccount({
    required String storeName,
    required String ownerName,
    String phoneNumber = '',
    String? email,
    String? address,
    String? city,
    String? state,
  }) async {
    await initialize();

    final normalizedStoreName = storeName.trim();
    final normalizedOwnerName = ownerName.trim();
    final normalizedPhone = _normalizePhone(phoneNumber);

    final normalizedEmail =
        email == null || email.trim().isEmpty ? null : _normalizeEmail(email);

    if (normalizedStoreName.isEmpty) {
      throw ArgumentError('Store name cannot be empty.');
    }

    if (normalizedOwnerName.isEmpty) {
      throw ArgumentError('Owner name cannot be empty.');
    }

    if (normalizedPhone.isNotEmpty && !_isValidPhone(normalizedPhone)) {
      throw ArgumentError('Invalid phone number.');
    }

    if (normalizedEmail != null && !_isValidEmail(normalizedEmail)) {
      throw ArgumentError('Invalid email address.');
    }

    if (normalizedEmail != null) {
      final existing = _findAccountByEmail(normalizedEmail);

      if (existing != null) {
        throw StateError(
          'An account with this email already exists.',
        );
      }
    }

    if (normalizedPhone.isNotEmpty) {
      final existing = _findAccountByPhone(normalizedPhone);

      if (existing != null) {
        throw StateError(
          'An account with this phone number already exists.',
        );
      }
    }

    final profile = UserProfile(
      id: _generateAccountId(),
      storeName: normalizedStoreName,
      ownerName: normalizedOwnerName,
      phoneNumber: normalizedPhone,
      email: normalizedEmail,
      address: _nullableValue(address),
      city: _nullableValue(city),
      state: _nullableValue(state),
      createdAt: DateTime.now(),
      isActive: true,
    );

    await _saveAccount(profile);
    await setCurrentAccount(profile.id);

    return profile;
  }

  // ---------------------------------------------------------------------------
  // Email authentication
  // ---------------------------------------------------------------------------

  /// Performs local email login.
  ///
  /// If the email already belongs to an account, that account is activated.
  /// Otherwise a new local account is created.
  Future<UserProfile?> loginWithEmail(String email) async {
    await initialize();

    final normalizedEmail = _normalizeEmail(email);

    if (!_isValidEmail(normalizedEmail)) {
      return null;
    }

    final existingAccount = _findAccountByEmail(normalizedEmail);

    final profile = existingAccount != null
        ? existingAccount.copyWith(isActive: true)
        : UserProfile(
            id: _generateAccountId(),
            storeName: 'My Store',
            ownerName: 'Owner',
            phoneNumber: '',
            email: normalizedEmail,
            createdAt: DateTime.now(),
            isActive: true,
          );

    await _saveAccount(profile);
    await setCurrentAccount(profile.id);

    return profile;
  }

  // ---------------------------------------------------------------------------
  // Offline OTP
  // ---------------------------------------------------------------------------

  /// Generates a local OTP for a valid Indian mobile number.
  ///
  /// This is an OFFLINE development/local-auth flow.
  /// No SMS is sent by this method.
  ///
  /// The returned OTP should only be exposed by the authentication UI when
  /// your product intentionally uses a local/demo authentication flow.
  Future<String?> requestOfflineOtp(String phoneNumber) async {
    await initialize();

    final normalizedPhone = _normalizePhone(phoneNumber);

    if (!_isValidPhone(normalizedPhone)) {
      return null;
    }

    final random = Random.secure();

    final generatedOtp = (100000 + random.nextInt(900000)).toString();

    _otp = generatedOtp;
    _otpPhone = normalizedPhone;
    _otpExpiresAt = DateTime.now().add(_otpValidity);
    _otpAttempts = 0;

    return generatedOtp;
  }

  /// Verifies a previously generated local OTP.
  Future<UserProfile?> verifyOfflineOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    await initialize();

    final normalizedPhone = _normalizePhone(phoneNumber);
    final enteredOtp = otp.trim();

    if (!_isValidPhone(normalizedPhone)) {
      return null;
    }

    if (enteredOtp.isEmpty) {
      return null;
    }

    if (_otp == null || _otpPhone == null || _otpExpiresAt == null) {
      return null;
    }

    if (_otpPhone != normalizedPhone) {
      return null;
    }

    if (DateTime.now().isAfter(_otpExpiresAt!)) {
      _clearOtp();
      return null;
    }

    if (_otpAttempts >= _maxOtpAttempts) {
      _clearOtp();
      return null;
    }

    _otpAttempts++;

    if (enteredOtp != _otp) {
      if (_otpAttempts >= _maxOtpAttempts) {
        _clearOtp();
      }

      return null;
    }

    final existingAccount = _findAccountByPhone(normalizedPhone);

    final profile = existingAccount != null
        ? existingAccount.copyWith(isActive: true)
        : UserProfile(
            id: _generateAccountId(),
            storeName: 'My Store',
            ownerName: 'Owner',
            phoneNumber: normalizedPhone,
            createdAt: DateTime.now(),
            isActive: true,
          );

    await _saveAccount(profile);
    await setCurrentAccount(profile.id);

    _clearOtp();

    return profile;
  }

  // ---------------------------------------------------------------------------
  // Account creation / switching
  // ---------------------------------------------------------------------------

  /// Sets an existing account as the current account.
  ///
  /// Returns `true` when the account exists and was selected.
  Future<bool> setCurrentAccount(String accountId) async {
    await initialize();

    final normalizedId = accountId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    final account = _getAccount(normalizedId);

    if (account == null) {
      return false;
    }

    final updatedAccount = account.copyWith(
      isActive: true,
    );

    await _saveAccount(updatedAccount);

    // Mark other accounts inactive.
    for (final key in _box!.keys) {
      if (key == _currentAccountKey) {
        continue;
      }

      final other = _getAccount(key.toString());

      if (other == null || other.id == updatedAccount.id) {
        continue;
      }

      if (other.isActive) {
        await _saveAccount(
          other.copyWith(isActive: false),
        );
      }
    }

    await _box!.put(
      _currentAccountKey,
      updatedAccount.id,
    );

    return true;
  }

  /// Updates an existing account profile.
  Future<bool> updateProfile(UserProfile profile) async {
    await initialize();

    final existing = _getAccount(profile.id);

    if (existing == null) {
      return false;
    }

    await _saveAccount(profile);

    return true;
  }

  /// Switches to another locally stored account.
  Future<bool> switchAccount(String accountId) async {
    return setCurrentAccount(accountId);
  }

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  /// Logs out the current account.
  ///
  /// The account profile remains stored locally and can be selected again.
  Future<void> logout() async {
    await initialize();

    final accountId = _box!.get(_currentAccountKey);

    if (accountId != null) {
      final account = _getAccount(accountId.toString());

      if (account != null) {
        await _saveAccount(
          account.copyWith(
            isActive: false,
          ),
        );
      }
    }

    await _box!.delete(_currentAccountKey);

    _clearOtp();
  }

  /// Deletes a local account profile.
  ///
  /// Business data associated with this account is NOT deleted here.
  /// Data isolation/deletion belongs to the individual persistence services.
  Future<bool> deleteAccount(String accountId) async {
    await initialize();

    final normalizedId = accountId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    final exists = _getAccount(normalizedId) != null;

    if (!exists) {
      return false;
    }

    await _box!.delete(normalizedId);

    final currentAccountId = _box!.get(_currentAccountKey)?.toString();

    if (currentAccountId == normalizedId) {
      await _box!.delete(_currentAccountKey);
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Internal account helpers
  // ---------------------------------------------------------------------------

  UserProfile? _getAccount(String accountId) {
    final data = _box!.get(accountId);

    if (data is! Map) {
      return null;
    }

    try {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (_) {
      return null;
    }
  }

  UserProfile? _findAccountByEmail(String email) {
    final normalizedEmail = _normalizeEmail(email);

    for (final key in _box!.keys) {
      if (key == _currentAccountKey) {
        continue;
      }

      final account = _getAccount(key.toString());

      if (account == null || account.email == null) {
        continue;
      }

      if (_normalizeEmail(account.email!) == normalizedEmail) {
        return account;
      }
    }

    return null;
  }

  UserProfile? _findAccountByPhone(String phoneNumber) {
    final normalizedPhone = _normalizePhone(phoneNumber);

    for (final key in _box!.keys) {
      if (key == _currentAccountKey) {
        continue;
      }

      final account = _getAccount(key.toString());

      if (account == null || account.phoneNumber.isEmpty) {
        continue;
      }

      if (_normalizePhone(account.phoneNumber) == normalizedPhone) {
        return account;
      }
    }

    return null;
  }

  Future<void> _saveAccount(UserProfile profile) async {
    await initialize();

    await _box!.put(
      profile.id,
      profile.toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation / normalization
  // ---------------------------------------------------------------------------

  String _generateAccountId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random.secure().nextInt(1000000);

    return 'account_${timestamp}_$random';
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  String _normalizePhone(String phoneNumber) {
    var phone = phoneNumber.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('91') && phone.length == 12) {
      phone = phone.substring(2);
    }

    return phone;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  bool _isValidPhone(String phoneNumber) {
    return RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(phoneNumber);
  }

  String? _nullableValue(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // OTP cleanup
  // ---------------------------------------------------------------------------

  void _clearOtp() {
    _otp = null;
    _otpPhone = null;
    _otpExpiresAt = null;
    _otpAttempts = 0;
  }
}
