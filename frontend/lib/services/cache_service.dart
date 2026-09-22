// frontend/lib/services/cache_service.dart

import 'package:hive_flutter/hive_flutter.dart';

import '../models/credit_entry.dart';
import '../models/credit_score.dart';
import '../models/customer.dart';
import '../models/heatmap_data.dart';
import '../models/transaction.dart';

/// Centralized Hive box names used by the application.
class HiveBoxes {
  static const String transactions = 'transactions_cache';
  static const String creditScore = 'credit_score_cache';
  static const String heatmap = 'heatmap_cache';
  static const String customers = 'customers_cache';
  static const String khataEntries = 'khata_entries';
  static const String appState = 'app_state';

  /// Stores local account profiles and the selected account.
  static const String userAccounts = 'user_accounts';

  const HiveBoxes._();
}

/// Wrapper containing cached data and the time it was cached.
class Cached<T> {
  final T data;
  final DateTime cachedAt;

  const Cached({
    required this.data,
    required this.cachedAt,
  });
}

/// Local persistence service for the VyapaarSaathi application.
///
/// Business data is scoped to the currently selected local account.
///
/// Account-scoped data:
/// - Transactions
/// - Credit score
/// - Heatmap
/// - Customers
/// - Khata / credit entries
/// - Transaction streak
///
/// Device-scoped data such as selected language and theme remains in the
/// application-state box under its original keys.
class CacheService {
  // ---------------------------------------------------------------------------
  // Hive boxes
  // ---------------------------------------------------------------------------

  Box get _transactionsBox => Hive.box(HiveBoxes.transactions);

  Box get _creditScoreBox => Hive.box(HiveBoxes.creditScore);

  Box get _heatmapBox => Hive.box(HiveBoxes.heatmap);

  Box get _customersBox => Hive.box(HiveBoxes.customers);

  Box get _khataEntriesBox => Hive.box(HiveBoxes.khataEntries);

  Box get _appStateBox => Hive.box(HiveBoxes.appState);

  static const int _maxCachedTransactions = 100;

  // ---------------------------------------------------------------------------
  // Account scoping
  // ---------------------------------------------------------------------------

  /// Returns the currently selected account ID.
  ///
  /// LocalAuthService persists the selected account under the same Hive box.
  /// This getter is synchronous because all CacheService read APIs are
  /// synchronous and the user_accounts box is opened during application
  /// startup.
  String? get _currentAccountId {
    if (!Hive.isBoxOpen(HiveBoxes.userAccounts)) {
      return null;
    }

    final value = Hive.box(HiveBoxes.userAccounts).get('current_account_id');

    if (value == null) {
      return null;
    }

    final accountId = value.toString().trim();

    return accountId.isEmpty ? null : accountId;
  }

  /// Prefix used for all account-specific business-data keys.
  String get _accountPrefix {
    final accountId = _currentAccountId;

    if (accountId == null) {
      return 'account_default';
    }

    return 'account_${_safeKey(accountId)}';
  }

