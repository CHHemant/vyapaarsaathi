// frontend/lib/widgets/daily_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/kirana_colors.dart';
import '../widgets/kirana_card.dart';

class DailySummaryWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime date;

  const DailySummaryWidget({
    required this.transactions,
    required this.date,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final totalSales = transactions
        .where((t) => t.category == TransactionCategory.sales)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpenses = transactions
        .where((t) => t.category == TransactionCategory.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final netProfit = totalSales - totalExpenses;
    final transactionCount = transactions.length;

    return KiranaCard(
      color: KiranaColors.primary,
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assessment,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMM').format(date),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$transactionCount transactions',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareSummary(context, totalSales, totalExpenses, netProfit, transactionCount),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Sales',
                  amount: totalSales,
                  color: Colors.green.shade300,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: 'Expenses',
                  amount: totalExpenses,
                  color: Colors.orange.shade300,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  label: 'Net',
                  amount: netProfit,
                  color: Colors.white,
                  icon: Icons.account_balance_wallet,
                  isPrimary: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Daily Target',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((totalSales / 2000) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (totalSales / 2000).clamp(0, 1),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareSummary(
    BuildContext context,
    double sales,
    double expenses,
    double net,
    int count,
  ) async {
    HapticFeedback.lightImpact();

    final message = '''
📊 *Daily Summary - ${DateFormat('dd MMM').format(date)}*

💰 Sales: ₹${sales.toStringAsFixed(0)}
💸 Expenses: ₹${expenses.toStringAsFixed(0)}
📈 Net: ₹${net.toStringAsFixed(0)}
🧾 Transactions: $count

Powered by VyapaarSaathi
    '''.trim();

    await Share.share(message);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary shared!'),
          backgroundColor: KiranaColors.success,
        ),
      );
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isPrimary;

  const _StatBox({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isPrimary ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isPrimary ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}