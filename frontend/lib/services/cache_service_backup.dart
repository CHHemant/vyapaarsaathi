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
/// All local application data is stored through Hive so the application
/// remains usable in offline-first mode.
///
/// Responsibilities:
/// - Transaction caching
/// - Credit score caching
/// - Heatmap caching
/// - Customer caching
/// - Khata / credit-entry persistence
/// - Application state persistence
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
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the cache service.
  ///
  /// Hive boxes are opened by `main.dart` before the application starts.
  /// Therefore this method intentionally does not open boxes again.
  Future<void> initialize() async {
    return;
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  /// Saves transactions to the local cache.
  ///
  /// Transactions are sorted newest-first and limited to the configured
  /// maximum cache size.
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final sorted = [...transactions]..sort(
        (a, b) => b.timestamp.compareTo(a.timestamp),
      );

    final trimmed = sorted.take(_maxCachedTransactions).toList();

    await _transactionsBox.put(
      'list',
      trimmed.map((transaction) => transaction.toJson()).toList(),
    );

    await _transactionsBox.put(
      'cached_at',
      DateTime.now().toIso8601String(),
    );
  }

  /// Adds a transaction to the local cache.
  Future<void> addTransaction(Transaction transaction) async {
    final existing = getCachedTransactions().data;

    await saveTransactions([
      transaction,
      ...existing.where(
        (item) => item.id != transaction.id,
      ),
    ]);
  }

  /// Returns cached transactions.
  Cached<List<Transaction>> getCachedTransactions() {
    final rawList = _transactionsBox.get('list') as List<dynamic>?;
    final rawCachedAt = _transactionsBox.get('cached_at') as String?;

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

  /// Saves the latest credit score locally.
  Future<void> saveCreditScore(CreditScore score) async {
    await _creditScoreBox.put(
      'data',
      score.toJson(),
    );
  }

  /// Returns the locally cached credit score, if available.
  Cached<CreditScore>? getCachedCreditScore() {
    final raw = _creditScoreBox.get('data') as Map<dynamic, dynamic>?;

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

  /// Saves heatmap data locally.
  Future<void> saveHeatmap(HeatmapData data) async {
    await _heatmapBox.put(
      'data',
      data.toJson(),
    );

    await _heatmapBox.put(
      'cached_at',
      DateTime.now().toIso8601String(),
    );
  }

  /// Returns cached heatmap data, if available.
  Cached<HeatmapData>? getCachedHeatmap() {
    final raw = _heatmapBox.get('data') as Map<dynamic, dynamic>?;
    final rawCachedAt = _heatmapBox.get('cached_at') as String?;

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

  /// Returns today's cached heatmap summary.
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

  /// Saves customers to the local cache.
  Future<void> saveCustomers(List<Customer> customers) async {
    await _customersBox.put(
      'list',
      customers.map((customer) => customer.toJson()).toList(),
    );
  }

  /// Returns cached customers.
  List<Customer> getCachedCustomers() {
    final rawList = _customersBox.get('list') as List<dynamic>?;

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

  /// Saves all Khata entries locally.
  ///
  /// Entries are stored newest-first using their transaction date.
  Future<void> saveCreditEntries(
    List<CreditEntry> entries,
  ) async {
    final sorted = [...entries]..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    await _khataEntriesBox.put(
      'list',
      sorted.map((entry) => entry.toJson()).toList(),
    );

    await _khataEntriesBox.put(
      'cached_at',
      DateTime.now().toIso8601String(),
    );
  }

  /// Returns all locally stored Khata entries.
  List<CreditEntry> getCreditEntries() {
    final rawList = _khataEntriesBox.get('list') as List<dynamic>?;

    return (rawList ?? [])
        .map(
          (item) => CreditEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  /// Returns the cached Khata entries together with their cache timestamp.
  Cached<List<CreditEntry>> getCachedCreditEntries() {
    final rawList = _khataEntriesBox.get('list') as List<dynamic>?;
    final rawCachedAt = _khataEntriesBox.get('cached_at') as String?;

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

  /// Adds a new Khata entry.
  ///
  /// If an entry with the same ID already exists, it is replaced instead
  /// of creating a duplicate.
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

  /// Updates an existing Khata entry.
  ///
  /// If the entry does not exist, it will be added.
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

  /// Deletes a Khata entry by ID.
  Future<void> deleteCreditEntry(String entryId) async {
    final existing = getCreditEntries();

    final updated = existing
        .where(
          (entry) => entry.id != entryId,
        )
        .toList();

    await saveCreditEntries(updated);
  }

  /// Returns all Khata entries belonging to a specific customer.
  List<CreditEntry> getCreditEntriesForCustomer(
    String customerId,
  ) {
    return getCreditEntries()
        .where(
          (entry) => entry.customerId == customerId,
        )
        .toList();
  }

  /// Calculates the outstanding balance for a customer.
  ///
  /// `given` means money/credit given to the customer.
  /// `taken` means money/credit taken from the customer.
  ///
  /// Positive balance = customer owes the business.
  /// Negative balance = business owes the customer.
  double getCustomerOutstandingBalance(
    String customerId,
  ) {
    final entries = getCreditEntriesForCustomer(customerId);

    double balance = 0;

    for (final entry in entries) {
      // Include both unpaid and partially paid entries, but ignore
      // entries whose remaining balance has reached zero.
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

  /// Returns the current transaction streak.
  int getStreak() {
    return (_appStateBox.get('streak_counter') as int?) ?? 0;
  }

  /// Returns whether the user has earned the Pro Vyapari badge.
  bool hasProVyapariBadge() {
    return getStreak() >= 30;
  }

  /// Updates the daily transaction streak.
  Future<int> updateStreakForDay({
    required DateTime day,
    required int transactionCountForDay,
  }) async {
    final qualifies = transactionCountForDay >= 5;

    final lastDateRaw = _appStateBox.get('last_transaction_date') as String?;

    final currentStreak = getStreak();

    final dayOnly = DateTime(
      day.year,
      day.month,
      day.day,
    );

    if (!qualifies) {
      await _appStateBox.put(
        'streak_counter',
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
      'streak_counter',
      newStreak,
    );

    await _appStateBox.put(
      'last_transaction_date',
      dayOnly.toIso8601String(),
    );

    return newStreak;
  }
}
