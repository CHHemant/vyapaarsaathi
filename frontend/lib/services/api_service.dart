import 'package:flutter/foundation.dart';
// frontend/lib/services/api_service.dart
//
// Single Dio client for talking to the on-device FastAPI backend
// (http://10.215.72.35:8000/api/v1 — reached over the Office Kit bridge,
// not the public internet). Owns: base config, timeout handling,
// exponential-backoff retry for transient failures, debug-only request
// logging, and one typed method per endpoint.
//
// This file does NOT touch Hive. Cache fallback is the caller's job
// (see providers built on top of ApiService + CacheService) — keeping
// network and cache concerns separate makes both easier to test.


import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/transaction.dart';
import '../models/credit_score.dart';
import '../models/invoice.dart';
import '../models/heatmap_data.dart';
import '../models/customer.dart';


/// Sealed error type so every call site is forced to handle each failure
/// mode explicitly (e.g. showing the cached-data badge only on
/// [ApiOfflineException] or [ApiTimeoutException], not on a genuine
/// [ApiServerException]).
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);


  @override
  String toString() => message;
}


/// Connection/send/receive timeout — surfaced as "Network slow, retry?"
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException() : super('Network slow, retry?');
}


/// No route to the backend at all (device not on the Office Kit bridge,
/// backend process not running) — surfaced as the "Working offline" badge.
class ApiOfflineException extends ApiException {
  const ApiOfflineException() : super('Working offline');
}


/// Backend responded but with a 4xx/5xx — surfaced as "Backend error,
/// please restart app" per the spec's error-handling requirement.
class ApiServerException extends ApiException {
  final int statusCode;
  const ApiServerException(this.statusCode) : super('Backend error, please restart app');
}


/// Anything that doesn't fit the three cases above (malformed response
/// body, cancellation, etc.) — kept distinct so it's never silently
/// mapped into "offline" or "timeout" and mishandled by the UI.
class ApiUnknownException extends ApiException {
  const ApiUnknownException(super.message);
}


