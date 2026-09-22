// frontend/lib/services/credit_service.dart

import 'package:hive_flutter/hive_flutter.dart';

import '../models/credit_entry.dart';

/// Local persistence service for legacy/direct Khata access.
///
/// The service preserves the existing `udhaar_entries` Hive box so existing
/// data and callers are not silently moved to a different storage location.
///
/// Payment state is represented by:
/// - [CreditEntry.amount]      -> original entry amount
/// - [CreditEntry.paidAmount]  -> total amount paid so far
/// - [CreditEntry.remainingAmount] -> current outstanding amount
/// - [CreditEntry.isPaid]     -> true only when the entry is fully settled
class CreditService {
  static const String _boxName = 'udhaar_entries';

  Box<dynamic>? _box;

  Future<void> initialize() async {
    if (_box?.isOpen == true) {
      return;
    }

    _box = await Hive.openBox<dynamic>(_boxName);
  }

  Future<Box<dynamic>> get _storage async {
    if (_box?.isOpen != true) {
      await initialize();
    }

    return _box!;
  }

  Future<List<CreditEntry>> getAllEntries() async {
    final box = await _storage;
    final entries = <CreditEntry>[];

    for (final data in box.values) {
      if (data is CreditEntry) {
        entries.add(data);
      } else if (data is Map) {
        entries.add(
          CreditEntry.fromJson(
            Map<String, dynamic>.from(data),
          ),
        );
      }
    }

    entries.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return entries;
  }

  /// Returns entries that still have an outstanding balance.
  ///
  /// This includes both completely unpaid and partially paid entries.
  Future<List<CreditEntry>> getUnpaidEntries() async {
    final all = await getAllEntries();

    return all.where((entry) => entry.hasOutstanding).toList();
  }

  Future<CreditEntry> addEntry(CreditEntry entry) async {
    final box = await _storage;

    await box.put(
      entry.id,
      entry.toJson(),
    );

    return entry;
  }

  /// Records a partial or full payment against a Khata entry.
  ///
  /// Throws [ArgumentError] when the payment is invalid or exceeds the
  /// remaining balance, and [StateError] when the entry cannot be found or
  /// is already fully paid.
  Future<CreditEntry> recordPayment(
    String entryId,
    double paymentAmount,
  ) async {
    final box = await _storage;

    if (paymentAmount <= 0) {
      throw ArgumentError(
        'Payment amount must be greater than zero.',
      );
    }

    final data = box.get(entryId);

    if (data == null) {
      throw StateError(
        'Credit entry not found: $entryId',
      );
    }

    final entry = _decodeEntry(data);

    if (!entry.hasOutstanding) {
      throw StateError(
        'This credit entry is already fully paid.',
      );
    }

    if (paymentAmount > entry.remainingAmount + 0.000001) {
      throw ArgumentError(
        'Payment cannot exceed the remaining balance.',
      );
    }

    final newPaidAmount = entry.paidAmount + paymentAmount;
    final isNowFullyPaid = newPaidAmount >= entry.amount;

    final updated = entry.copyWith(
      paidAmount: isNowFullyPaid ? entry.amount : newPaidAmount,
      isPaid: isNowFullyPaid,
      paidAt: DateTime.now(),
    );

    await box.put(
      entryId,
      updated.toJson(),
    );

    return updated;
  }

  /// Marks the complete remaining balance as paid.
  ///
  /// Kept for compatibility with existing callers that need a one-step
  /// full-settlement action.
  Future<void> markAsPaid(String entryId) async {
    final box = await _storage;
    final data = box.get(entryId);

    if (data == null) {
      return;
    }

    final entry = _decodeEntry(data);

    if (!entry.hasOutstanding) {
      return;
    }

    final updated = entry.copyWith(
      paidAmount: entry.amount,
      isPaid: true,
      paidAt: DateTime.now(),
    );

    await box.put(
      entryId,
      updated.toJson(),
    );
  }

  Future<void> deleteEntry(String entryId) async {
    final box = await _storage;
    await box.delete(entryId);
  }

  /// Returns financial totals based on the actual remaining balances.
  Future<Map<String, dynamic>> getSummary() async {
    final all = await getAllEntries();

    final outstanding = all.where((entry) => entry.hasOutstanding).toList();

    final totalGiven =
        outstanding.where((entry) => entry.type == 'given').fold<double>(
              0,
              (sum, entry) => sum + entry.remainingAmount,
            );

    final totalTaken =
        outstanding.where((entry) => entry.type == 'taken').fold<double>(
              0,
              (sum, entry) => sum + entry.remainingAmount,
            );

    return <String, dynamic>{
      'totalGiven': totalGiven,
      'totalTaken': totalTaken,
      'netCredit': totalGiven - totalTaken,
      'unpaidCount': outstanding.length,
    };
  }

  CreditEntry _decodeEntry(dynamic data) {
    if (data is CreditEntry) {
      return data;
    }

    if (data is Map) {
      return CreditEntry.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw StateError(
      'Invalid credit entry data stored in Hive.',
    );
  }
}
