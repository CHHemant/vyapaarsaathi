import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/invoice.dart';
import '../../providers/invoices/invoice_provider.dart';
import '../../services/payment_slip_service.dart';
import '../../theme/kirana_colors.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final String? invoiceId;

  const InvoicePreviewScreen({
    super.key,
    this.invoiceId,
  });

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  static const String _merchantVpa = 'vyapaar.ramesh@icici';

  static const String _merchantName = 'VyapaarSaathi';

  bool _processing = false;

  Invoice? _findInvoice(
    List<Invoice> invoices,
  ) {
    final id = widget.invoiceId;

    if (id == null || id.isEmpty) {
      return null;
    }

    for (final invoice in invoices) {
      if (invoice.storageId == id) {
        return invoice;
      }
    }

    return null;
  }

  String _number(Invoice invoice) {
    return invoice.invoiceNumber ?? invoice.storageId ?? 'INVOICE';
  }

  String _amount(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  String _upi(Invoice invoice) {
    return 'upi://pay'
        '?pa=${Uri.encodeComponent(_merchantVpa)}'
        '&pn=${Uri.encodeComponent(_merchantName)}'
        '&am=${invoice.grandTotal.toStringAsFixed(2)}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent(_number(invoice))}';
  }

  Future<void> _whatsapp(
    Invoice invoice,
  ) async {
    final text = '''
*VyapaarSaathi Invoice*

Invoice: ${_number(invoice)}
Customer: ${invoice.customerName ?? 'Customer'}
GSTIN: ${invoice.customerId ?? 'N/A'}

Amount: ${_amount(invoice.grandTotal)}
Status: ${invoice.isPaid ? 'PAID' : 'PAYMENT PENDING'}

UPI: $_merchantVpa
Payment link:
${_upi(invoice)}

Thank you for your business.
''';

    final uri = Uri.parse(
      'whatsapp://send?text='
      '${Uri.encodeComponent(text)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _message(
          'WhatsApp is not available on this device.',
        );
      }
    } catch (_) {
      _message(
        'Could not open WhatsApp.',
      );
    }
  }

  Future<void> _openUpi(
    Invoice invoice,
  ) async {
    final paymentUri = Uri.parse(
      _upi(invoice),
    );

    try {
      final launched = await launchUrl(
        paymentUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await Clipboard.setData(
          ClipboardData(
            text: _upi(invoice),
          ),
        );

        _message(
          'No UPI app opened. Payment link copied.',
        );
      }
    } catch (_) {
      await Clipboard.setData(
        ClipboardData(
          text: _upi(invoice),
        ),
      );

      _message(
        'Payment link copied.',
      );
    }
  }

  Future<void> _copyVpa() async {
    await Clipboard.setData(
      const ClipboardData(
        text: _merchantVpa,
      ),
    );

    _message(
      'VPA copied.',
    );
  }

  Future<void> _markPaid(
    Invoice invoice,
  ) async {
    if (_processing) return;

    if (invoice.isPaid && invoice.paymentSlipPath != null) {
      _showSlip(
        invoice.paymentSlipPath!,
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final paidAt = DateTime.now();

      final path = await PaymentSlipService().createPaidSlip(
        invoice: invoice,
        paidAt: paidAt,
      );

      final updatedInvoice = invoice.copyWith(
        isPaid: true,
        paidAt: paidAt,
        paymentSlipPath: path,
      );

      await ref.read(invoiceProvider.notifier).saveInvoice(updatedInvoice);

      _message(
        'Payment completed. Receipt saved locally.',
      );
    } catch (error) {
      _message(
        'Could not create payment receipt: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  void _showSlip(String path) {
    final file = File(path);

    if (!file.existsSync()) {
      _message(
        'Saved payment slip is no longer available.',
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.88,
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Completed Payment Slip',
                  ),
                  subtitle: Text(
                    path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                ),
                Expanded(
                  child: SfPdfViewer.file(
                    file,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);

    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'INVOICE REVIEW',
              style: GoogleFonts.bebasNeue(
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            Text(
              'REVIEW • PAY • SHARE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: invoiceState.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(
              'Unable to load invoice.\n$error',
              textAlign: TextAlign.center,
            ),
          );
        },
        data: (invoices) {
          final invoice = _findInvoice(invoices);

          if (invoice == null) {
            return _notFound();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ),
            children: [
              _statusCard(invoice),
              const SizedBox(height: 10),
              _summaryCard(invoice),
              const SizedBox(height: 10),
              _paymentCard(invoice),
              const SizedBox(height: 10),
              _itemsCard(invoice),
              const SizedBox(height: 10),
              _actionsCard(invoice),
              const SizedBox(height: 10),
              _auditCard(invoice),
            ],
          );
        },
      ),
    );
  }

  Widget _notFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              'Invoice not found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The selected invoice could not be found in local storage.',
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.goNamed(
                  'invoice_list',
                );
              },
              child: const Text(
                'BACK TO GST SUITE',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(
    Invoice invoice,
  ) {
    final paid = invoice.isPaid;

    return _card(
      child: Row(
        children: [
          Icon(
            paid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
            color: paid ? Colors.green.shade700 : KiranaColors.secondary,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid ? 'PAYMENT COMPLETED' : 'INVOICE READY',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  paid
                      ? 'Receipt saved locally.'
                      : 'Review the bill before collecting payment.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    Invoice invoice,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_rounded,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TAX INVOICE',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 21,
                  ),
                ),
              ),
              Text(
                _number(invoice),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _detail(
            'Buyer',
            invoice.customerName ?? 'Customer',
          ),
          _detail(
            'GSTIN',
            invoice.customerId ?? 'N/A',
          ),
          _detail(
            'Place of supply',
            '27 - Maharashtra',
          ),
          if (invoice.createdAt != null)
            _detail(
              'Created',
              _formatDate(
                invoice.createdAt!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _detail(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(
    Invoice invoice,
  ) {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                color: KiranaColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'UPI PAYMENT',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 21,
                  ),
                ),
              ),
              Text(
                _amount(
                  invoice.grandTotal,
                ),
                style: GoogleFonts.bebasNeue(
                  fontSize: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black12,
              ),
            ),
            child: QrImageView(
              data: _upi(invoice),
              version: QrVersions.auto,
              size: 190,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _merchantVpa,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyVpa,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                  ),
                  label: const Text('COPY VPA'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openUpi(invoice),
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                  ),
                  label: const Text('OPEN UPI'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemsCard(
    Invoice invoice,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ITEMS',
            style: GoogleFonts.bebasNeue(
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < invoice.items.length; i++) ...[
            _itemRow(
              invoice.items[i],
            ),
            if (i != invoice.items.length - 1)
              const Divider(
                height: 18,
              ),
          ],
          const Divider(
            height: 20,
          ),
          _summaryRow(
            'Taxable value',
            invoice.subtotal,
          ),
          _summaryRow(
            'GST',
            invoice.gstTotal,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                ),
              ),
              Text(
                _amount(
                  invoice.grandTotal,
                ),
                style: GoogleFonts.bebasNeue(
                  fontSize: 27,
                  color: KiranaColors.secondaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(
    InvoiceItem item,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_formatQuantity(item.quantity)} × '
                '${_amount(item.unitPrice)} • '
                'GST ${item.gstRate.percent}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: KiranaColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _amount(item.lineTotal),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'GST ${_amount(item.lineGst)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 7,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    double value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
          Text(
            _amount(value),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsCard(
    Invoice invoice,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT STEP',
            style: GoogleFonts.bebasNeue(
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an action. Nothing is paid or sent automatically.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _processing ? null : () => _whatsapp(invoice),
              icon: const Icon(
                Icons.chat_rounded,
              ),
              label: const Text(
                'OPEN WHATSAPP & SHARE BILL',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: invoice.isPaid && invoice.paymentSlipPath != null
                ? OutlinedButton.icon(
                    onPressed: () {
                      _showSlip(
                        invoice.paymentSlipPath!,
                      );
                    },
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                    ),
                    label: const Text(
                      'OPEN PAYMENT SLIP',
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _processing
                        ? null
                        : () => _markPaid(
                              invoice,
                            ),
                    icon: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.payments_rounded,
                          ),
                    label: Text(
                      _processing
                          ? 'SAVING RECEIPT…'
                          : 'MARK PAYMENT COMPLETED',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _auditCard(
    Invoice invoice,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'LOCAL AUDIT RECORD',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Invoice: ${_number(invoice)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            invoice.isPaid ? 'Status: PAID' : 'Status: PAYMENT PENDING',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
          if (invoice.createdAt != null)
            Text(
              'Created: ${_formatDate(invoice.createdAt!)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
          if (invoice.paymentSlipPath != null) ...[
            const SizedBox(height: 7),
            Text(
              'Receipt: ${invoice.paymentSlipPath}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: child,
    );
  }

  String _formatQuantity(
    double quantity,
  ) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
