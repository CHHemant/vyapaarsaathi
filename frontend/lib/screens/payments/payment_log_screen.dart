import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/transaction.dart';
import '../../providers/transactions/transaction_provider.dart';
import '../../theme/kirana_colors.dart';

class PaymentLogScreen extends ConsumerWidget {
  const PaymentLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Text(
          'PAYMENT LOG',
          style: GoogleFonts.bebasNeue(
            fontSize: 25,
            color: KiranaColors.primary,
            letterSpacing: 1,
          ),
        ),
      ),
      body: payments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load payment records.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (transactions) {
          final sales = transactions
              .where((item) => item.category == TransactionCategory.sales)
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          final total = sales.fold<double>(
            0,
            (sum, item) => sum + item.amount,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _summary(total, sales.length),
              const SizedBox(height: 16),
              if (sales.isEmpty) _empty() else ...sales.map(_entry),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(double total, int count) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KiranaColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECORDED COLLECTIONS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_format(total)}',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 36,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: GoogleFonts.bebasNeue(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              Text(
                'RECORDS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _entry(Transaction transaction) {
    final customer = transaction.customerName?.trim();
    final title =
        customer == null || customer.isEmpty ? 'Recorded sale' : customer;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KiranaColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: KiranaColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              color: KiranaColors.onTertiaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_date(transaction.timestamp)} • ${transaction.isSynced ? 'SYNCED' : 'LOCAL'}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+₹${_format(transaction.amount)}',
            style: GoogleFonts.bebasNeue(
              fontSize: 19,
              color: KiranaColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: KiranaColors.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'NO PAYMENT RECORDS',
            style: GoogleFonts.bebasNeue(
              fontSize: 21,
              color: KiranaColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sales recorded through Quick Sale will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  String _date(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '$hour:$minute $period';
  }
}
