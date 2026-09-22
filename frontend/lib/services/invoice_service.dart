import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/invoice.dart';

class InvoiceService {
  static const String _boxName = 'invoices_cache';

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }

    return Hive.openBox<String>(_boxName);
  }

  Future<List<Invoice>> getInvoices() async {
    final box = await _openBox();

    final invoices = <Invoice>[];

    for (final value in box.values) {
      try {
        final decoded = jsonDecode(value);

        if (decoded is Map) {
          invoices.add(
            Invoice.fromJson(
              Map<String, dynamic>.from(decoded),
            ),
          );
        }
      } catch (_) {
        // Ignore one corrupted record and continue loading others.
      }
    }

    invoices.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }

      if (aDate != null) return -1;

      if (bDate != null) return 1;

      return (b.storageId ?? '').compareTo(
        a.storageId ?? '',
      );
    });

    return invoices;
  }

  Future<void> saveInvoice(Invoice invoice) async {
    final box = await _openBox();

    final key = invoice.storageId ??
        invoice.invoiceNumber ??
        DateTime.now().microsecondsSinceEpoch.toString();

    await box.put(
      key,
      jsonEncode(invoice.toJson()),
    );
  }

  Future<void> deleteInvoice(String storageId) async {
    final box = await _openBox();

    await box.delete(storageId);
  }

  Future<void> clearInvoices() async {
    final box = await _openBox();

    await box.clear();
  }
}
