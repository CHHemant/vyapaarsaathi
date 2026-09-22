// frontend/lib/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../theme/kirana_colors.dart';

/// A sleek transaction tile based on the True Master Dashboard design.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        TimeOfDay.fromDateTime(transaction.timestamp).format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: KiranaColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            transaction.category.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          transaction.customerName ?? 'Direct Sale',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: KiranaColors.primary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              'INV #VS-${transaction.id.substring(transaction.id.length.clamp(0, 3))} â€¢ $timeLabel',
              style: GoogleFonts.monoton(
                fontSize: 9,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'â‚¹${transaction.amount.toStringAsFixed(0)}',
              style: GoogleFonts.monoton(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: KiranaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: transaction.isSynced
                    ? const Color(0xFFC2ECD8)
                    : const Color(0xFFFFDAD2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                transaction.isSynced ? 'PAID VIA UPI' : 'PENDING SYNC',
                style: GoogleFonts.monoton(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: transaction.isSynced
                      ? const Color(0xFF002116)
                      : const Color(0xFF3D0600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
