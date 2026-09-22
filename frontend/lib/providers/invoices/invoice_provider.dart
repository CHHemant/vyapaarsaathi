import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/invoice.dart';
import '../../services/invoice_service.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService();
});

final invoiceProvider = AsyncNotifierProvider<InvoiceNotifier, List<Invoice>>(
  InvoiceNotifier.new,
);

class InvoiceNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() async {
    return ref.read(invoiceServiceProvider).getInvoices();
  }

  Future<void> saveInvoice(Invoice invoice) async {
    final service = ref.read(invoiceServiceProvider);

    await service.saveInvoice(invoice);

    final invoices = await service.getInvoices();

    state = AsyncData(invoices);
  }

  Future<void> deleteInvoice(String storageId) async {
    final service = ref.read(invoiceServiceProvider);

    await service.deleteInvoice(storageId);

    final invoices = await service.getInvoices();

    state = AsyncData(invoices);
  }

  Future<void> refreshInvoices() async {
    final service = ref.read(invoiceServiceProvider);

    state = const AsyncLoading();

    try {
      final invoices = await service.getInvoices();

      state = AsyncData(invoices);
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }

  Future<void> clearInvoices() async {
    final service = ref.read(invoiceServiceProvider);

    await service.clearInvoices();

    state = const AsyncData([]);
  }
}