  String _safeKey(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _key(String name) => '$_accountPrefix:$name';

  /// Migrates the old global cache into the currently selected account once.
  ///
  /// This protects existing users from losing the business data that was
  /// stored before account isolation was introduced.
  Future<void> _migrateLegacyDataIfNeeded() async {
    final accountId = _currentAccountId;

    if (accountId == null) {
      return;
    }

    await _migrateBox(
      _transactionsBox,
      legacyKeys: const ['list', 'cached_at'],
      scopedKeys: [_key('transactions_list'), _key('transactions_cached_at')],
    );

    await _migrateBox(
      _creditScoreBox,
      legacyKeys: const ['data'],
      scopedKeys: [_key('credit_score_data')],
    );

    await _migrateBox(
      _heatmapBox,
      legacyKeys: const ['data', 'cached_at'],
      scopedKeys: [_key('heatmap_data'), _key('heatmap_cached_at')],
    );

    await _migrateBox(
      _customersBox,
      legacyKeys: const ['list'],
      scopedKeys: [_key('customers_list')],
    );

    await _migrateBox(
      _khataEntriesBox,
      legacyKeys: const ['list', 'cached_at'],
      scopedKeys: [_key('khata_list'), _key('khata_cached_at')],
    );
  }

  Future<void> _migrateBox(
    Box box, {
    required List<String> legacyKeys,
    required List<String> scopedKeys,
  }) async {
    // Migration is only performed when the first scoped key is absent.
    if (box.containsKey(scopedKeys.first)) {
      return;
    }

    var foundLegacyData = false;

    for (var i = 0; i < legacyKeys.length; i++) {
      final value = box.get(legacyKeys[i]);

      if (value != null) {
        foundLegacyData = true;
        await box.put(scopedKeys[i], value);
      }
    }

    // Mark that this account has completed the one-time migration even when
    // the legacy cache was empty. This prevents future account creation from
    // accidentally receiving data written for another account.
    await box.put(
      _key('legacy_migration_complete'),
      foundLegacyData ? true : false,
    );
  }

  /// Deletes all business data belonging to a specific local account.
  ///
  /// This is intentionally separate from logout. Logging out must never
  /// delete the account's business records.
  Future<void> deleteAccountData(String accountId) async {
    final prefix = 'account_${_safeKey(accountId)}';

    final boxes = <Box>[
      _transactionsBox,
      _creditScoreBox,
      _heatmapBox,
      _customersBox,
      _khataEntriesBox,
    ];

    for (final box in boxes) {
      final keys = box.keys
          .where(
            (key) =>
                key.toString().startsWith('$prefix:') ||
                key.toString() == prefix,
          )
          .toList();

      if (keys.isNotEmpty) {
        await box.deleteAll(keys);
      }
    }

    final appStateKeys = _appStateBox.keys
        .where(
          (key) => key.toString().startsWith('$prefix:'),
        )
        .toList();

    if (appStateKeys.isNotEmpty) {
      await _appStateBox.deleteAll(appStateKeys);
    }
  }

  /// Initializes the cache service.
  ///
  /// Hive boxes are opened by `main.dart` before the application starts.
  Future<void> initialize() async {
    await _migrateLegacyDataIfNeeded();
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  Future<void> saveTransactions(List<Transaction> transactions) async {
    await _migrateLegacyDataIfNeeded();

    final sorted = [...transactions]..sort(
        (a, b) => b.timestamp.compareTo(a.timestamp),
      );

    final trimmed = sorted.take(_maxCachedTransactions).toList();

    await _transactionsBox.put(
      _key('transactions_list'),
      trimmed.map((transaction) => transaction.toJson()).toList(),
    );

    await _transactionsBox.put(
      _key('transactions_cached_at'),
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> addTransaction(Transaction transaction) async {
    final existing = getCachedTransactions().data;

    await saveTransactions([
      transaction,
      ...existing.where(
        (item) => item.id != transaction.id,
      ),
    ]);
  }

  Cached<List<Transaction>> getCachedTransactions() {
    final rawList =
        _transactionsBox.get(_key('transactions_list')) as List<dynamic>?;
    final rawCachedAt =
        _transactionsBox.get(_key('transactions_cached_at')) as String?;

    final transactions = (rawList ?? [])
        .map(
          (item) => Transaction.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return Cached<List<Transaction>>(
      data: transactions,
      cachedAt:
          rawCachedAt != null ? DateTime.parse(rawCachedAt) : DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Credit Score
  // ---------------------------------------------------------------------------

  Future<void> saveCreditScore(CreditScore score) async {
    await _migrateLegacyDataIfNeeded();

    await _creditScoreBox.put(
      _key('credit_score_data'),
      score.toJson(),
    );
  }

  Cached<CreditScore>? getCachedCreditScore() {
    final raw = _creditScoreBox.get(_key('credit_score_data'))
        as Map<dynamic, dynamic>?;

    if (raw == null) {
      return null;
    }

    final score = CreditScore.fromCache(
      Map<String, dynamic>.from(raw),
    );

    return Cached<CreditScore>(
      data: score,
      cachedAt: score.fetchedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Heatmap
  // ---------------------------------------------------------------------------

  Future<void> saveHeatmap(HeatmapData data) async {
    await _migrateLegacyDataIfNeeded();

    await _heatmapBox.put(
      _key('heatmap_data'),
      data.toJson(),
    );

    await _heatmapBox.put(
      _key('heatmap_cached_at'),
      DateTime.now().toIso8601String(),
    );
  }

  Cached<HeatmapData>? getCachedHeatmap() {
    final raw = _heatmapBox.get(_key('heatmap_data')) as Map<dynamic, dynamic>?;
    final rawCachedAt = _heatmapBox.get(_key('heatmap_cached_at')) as String?;

    if (raw == null || rawCachedAt == null) {
      return null;
    }

    return Cached<HeatmapData>(
      data: HeatmapData.fromJson(
        Map<String, dynamic>.from(raw),
      ),
      cachedAt: DateTime.parse(rawCachedAt),
    );
  }

  Cached<DailySummary>? getCachedTodaySummary() {
    final cached = getCachedHeatmap();

    if (cached == null) {
      return null;
    }

    final now = DateTime.now();

    for (final day in cached.data.days) {
      if (day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day) {
        return Cached<DailySummary>(
          data: day,
          cachedAt: cached.cachedAt,
        );
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Customers
  // ---------------------------------------------------------------------------

  Future<void> saveCustomers(List<Customer> customers) async {
    await _migrateLegacyDataIfNeeded();

    await _customersBox.put(
      _key('customers_list'),
      customers.map((customer) => customer.toJson()).toList(),
    );
  }

  List<Customer> getCachedCustomers() {
    final rawList = _customersBox.get(_key('customers_list')) as List<dynamic>?;

    return (rawList ?? [])
        .map(
          (item) => Customer.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Khata / Credit Entries
  // ---------------------------------------------------------------------------

  Future<void> saveCreditEntries(
    List<CreditEntry> entries,
  ) async {
    await _migrateLegacyDataIfNeeded();

    final sorted = [...entries]..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    await _khataEntriesBox.put(
      _key('khata_list'),
      sorted.map((entry) => entry.toJson()).toList(),
    );

    await _khataEntriesBox.put(
      _key('khata_cached_at'),
      DateTime.now().toIso8601String(),
    );
  }

  List<CreditEntry> getCreditEntries() {
    final rawList = _khataEntriesBox.get(_key('khata_list')) as List<dynamic>?;

    return (rawList ?? [])
        .map(
          (item) => CreditEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Cached<List<CreditEntry>> getCachedCreditEntries() {
    final rawList = _khataEntriesBox.get(_key('khata_list')) as List<dynamic>?;
    final rawCachedAt =
        _khataEntriesBox.get(_key('khata_cached_at')) as String?;

    final entries = (rawList ?? [])
        .map(
          (item) => CreditEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return Cached<List<CreditEntry>>(
      data: entries,
      cachedAt:
          rawCachedAt != null ? DateTime.parse(rawCachedAt) : DateTime.now(),
    );
  }

  Future<void> addCreditEntry(CreditEntry entry) async {
    final existing = getCreditEntries();

    final updated = [
      entry,
      ...existing.where(
        (item) => item.id != entry.id,
      ),
    ];

    await saveCreditEntries(updated);
  }

  Future<void> updateCreditEntry(CreditEntry entry) async {
    final existing = getCreditEntries();

    final index = existing.indexWhere(
      (item) => item.id == entry.id,
    );

    if (index == -1) {
      await addCreditEntry(entry);
      return;
    }

    final updated = [...existing];
    updated[index] = entry;

    await saveCreditEntries(updated);
  }

  Future<void> deleteCreditEntry(String entryId) async {
    final existing = getCreditEntries();

    final updated = existing
        .where(
          (entry) => entry.id != entryId,
        )
        .toList();

    await saveCreditEntries(updated);
  }

  List<CreditEntry> getCreditEntriesForCustomer(
    String customerId,
  ) {
    return getCreditEntries()
        .where(
          (entry) => entry.customerId == customerId,
        )
        .toList();
  }

  double getCustomerOutstandingBalance(
    String customerId,
  ) {
    final entries = getCreditEntriesForCustomer(customerId);

    double balance = 0;

    for (final entry in entries) {
      if (!entry.hasOutstanding) {
        continue;
      }

      final remaining = entry.remainingAmount;

      if (entry.type == 'given') {
        balance += remaining;
      } else if (entry.type == 'taken') {
        balance -= remaining;
      }
    }

    return balance;
  }

  // ---------------------------------------------------------------------------
  // Application State
  // ---------------------------------------------------------------------------

  String get _streakKey => _key('streak_counter');

  String get _lastTransactionDateKey => _key('last_transaction_date');

  int getStreak() {
    return (_appStateBox.get(_streakKey) as int?) ?? 0;
  }

  bool hasProVyapariBadge() {
    return getStreak() >= 30;
  }

  Future<int> updateStreakForDay({
    required DateTime day,
    required int transactionCountForDay,
  }) async {
    final qualifies = transactionCountForDay >= 5;

    final lastDateRaw = _appStateBox.get(_lastTransactionDateKey) as String?;

    final currentStreak = getStreak();

    final dayOnly = DateTime(
      day.year,
      day.month,
      day.day,
    );

    if (!qualifies) {
      await _appStateBox.put(
        _streakKey,
        0,
      );

      return 0;
    }

    final isConsecutive = lastDateRaw != null &&
        dayOnly
                .difference(
                  DateTime.parse(lastDateRaw),
                )
                .inDays ==
            1;

    final alreadyCountedToday = lastDateRaw != null &&
        DateTime.parse(lastDateRaw).isAtSameMomentAs(dayOnly);

    final newStreak = alreadyCountedToday
        ? currentStreak
        : (isConsecutive ? currentStreak + 1 : 1);

    await _appStateBox.put(
      _streakKey,
      newStreak,
    );

    await _appStateBox.put(
      _lastTransactionDateKey,
      dayOnly.toIso8601String(),
    );

    return newStreak;
  }
}
