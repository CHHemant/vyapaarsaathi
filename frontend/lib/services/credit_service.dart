// frontend/lib/services/credit_service.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/credit_entry.dart';

class CreditService {
  static const String _boxName = 'udhaar_entries';
  Box<dynamic>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<List<CreditEntry>> getAllEntries() async {
    if (_box == null) await initialize();

    final entries = <CreditEntry>[];
    for (final data in _box!.values) {
      if (data is CreditEntry) {
        entries.add(data);
      } else if (data is Map) {
        entries.add(CreditEntry.fromJson(Map<String, dynamic>.from(data)));
      }
    }

    // Sort by date (newest first)
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<List<CreditEntry>> getUnpaidEntries() async {
    final all = await getAllEntries();
    return all.where((e) => !e.isPaid).toList();
  }

  Future<CreditEntry> addEntry(CreditEntry entry) async {
    if (_box == null) await initialize();
    await _box!.put(entry.id, entry.toJson());
    return entry;
  }

  Future<void> markAsPaid(String entryId) async {
    if (_box == null) await initialize();
    final data = _box!.get(entryId);
    if (data != null) {
      final entry = data is CreditEntry
          ? data
          : CreditEntry.fromJson(Map<String, dynamic>.from(data));
      final updated = entry.copyWith(
        isPaid: true,
        paidAt: DateTime.now(),
      );
      await _box!.put(entryId, updated.toJson());
    }
  }

  Future<void> deleteEntry(String entryId) async {
    if (_box == null) await initialize();
    await _box!.delete(entryId);
  }

  Future<Map<String, dynamic>> getSummary() async {
    final all = await getAllEntries();
    final unpaid = all.where((e) => !e.isPaid).toList();

    final totalGiven = unpaid
        .where((e) => e.type == 'given')
        .fold<double>(0, (sum, e) => sum + e.amount);

    final totalTaken = unpaid
        .where((e) => e.type == 'taken')
        .fold<double>(0, (sum, e) => sum + e.amount);

    return {
      'totalGiven': totalGiven,
      'totalTaken': totalTaken,
      'netCredit': totalGiven - totalTaken,
      'unpaidCount': unpaid.length,
    };
  }
}