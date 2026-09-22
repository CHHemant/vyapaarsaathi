import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction.dart';
import '../core_providers.dart';

final transactionProvider = FutureProvider<List<Transaction>>((ref) async {
  final cache = ref.watch(cacheServiceProvider);
  return cache.getCachedTransactions().data;
});

final todayTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final transactions = await ref.watch(transactionProvider.future);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrow = todayStart.add(const Duration(days: 1));

  return transactions.where((transaction) {
    return !transaction.timestamp.isBefore(todayStart) &&
        transaction.timestamp.isBefore(tomorrow);
  }).toList();
});

final weeklyTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final transactions = await ref.watch(transactionProvider.future);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(const Duration(days: 6));
  final tomorrow = todayStart.add(const Duration(days: 1));

  return transactions.where((transaction) {
    return !transaction.timestamp.isBefore(weekStart) &&
        transaction.timestamp.isBefore(tomorrow);
  }).toList();
});

final todaySalesProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(todayTransactionsProvider).whenData(
        (transactions) => transactions
            .where(
              (transaction) =>
                  transaction.category == TransactionCategory.sales,
            )
            .fold<double>(
              0,
              (total, transaction) => total + transaction.amount,
            ),
      );
});

final todayExpensesProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(todayTransactionsProvider).whenData(
        (transactions) => transactions
            .where(
              (transaction) =>
                  transaction.category == TransactionCategory.expense,
            )
            .fold<double>(
              0,
              (total, transaction) => total + transaction.amount,
            ),
      );
});

final todayTransactionCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(todayTransactionsProvider).whenData(
        (transactions) => transactions.length,
      );
});

final weeklySalesProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(weeklyTransactionsProvider).whenData(
        (transactions) => transactions
            .where(
              (transaction) =>
                  transaction.category == TransactionCategory.sales,
            )
            .fold<double>(
              0,
              (total, transaction) => total + transaction.amount,
            ),
      );
});
