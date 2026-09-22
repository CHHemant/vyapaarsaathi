// frontend/lib/services/local_api_service.dart

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/credit_score.dart';
import '../models/heatmap_data.dart';
import '../models/transaction.dart';

/// Local/backend bridge used by the Flutter application.
///
/// The service keeps the existing offline-first behavior while using the
/// Office Kit backend for speech transcription and the tax assistant.
///
/// Backend:
///   http://10.215.72.35:8000/api/v1
class LocalApiService {
  static const String _baseUrl = 'http://10.215.72.35:8000/api/v1';

  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _sendTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(seconds: 20);

  final Box<dynamic>? _hiveBox;
  late final Dio _dio;

  LocalApiService({Box<dynamic>? hiveBox, Dio? dio}) : _hiveBox = hiveBox {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: _connectTimeout,
            sendTimeout: _sendTimeout,
            receiveTimeout: _receiveTimeout,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );
  }

  /// Captures a transaction from an image.
  ///
  /// This preserves the existing local/demo fallback behavior used by the
  /// current application. It does not pretend to perform OCR locally.
  Future<TransactionCaptureResponse> captureTransaction({
    required String imageBase64,
  }) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final hash = imageBase64.hashCode;
      final random = Random(hash.abs());

      final amount = (random.nextDouble() * 500 + 50).roundToDouble();
      final confidence = random.nextInt(30) + 70;

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        category: TransactionCategory
            .values[random.nextInt(TransactionCategory.values.length)],
        timestamp: DateTime.now(),
        confidence: confidence,
        customerName: 'Customer ${random.nextInt(100)}',
        customerId: 'C${random.nextInt(1000).toString().padLeft(3, '0')}',
        isSynced: true,
      );

      await _cacheTransaction(transaction);

      if (confidence >= 80) {
        return ConfirmedCapture(
          transaction: transaction,
          confidence: confidence,
        );
      }

      return LowConfidenceCapture(
        transaction: transaction,
        confidence: confidence,
      );
    } catch (error, stackTrace) {
      debugPrint('[LocalApiService] Capture error: $error');
      debugPrintStack(stackTrace: stackTrace);

      throw ApiException('Failed to process image: $error');
    }
  }

  /// Sends recorded voice audio to the backend and returns its transcript.
  ///
  /// The backend contract used by the application is:
  ///
  /// POST /transactions/capture
  /// {
  ///   "audio_base64": "...",
  ///   "audio_only": true
  /// }
  ///
  /// The response is expected to contain either `transcript` or `text`.
  Future<String?> transcribeAudio(String audioBase64) async {
    if (audioBase64.trim().isEmpty) {
      return null;
    }

    try {
      final response = await _dio.post(
        '/transactions/capture',
        data: <String, dynamic>{
          'audio_base64': audioBase64,
          'audio_only': true,
        },
      );

      final data = response.data;

      if (data is! Map) {
        debugPrint(
          '[LocalApiService] Invalid transcription response type: '
          '${data.runtimeType}',
        );
        return null;
      }

      final transcript = data['transcript'] ?? data['text'];

      if (transcript is! String || transcript.trim().isEmpty) {
        debugPrint(
          '[LocalApiService] Backend returned no transcript.',
        );
        return null;
      }

      return transcript.trim();
    } on DioException catch (error, stackTrace) {
      debugPrint(
        '[LocalApiService] Transcription request failed: '
        '${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } catch (error, stackTrace) {
      debugPrint('[LocalApiService] Transcription error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Sends a natural-language question to the tax assistant backend.
  Future<String> askTaxAssistant(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return 'Please ask a question.';
    }

    try {
      final response = await _dio.post(
        '/tax-assistant/query',
        data: <String, dynamic>{
          'query': normalizedQuery,
        },
      );

      final data = response.data;

      if (data is Map && data['answer'] is String) {
        final answer = (data['answer'] as String).trim();

        if (answer.isNotEmpty) {
          return answer;
        }
      }

      debugPrint(
        '[LocalApiService] Tax assistant returned an invalid response.',
      );

      return 'I could not understand the assistant response.';
    } on DioException catch (error, stackTrace) {
      debugPrint(
        '[LocalApiService] Tax assistant request failed: '
        '${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);

      return 'I am working offline right now. '
          'Please connect to the Office Kit bridge and try again.';
    } catch (error, stackTrace) {
      debugPrint('[LocalApiService] Tax assistant error: $error');
      debugPrintStack(stackTrace: stackTrace);

      return 'I could not process that request right now.';
    }
  }

  /// Returns heatmap data from locally stored transactions.
  Future<HeatmapData> getHeatmap({int days = 7}) async {
    final safeDays = days.clamp(1, 365);

    try {
      final now = DateTime.now();
      final heatmapDays = <DailySummary>[];

      for (var i = 0; i < safeDays; i++) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final transactions = await _getTransactionsByDate(
          dayStart,
          dayEnd,
        );

        final income = transactions
            .where((t) => t.category == TransactionCategory.sales)
            .fold<double>(
              0,
              (sum, transaction) => sum + transaction.amount,
            );

        final expense = transactions
            .where((t) => t.category == TransactionCategory.expense)
            .fold<double>(
              0,
              (sum, transaction) => sum + transaction.amount,
            );

        heatmapDays.add(
          DailySummary(
            date: dayStart,
            income: income,
            expense: expense,
          ),
        );
      }

      return HeatmapData(days: heatmapDays);
    } catch (error, stackTrace) {
      debugPrint('[LocalApiService] Heatmap error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return _generateMockHeatmap(safeDays);
    }
  }

  /// Returns locally cached transactions within the supplied date range.
  Future<List<Transaction>> getTransactions({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _getTransactionsByDate(startDate, endDate);
    } catch (error, stackTrace) {
      debugPrint('[LocalApiService] Get transactions error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <Transaction>[];
    }
  }

  /// Saves a transaction to the local cache.
  Future<void> saveTransaction(Transaction transaction) async {
    await _cacheTransaction(transaction);
  }

  /// Calculates a local credit score from cached transactions.
  Future<CreditScore> getCreditScore() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 90));

      final transactions = await getTransactions(
        startDate: startDate,
        endDate: now,
      );

      final totalTransactions = transactions.length;
      final totalVolume = transactions.fold<double>(
        0,
        (sum, transaction) => sum + transaction.amount,
      );

      final avgDailyTransactions = totalTransactions / 90;

      var score = 300;
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
        fetchedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      debugPrint('[LocalApiService] Credit score error: $error');
      debugPrintStack(stackTrace: stackTrace);

      return CreditScore(
        score: 650,
        breakdown: CreditBreakdown(
          consistency: 50,
          diversity: 50,
          avgDailyIncome: 0,
        ),
        fetchedAt: DateTime.now(),
      );
    }
  }

  Future<List<Transaction>> _getTransactionsByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_hiveBox == null) {
      return _generateMockTransactions(startDate, endDate);
    }

    try {
      final allTransactions = _hiveBox.values
          .whereType<Transaction>()
          .where(
            (transaction) =>
                !transaction.timestamp.isBefore(startDate) &&
                transaction.timestamp.isBefore(endDate),
          )
          .toList();

      allTransactions.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp),
      );

      return allTransactions;
    } catch (error, stackTrace) {
      debugPrint('[LocalApiService] Cache read error: $error');
      debugPrintStack(stackTrace: stackTrace);

      return _generateMockTransactions(startDate, endDate);
    }
  }

  Future<void> _cacheTransaction(Transaction transaction) async {
    if (_hiveBox == null) {
      return;
    }

    try {
      await _hiveBox.put(transaction.id, transaction);
    } catch (error, stackTrace) {
      debugPrint('[LocalApiService] Cache write error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<Transaction> _generateMockTransactions(
    DateTime startDate,
    DateTime endDate,
  ) {
    final durationDays = endDate.difference(startDate).inDays;

    if (durationDays <= 0) {
      return <Transaction>[];
    }

    final random = Random(startDate.hashCode);
    final transactions = <Transaction>[];
    final categories = TransactionCategory.values;
    final numTransactions = random.nextInt(5) + 1;

    for (var i = 0; i < numTransactions; i++) {
      final dayOffset = random.nextInt(durationDays);
      final hourOffset = random.nextInt(12) + 8;

      transactions.add(
        Transaction(
          id: 'mock_${startDate.hashCode}_$i',
          amount: (random.nextDouble() * 300 + 50).roundToDouble(),
          category: categories[random.nextInt(categories.length)],
          timestamp: startDate.add(
            Duration(
              days: dayOffset,
              hours: hourOffset,
            ),
          ),
          confidence: random.nextInt(30) + 70,
          customerName: 'Customer $i',
          customerId: 'C${i.toString().padLeft(3, '0')}',
          isSynced: true,
        ),
      );
    }

    return transactions;
  }

  HeatmapData _generateMockHeatmap(int days) {
    final safeDays = days.clamp(1, 365);
    final random = Random(safeDays);
    final heatmapDays = <DailySummary>[];
    final now = DateTime.now();

    for (var i = 0; i < safeDays; i++) {
      final date = now.subtract(Duration(days: i));

      heatmapDays.add(
        DailySummary(
          date: DateTime(date.year, date.month, date.day),
          income: (random.nextDouble() * 2000 + 500).roundToDouble(),
          expense: (random.nextDouble() * 1000 + 200).roundToDouble(),
        ),
      );
    }

    return HeatmapData(days: heatmapDays);
  }
}

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
