// frontend/lib/services/cache_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/credit_score.dart';
import '../models/heatmap_data.dart';
import '../models/customer.dart';

class HiveBoxes {
  static const String transactions = 'transactions_cache';
  static const String creditScore = 'credit_score_cache';
  static const String heatmap = 'heatmap_cache';
  static const String customers = 'customers_cache';
  static const String appState = 'app_state';

  const HiveBoxes._();
}

class Cached<T> {
  final T data;
  final DateTime cachedAt;
  const Cached({required this.data, required this.cachedAt});
}

class CacheService {
  Box get _transactionsBox => Hive.box(HiveBoxes.transactions);
  Box get _creditScoreBox => Hive.box(HiveBoxes.creditScore);
  Box get _heatmapBox => Hive.box(HiveBoxes.heatmap);
  Box get _customersBox => Hive.box(HiveBoxes.customers);
  Box get _appStateBox => Hive.box(HiveBoxes.appState);

  static const _maxCachedTransactions = 100;

  // Added initialize method
  Future<void> initialize() async {
    return;
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final sorted = [...transactions]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final trimmed = sorted.take(_maxCachedTransactions).toList();
    await _transactionsBox.put('list', trimmed.map((t) => t.toJson()).toList());
    await _transactionsBox.put('cached_at', DateTime.now().toIso8601String());
  }

  Future<void> addTransaction(Transaction transaction) async {
    final existing = getCachedTransactions().data;
    await saveTransactions([transaction, ...existing]);
  }

  Cached<List<Transaction>> getCachedTransactions() {
    final rawList = _transactionsBox.get('list') as List<dynamic>?;
    final rawCachedAt = _transactionsBox.get('cached_at') as String?;
    final transactions = (rawList ?? [])
        .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return Cached(
      data: transactions,
      cachedAt: rawCachedAt != null ? DateTime.parse(rawCachedAt) : DateTime.now(),
    );
  }

  Future<void> saveCreditScore(CreditScore score) async {
    await _creditScoreBox.put('data', score.toJson());
  }

  Cached<CreditScore>? getCachedCreditScore() {
    final raw = _creditScoreBox.get('data') as Map<dynamic, dynamic>?;
    if (raw == null) return null;
    final score = CreditScore.fromCache(Map<String, dynamic>.from(raw));
    return Cached(data: score, cachedAt: score.fetchedAt);
  }

  Future<void> saveHeatmap(HeatmapData data) async {
    await _heatmapBox.put('data', data.toJson());
    await _heatmapBox.put('cached_at', DateTime.now().toIso8601String());
  }

  Cached<HeatmapData>? getCachedHeatmap() {
    final raw = _heatmapBox.get('data') as Map<dynamic, dynamic>?;
    final rawCachedAt = _heatmapBox.get('cached_at') as String?;
    if (raw == null || rawCachedAt == null) return null;
    return Cached(
      data: HeatmapData.fromJson(Map<String, dynamic>.from(raw)),
      cachedAt: DateTime.parse(rawCachedAt),
    );
  }

  Cached<DailySummary>? getCachedTodaySummary() {
    final cached = getCachedHeatmap();
    if (cached == null) return null;
    final now = DateTime.now();
    for (final day in cached.data.days) {
      if (day.date.year == now.year && day.date.month == now.month && day.date.day == now.day) {
        return Cached(data: day, cachedAt: cached.cachedAt);
      }
    }
    return null;
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    await _customersBox.put('list', customers.map((c) => c.toJson()).toList());
  }

  List<Customer> getCachedCustomers() {
    final rawList = _customersBox.get('list') as List<dynamic>?;
    return (rawList ?? [])
        .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  int getStreak() => (_appStateBox.get('streak_counter') as int?) ?? 0;

  bool hasProVyapariBadge() => getStreak() >= 30;

  Future<int> updateStreakForDay({
    required DateTime day,
    required int transactionCountForDay,
  }) async {
    final qualifies = transactionCountForDay >= 5;
    final lastDateRaw = _appStateBox.get('last_transaction_date') as String?;
    final currentStreak = getStreak();
    final dayOnly = DateTime(day.year, day.month, day.day);

    if (!qualifies) {
      await _appStateBox.put('streak_counter', 0);
      return 0;
    }

    final isConsecutive = lastDateRaw != null &&
        dayOnly.difference(DateTime.parse(lastDateRaw)).inDays == 1;
    final alreadyCountedToday = lastDateRaw != null &&
        DateTime.parse(lastDateRaw).isAtSameMomentAs(dayOnly);

    final newStreak = alreadyCountedToday
        ? currentStreak
        : (isConsecutive ? currentStreak + 1 : 1);

    await _appStateBox.put('streak_counter', newStreak);
    await _appStateBox.put('last_transaction_date', dayOnly.toIso8601String());
    return newStreak;
  }
}