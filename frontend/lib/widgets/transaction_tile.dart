// frontend/lib/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/kirana_colors.dart';

/// One row in any transaction list (Home's recent activity, a future
/// transaction-history view). Shows the category emoji, customer name
/// (or "New Customer" when unidentified), time, and the amount in
/// Roboto Mono per the design spec.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = TimeOfDay.fromDateTime(transaction.timestamp).format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: KiranaColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            transaction.category.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          transaction.customerName ?? 'Direct Sale',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text(
              timeLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: transaction.amount > 0 ? KiranaColors.secondary : theme.colorScheme.onSurface,
              ),
            ),
            if (!transaction.isSynced)
              Text(
                'PENDING',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: KiranaColors.tertiary,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
