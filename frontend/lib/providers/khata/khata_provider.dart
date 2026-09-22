import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/credit_entry.dart';
import '../core_providers.dart';

/// Provides all locally stored Khata entries.
///
/// Hive is the source of truth for the offline-first Khata module.
final khataEntriesProvider =
    AsyncNotifierProvider<KhataEntriesNotifier, List<CreditEntry>>(
  KhataEntriesNotifier.new,
);

class KhataEntriesNotifier extends AsyncNotifier<List<CreditEntry>> {
  @override
  Future<List<CreditEntry>> build() async {
    final cache = ref.watch(cacheServiceProvider);

    return cache.getCreditEntries();
  }

  /// Adds a new Khata entry.
  Future<void> addEntry(CreditEntry entry) async {
    final cache = ref.read(cacheServiceProvider);

    try {
      await cache.addCreditEntry(entry);

      state = AsyncData(
        cache.getCreditEntries(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Updates an existing Khata entry.
  Future<void> updateEntry(CreditEntry entry) async {
    final cache = ref.read(cacheServiceProvider);

    try {
      await cache.updateCreditEntry(entry);

      state = AsyncData(
        cache.getCreditEntries(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Deletes an existing Khata entry.
  Future<void> deleteEntry(String entryId) async {
    final cache = ref.read(cacheServiceProvider);

    try {
      await cache.deleteCreditEntry(entryId);

      state = AsyncData(
        cache.getCreditEntries(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Records a payment against a Khata entry.
  ///
  /// Supports:
  /// - Full payment
  /// - Partial payment
  ///
  /// Example:
  /// Amount = ₹1000
  /// Payment = ₹300
  /// paidAmount = ₹300
  /// remainingAmount = ₹700
  Future<void> recordPayment(
    String entryId,
    double paymentAmount,
  ) async {
    if (paymentAmount <= 0) {
      throw ArgumentError(
        'Payment amount must be greater than zero.',
      );
    }

    final entry = _findEntry(entryId);

    if (entry.isPaid || entry.remainingAmount <= 0) {
      throw StateError(
        'This Khata entry is already fully paid.',
      );
    }

    if (paymentAmount > entry.remainingAmount) {
      throw ArgumentError(
        'Payment amount cannot be greater than the remaining balance.',
      );
    }

    final newPaidAmount = entry.paidAmount + paymentAmount;
    final isNowFullyPaid = newPaidAmount >= entry.amount;

    final updatedEntry = entry.copyWith(
      paidAmount: isNowFullyPaid ? entry.amount : newPaidAmount,
      isPaid: isNowFullyPaid,
      paidAt: DateTime.now(),
    );

    await updateEntry(updatedEntry);
  }

  /// Marks a Khata entry as fully paid.
  ///
  /// This is equivalent to paying the complete remaining amount.
  Future<void> markAsPaid(String entryId) async {
    final entry = _findEntry(entryId);

    if (entry.isPaid || entry.remainingAmount <= 0) {
      return;
    }

    final updatedEntry = entry.copyWith(
      paidAmount: entry.amount,
      isPaid: true,
      paidAt: DateTime.now(),
    );

    await updateEntry(updatedEntry);
  }

  /// Marks a Khata entry as unpaid.
  ///
  /// This resets the payment state completely.
  ///
  /// Example:
  /// Amount = ₹1000
  /// Paid = ₹500
  ///
  /// After mark as unpaid:
  /// Paid = ₹0
  /// Remaining = ₹1000
  Future<void> markAsUnpaid(String entryId) async {
    final entry = _findEntry(entryId);

    final updatedEntry = entry.copyWith(
      paidAmount: 0,
      isPaid: false,
      clearPaidAt: true,
    );

    await updateEntry(updatedEntry);
  }

  /// Finds an entry safely by ID.
  CreditEntry _findEntry(String entryId) {
    final entries = state.valueOrNull ?? const <CreditEntry>[];

    for (final entry in entries) {
      if (entry.id == entryId) {
        return entry;
      }
    }

    throw StateError(
      'Khata entry not found: $entryId',
    );
  }

  /// Reloads Khata entries directly from Hive.
  Future<void> refresh() async {
    final cache = ref.read(cacheServiceProvider);

    try {
      state = AsyncData(
        cache.getCreditEntries(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

/// Returns entries belonging to one customer.
final customerKhataEntriesProvider =
    Provider.family<AsyncValue<List<CreditEntry>>, String>(
  (ref, customerId) {
    final entries = ref.watch(khataEntriesProvider);

    return entries.whenData(
      (allEntries) {
        final customerEntries = allEntries
            .where(
              (entry) => entry.customerId == customerId,
            )
            .toList();

        customerEntries.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        return customerEntries;
      },
    );
  },
);

/// Total amount the customer owes the business.
///
/// Uses remainingAmount so partial payments are handled correctly.
///
/// Only `given` entries with an outstanding balance are included.
final customerReceivableProvider = Provider.family<AsyncValue<double>, String>(
  (ref, customerId) {
    final entries = ref.watch(
      customerKhataEntriesProvider(customerId),
    );

    return entries.whenData(
      (customerEntries) => customerEntries
          .where(
            (entry) => entry.type == 'given' && entry.hasOutstanding,
          )
          .fold<double>(
            0,
            (total, entry) => total + entry.remainingAmount,
          ),
    );
  },
);

/// Total amount the business owes the customer.
///
/// Uses remainingAmount so partial payments are handled correctly.
///
/// Only `taken` entries with an outstanding balance are included.
final customerPayableProvider = Provider.family<AsyncValue<double>, String>(
  (ref, customerId) {
    final entries = ref.watch(
      customerKhataEntriesProvider(customerId),
    );

    return entries.whenData(
      (customerEntries) => customerEntries
          .where(
            (entry) => entry.type == 'taken' && entry.hasOutstanding,
          )
          .fold<double>(
            0,
            (total, entry) => total + entry.remainingAmount,
          ),
    );
  },
);

/// Net outstanding balance for a customer.
///
/// Positive:
/// Customer owes the business.
///
/// Negative:
/// Business owes the customer.
///
/// Zero:
/// Account is settled.
final customerOutstandingProvider = Provider.family<AsyncValue<double>, String>(
  (ref, customerId) {
    final receivable = ref.watch(
      customerReceivableProvider(customerId),
    );

    final payable = ref.watch(
      customerPayableProvider(customerId),
    );

    if (receivable.hasError) {
      return AsyncError(
        receivable.error!,
        receivable.stackTrace ?? StackTrace.current,
      );
    }

    if (payable.hasError) {
      return AsyncError(
        payable.error!,
        payable.stackTrace ?? StackTrace.current,
      );
    }

    if (receivable.isLoading || payable.isLoading) {
      return const AsyncLoading();
    }

    return AsyncData(
      (receivable.valueOrNull ?? 0) - (payable.valueOrNull ?? 0),
    );
  },
);

/// Returns all Khata entries that still have money outstanding.
///
/// This correctly includes partially-paid entries.
final unpaidKhataEntriesProvider = Provider<AsyncValue<List<CreditEntry>>>(
  (ref) {
    final entries = ref.watch(khataEntriesProvider);

    return entries.whenData(
      (items) {
        final unpaid = items
            .where(
              (entry) => entry.hasOutstanding,
            )
            .toList();

        unpaid.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        return unpaid;
      },
    );
  },
);

/// Total amount receivable across all customers.
///
/// Uses remainingAmount instead of amount so partial payments
/// are not counted twice.
final totalReceivableProvider = Provider<AsyncValue<double>>(
  (ref) {
    final entries = ref.watch(khataEntriesProvider);

    return entries.whenData(
      (items) => items
          .where(
            (entry) => entry.type == 'given' && entry.hasOutstanding,
          )
          .fold<double>(
            0,
            (total, entry) => total + entry.remainingAmount,
          ),
    );
  },
);

/// Total amount payable across all customers.
///
/// Uses remainingAmount instead of amount so partial payments
/// are handled correctly.
final totalPayableProvider = Provider<AsyncValue<double>>(
  (ref) {
    final entries = ref.watch(khataEntriesProvider);

    return entries.whenData(
      (items) => items
          .where(
            (entry) => entry.type == 'taken' && entry.hasOutstanding,
          )
          .fold<double>(
            0,
            (total, entry) => total + entry.remainingAmount,
          ),
    );
  },
);

/// Net outstanding amount across the complete Khata.
final totalOutstandingProvider = Provider<AsyncValue<double>>(
  (ref) {
    final receivable = ref.watch(
      totalReceivableProvider,
    );

    final payable = ref.watch(
      totalPayableProvider,
    );

    if (receivable.hasError) {
      return AsyncError(
        receivable.error!,
        receivable.stackTrace ?? StackTrace.current,
      );
    }

    if (payable.hasError) {
      return AsyncError(
        payable.error!,
        payable.stackTrace ?? StackTrace.current,
      );
    }

    if (receivable.isLoading || payable.isLoading) {
      return const AsyncLoading();
    }

    return AsyncData(
      (receivable.valueOrNull ?? 0) - (payable.valueOrNull ?? 0),
    );
  },
);
