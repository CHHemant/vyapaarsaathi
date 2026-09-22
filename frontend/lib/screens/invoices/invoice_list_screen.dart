import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/invoice.dart';
import '../../providers/invoices/invoice_provider.dart';
import '../../theme/kirana_colors.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  String _filter = 'All';

  final GlobalKey _historyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);

    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Text(
          'GST SUITE',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(invoiceProvider.notifier).refreshInvoices();
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: invoiceState.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return _errorState(error);
        },
        data: (invoices) {
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(invoiceProvider.notifier).refreshInvoices();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              children: [
                _header(),
                const SizedBox(height: 14),
                _overviewCard(invoices),
                const SizedBox(height: 14),
                _quickActions(),
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: _historyKey,
                  child: _historySection(
                    invoices,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed(
            'create_invoice',
          );
        },
        backgroundColor: KiranaColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: Text(
          'CREATE INVOICE',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final now = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GST & INVOICES',
                style: GoogleFonts.bebasNeue(
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Record → Bill → Collect → Understand',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: KiranaColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          DateFormat('MMM yyyy').format(now),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _overviewCard(
    List<Invoice> invoices,
  ) {
    final now = DateTime.now();

    final currentMonthInvoices = invoices.where((invoice) {
      final date = invoice.createdAt;

      if (date == null) {
        return false;
      }

      return date.year == now.year && date.month == now.month;
    }).toList();

    final taxableSales = currentMonthInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.subtotal,
    );

    final gst = currentMonthInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.gstTotal,
    );

    final invoiceCount = currentMonthInvoices.length;

    final unpaidCount = currentMonthInvoices
        .where(
          (invoice) => !invoice.isPaid,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KiranaColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: KiranaColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTH OVERVIEW',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(now),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        color: KiranaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (currentMonthInvoices.isEmpty) _smallBadge('NO DATA'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'TAXABLE SALES',
                  _money(taxableSales),
                  Icons.trending_up_rounded,
                ),
              ),
              Expanded(
                child: _metric(
                  'GST',
                  _money(gst),
                  Icons.percent_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'INVOICES',
                  invoiceCount.toString(),
                  Icons.receipt_long_rounded,
                ),
              ),
              Expanded(
                child: _metric(
                  'UNPAID',
                  unpaidCount.toString(),
                  Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: KiranaColors.secondary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 20,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
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

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.add_business_rounded,
            title: 'CREATE INVOICE',
            subtitle: 'New customer bill',
            filled: true,
            onTap: () {
              context.pushNamed(
                'create_invoice',
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.history_rounded,
            title: 'INVOICE HISTORY',
            subtitle: 'View saved bills',
            onTap: _scrollToHistory,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: filled
                ? KiranaColors.primary
                : KiranaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(
                    color: Colors.black.withValues(
                      alpha: 0.06,
                    ),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: filled ? Colors.white : KiranaColors.primary,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: filled ? Colors.white : KiranaColors.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color:
                      filled ? Colors.white70 : KiranaColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToHistory() {
    setState(() {
      _filter = 'All';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyContext = _historyKey.currentContext;

      if (historyContext == null) return;

      Scrollable.ensureVisible(
        historyContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  Widget _historySection(
    List<Invoice> invoices,
  ) {
    final filtered = invoices.where((invoice) {
      switch (_filter) {
        case 'Paid':
          return invoice.isPaid;
        case 'Unpaid':
          return !invoice.isPaid;
        default:
          return true;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVOICE HISTORY',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    '${filtered.length} saved invoice${filtered.length == 1 ? '' : 's'}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      color: KiranaColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              initialValue: _filter,
              onSelected: (value) {
                setState(() {
                  _filter = value;
                });
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
                PopupMenuItem(
                  value: 'Paid',
                  child: Text('Paid'),
                ),
                PopupMenuItem(
                  value: 'Unpaid',
                  child: Text('Unpaid'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: KiranaColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filter.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _emptyHistory()
        else
          for (var i = 0; i < filtered.length; i++) ...[
            _invoiceCard(filtered[i]),
            if (i != filtered.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _invoiceCard(
    Invoice invoice,
  ) {
    final date = invoice.createdAt;

    final dateText = date == null
        ? 'Date unavailable'
        : DateFormat(
            'dd MMM yyyy • hh:mm a',
          ).format(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: invoice.storageId == null
            ? null
            : () {
                context.pushNamed(
                  'invoice_preview',
                  extra: invoice.storageId,
                );
              },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: KiranaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.black.withValues(
                alpha: 0.06,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: invoice.isPaid
                      ? Colors.green.withValues(
                          alpha: 0.10,
                        )
                      : KiranaColors.primary.withValues(
                          alpha: 0.10,
                        ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  invoice.isPaid
                      ? Icons.check_circle_outline_rounded
                      : Icons.receipt_long_outlined,
                  color: invoice.isPaid
                      ? Colors.green.shade700
                      : KiranaColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.customerName?.trim().isNotEmpty == true
                          ? invoice.customerName!
                          : 'Unnamed Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.invoiceNumber ?? 'Invoice',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateText,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 7,
                        color: KiranaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(invoice.grandTotal),
                    style: GoogleFonts.bebasNeue(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _statusBadge(invoice),
                ],
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(
    Invoice invoice,
  ) {
    final paid = invoice.isPaid;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: paid
            ? Colors.green.withValues(
                alpha: 0.10,
              )
            : Colors.orange.withValues(
                alpha: 0.10,
              ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        paid ? 'PAID' : 'UNPAID',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 7,
          fontWeight: FontWeight.bold,
          color: paid ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            _filter == 'All' ? 'No invoices yet' : 'No $_filter invoices',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _filter == 'All'
                ? 'Create your first invoice to see it here.'
                : 'Invoices matching this filter will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
          if (_filter == 'All') ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                context.pushNamed(
                  'create_invoice',
                );
              },
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'CREATE INVOICE',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorState(
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load invoices',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref
                    .read(
                      invoiceProvider.notifier,
                    )
                    .refreshInvoices();
              },
              child: const Text(
                'TRY AGAIN',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _money(double value) {
    return '₹${NumberFormat(
      '#,##0.00',
      'en_IN',
    ).format(value)}';
  }
}