class ApiService {
  static const _baseUrl = 'http://10.215.72.35:8000/api/v1';  // ← CHANGED FROM localhost
  static const _timeout = Duration(seconds: 5);
  static const _maxRetries = 3;
  static const _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];


  final Dio _dio;


  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
              sendTimeout: _timeout,
            )) {
    // Retry must run before logging in the interceptor chain so retried
    // attempts are logged individually (useful when diagnosing flaky
    // venue wifi during the demo).
    _dio.interceptors.add(_RetryInterceptor(_dio, _maxRetries, _retryDelays));


    // Debug-only request/response/error logging. Never attached in
    // release builds — request bodies can contain base64 image/audio
    // payloads that are noisy (and pointless) to log in production.
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // base64 payloads are huge; log headers only
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[ApiService] $obj'),
      ));
    }
  }


  /// Converts a raw DioException into our sealed [ApiException] hierarchy.
  /// Every public method below funnels its errors through this so callers
  /// never have to inspect DioExceptionType themselves.
  ApiException _mapError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const ApiTimeoutException(),
      DioExceptionType.connectionError => const ApiOfflineException(),
      DioExceptionType.badResponse => ApiServerException(e.response?.statusCode ?? 500),
      _ => ApiUnknownException(e.message ?? 'Unknown network error'),
    };
  }


  /// POST /transactions/capture
  /// [imageBase64] is required for a normal capture; [audioBase64] is
  /// present for voice-tagged captures ("500 rupees, groceries") and for
  /// the wake-word command path in voice_service.dart, which sends
  /// audio_only=true with no image at all.
  Future<TransactionCaptureResponse> captureTransaction({
    String? imageBase64,
    String? audioBase64,
    bool audioOnly = false,
  }) async {
    try {
      final response = await _dio.post('/transactions/capture', data: {
        if (imageBase64 != null) 'image_base64': imageBase64,
        if (audioBase64 != null) 'audio_base64': audioBase64,
        'audio_only': audioOnly,
      });
      return TransactionCaptureResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }


  /// POST /transactions/capture with audio_only=true, returning the RAW
  /// response body instead of a parsed [TransactionCaptureResponse].
  ///
  /// ASSUMPTION FLAGGED FOR BACKEND CONFIRMATION: the documented 6-endpoint
  /// contract doesn't specify what an audio_only capture returns when the
  /// audio is a spoken navigation command ("Home le raa") rather than a
  /// transaction amount. This method assumes the backend includes a
  /// `transcript` (or `text`) string field in that case, and returns it
  /// as-is without forcing it through Transaction.fromJson (which would
  /// throw on a response with no amount/category). voice_service.dart
  /// treats a missing transcript as "command not understood" rather than
  /// crashing — but please confirm the actual field name with whoever
  /// owns the backend before relying on this for the demo.
  Future<String?> transcribeAudio(String audioBase64) async {
    try {
      final response = await _dio.post('/transactions/capture', data: {
        'audio_base64': audioBase64,
        'audio_only': true,
      });
      final data = response.data as Map<String, dynamic>;
      return (data['transcript'] ?? data['text']) as String?;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }


  /// GET /credit-score?days=30
  Future<CreditScore> getCreditScore({int days = 30}) async {
    try {
      final response = await _dio.get('/credit-score', queryParameters: {'days': days});
      return CreditScore.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }


  /// POST /gst/invoice
  /// Sends the composed invoice; backend renders the PDF and returns its
  /// path (used to preview in-app and then push via Office Kit transfer).
  Future<Invoice> generateInvoice({
    String? customerPhone,
    required List<InvoiceItem> items,
  }) async {
    try {
      final response = await _dio.post('/gst/invoice', data: {
        if (customerPhone != null) 'customer_phone': customerPhone,
        'items': items.map((i) => i.toJson()).toList(),
      });
      return Invoice.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }


  /// GET /analytics/heatmap?days=30
  Future<HeatmapData> getHeatmap({int days = 30}) async {
    try {
      final response = await _dio.get('/analytics/heatmap', queryParameters: {'days': days});
      return HeatmapData.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }


  /// GET /transactions?start_date=...&end_date=...&category=...&customer_id=...
  /// All filters optional. NOTE: `customer_id` isn't in the endpoint's
  /// short param list ("start_date, end_date, category") given alongside
  /// the other 5 endpoints, but the Invoice screen's own logic explicitly
  /// calls for "GET /transactions with customer_id" to pull a customer's
  /// history. Treating it as an additional supported filter rather than
  /// silently dropping a requirement — confirm with the backend owner
  /// that this param is actually honored server-side.
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    String? customerId,
  }) async {
    try {
      final response = await _dio.get('/transactions', queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (category != null) 'category': category.name,
        if (customerId != null) 'customer_id': customerId,
      });
      final list = response.data as List<dynamic>;
      return list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }


  /// POST /customers/verify
  Future<Customer> verifyCustomer({
    required String customerId,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post('/customers/verify', data: {
        'customer_id': customerId,
        'phone_number': phoneNumber,
      });
      return Customer.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }
}


/// Retries idempotent GET requests (and POSTs the backend documents as
/// safe to retry, e.g. capture — duplicate captures are dedup'd
/// server-side by the AI model's own idempotency key) on transient
/// failures, with exponential backoff. Non-transient failures (4xx, 5xx
/// business errors) are not retried — retrying a 400 three times just
/// delays the error message the user needs to see.
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final List<Duration> _delays;


  _RetryInterceptor(this._dio, this._maxRetries, this._delays);


  static const _retryCountKey = 'retry_count';


  bool _isTransient(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }


  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;


    if (!_isTransient(err) || retryCount >= _maxRetries) {
      return handler.next(err);
    }


    await Future.delayed(_delays[retryCount]);


    final options = err.requestOptions;
    options.extra[_retryCountKey] = retryCount + 1;


    try {
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}