// frontend/lib/services/local_api_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/heatmap_data.dart';
import '../models/credit_score.dart';

class LocalApiService {
  final Box<dynamic>? _hiveBox;

  LocalApiService({Box<dynamic>? hiveBox}) : _hiveBox = hiveBox;

  Future<TransactionCaptureResponse> captureTransaction({
    required String imageBase64,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final hash = imageBase64.hashCode;
      final random = Random(hash.abs());

      final amount = (random.nextDouble() * 500 + 50).roundToDouble();
      final confidence = random.nextInt(30) + 70;

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        category: TransactionCategory.values[random.nextInt(TransactionCategory.values.length)],
        timestamp: DateTime.now(),
        confidence: confidence,
        customerName: 'Customer ${random.nextInt(100)}',
        customerId: 'C${random.nextInt(1000).toString().padLeft(3, '0')}',
        isSynced: true,
      );

      await _cacheTransaction(transaction);

      if (confidence >= 80) {
        return ConfirmedCapture(transaction: transaction, confidence: confidence);
      } else {
        return LowConfidenceCapture(transaction: transaction, confidence: confidence);
      }
    } catch (e) {
      debugPrint('[LocalApiService] Capture error: $e');
      throw ApiException('Failed to process image: $e');
    }
  }

  Future<String?> transcribeAudio(String audioBase64) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final hash = audioBase64.hashCode;
      final random = Random(hash.abs());

      final commands = ['home', 'capture', 'bill banao', 'credit score', 'heatmap'];

      return commands[random.nextInt(commands.length)];
    } catch (e) {
      debugPrint('[LocalApiService] Transcribe error: $e');
      return null;
    }
  }

  Future<HeatmapData> getHeatmap({int days = 7}) async {
    try {
      final now = DateTime.now();
      final heatmapDays = <DailySummary>[];

      for (var i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);

        final transactions = await _getTransactionsByDate(dayStart, dayStart.add(const Duration(days: 1)));

        final income = transactions
            .where((t) => t.category == TransactionCategory.sales)
            .fold<double>(0, (sum, t) => sum + t.amount);

        final expense = transactions
            .where((t) => t.category == TransactionCategory.expense)
            .fold<double>(0, (sum, t) => sum + t.amount);

        heatmapDays.add(DailySummary(
          date: dayStart,
          income: income,
          expense: expense,
        ));
      }

      return HeatmapData(days: heatmapDays);
    } catch (e) {
      debugPrint('[LocalApiService] Heatmap error: $e');
      return _generateMockHeatmap(days);
    }
  }

  Future<List<Transaction>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _getTransactionsByDate(startDate, endDate);
    } catch (e) {
      debugPrint('[LocalApiService] Get transactions error: $e');
      return [];
    }
  }

  Future<void> saveTransaction(Transaction transaction) async {
    try {
      await _cacheTransaction(transaction);
    } catch (e) {
      debugPrint('[LocalApiService] Save transaction error: $e');
    }
  }

  Future<CreditScore> getCreditScore() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 90));
      final transactions = await getTransactions(startDate: startDate, endDate: now);

      final totalTransactions = transactions.length;
      final totalVolume = transactions.fold<double>(0, (sum, t) => sum + t.amount);
      final avgDailyTransactions = totalTransactions / 90;

      int score = 300;
      score += (totalTransactions * 2).clamp(0, 200);
      score += ((totalVolume / 100).toInt()).clamp(0, 300);
      score += ((avgDailyTransactions * 10).toInt()).clamp(0, 200);

      score = score.clamp(300, 900);

      return CreditScore(
        score: score,
        breakdown: CreditBreakdown(
          consistency: (avgDailyTransactions * 10).clamp(0, 100).round(),
          diversity: (totalTransactions / 10).clamp(0, 100).round(),
          avgDailyIncome: totalVolume / 90,
        ),
        fetchedAt: DateTime.now(), // ✅ Add this
      );
    } catch (e) {
      debugPrint('[LocalApiService] Credit score error: $e');
      return CreditScore(
        score: 650,
        breakdown: CreditBreakdown(
          consistency: 50,
          diversity: 50,
          avgDailyIncome: 0,
        ),
        fetchedAt: DateTime.now(), // ✅ Add this
      );
    }
  }

  Future<List<Transaction>> _getTransactionsByDate(DateTime startDate, DateTime endDate) async {
    if (_hiveBox == null) {
      return _generateMockTransactions(startDate, endDate);
    }

    try {
      final allTransactions = _hiveBox.values
          .where((t) => t is Transaction)
          .cast<Transaction>()
          .where((t) => t.timestamp.isAfter(startDate) && t.timestamp.isBefore(endDate))
          .toList();

      return allTransactions;
    } catch (e) {
      debugPrint('[LocalApiService] Cache read error: $e');
      return _generateMockTransactions(startDate, endDate);
    }
  }

  Future<void> _cacheTransaction(Transaction transaction) async {
    if (_hiveBox == null) return;

    try {
      await _hiveBox.put(transaction.id, transaction);
    } catch (e) {
      debugPrint('[LocalApiService] Cache write error: $e');
    }
  }

  List<Transaction> _generateMockTransactions(DateTime startDate, DateTime endDate) {
    final random = Random(startDate.hashCode);
    final transactions = <Transaction>[];
    final categories = TransactionCategory.values;

    final days = endDate.difference(startDate).inDays;
    final numTransactions = random.nextInt(5) + 1;

    for (var i = 0; i < numTransactions; i++) {
      final dayOffset = random.nextInt(days);
      final hourOffset = random.nextInt(12) + 8;

      transactions.add(Transaction(
        id: 'mock_${startDate.hashCode}_$i',
        amount: (random.nextDouble() * 300 + 50).roundToDouble(),
        category: categories[random.nextInt(categories.length)],
        timestamp: startDate.add(Duration(days: dayOffset, hours: hourOffset)),
        confidence: random.nextInt(30) + 70,
        customerName: 'Customer $i',
        customerId: 'C${i.toString().padLeft(3, '0')}',
        isSynced: true,
      ));
    }

    return transactions;
  }

  HeatmapData _generateMockHeatmap(int days) {
    final random = Random(days);
    final heatmapDays = <DailySummary>[];
    final now = DateTime.now();

    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final income = (random.nextDouble() * 2000 + 500).roundToDouble();
      final expense = (random.nextDouble() * 1000 + 200).roundToDouble();

      heatmapDays.add(DailySummary(
        date: date,
        income: income,
        expense: expense,
      ));
    }

    return HeatmapData(days: heatmapDays);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}