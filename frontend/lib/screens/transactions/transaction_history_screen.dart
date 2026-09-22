import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../providers/transactions/transaction_provider.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(transactionProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load transactions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => ref.invalidate(transactionProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (transactions) {
          final filteredTransactions = _filteredTransactions(transactions);

          final sales = transactions
              .where(
                (transaction) =>
                    transaction.category == TransactionCategory.sales,
              )
              .fold<double>(
                0,
                (total, transaction) => total + transaction.amount,
              );

          final expenses = transactions
              .where(
                (transaction) =>
                    transaction.category == TransactionCategory.expense,
              )
              .fold<double>(
                0,
                (total, transaction) => total + transaction.amount,
              );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionProvider);
              await ref.read(transactionProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Sales',
                            amount: sales,
                            icon: Icons.trending_up,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Expenses',
                            amount: expenses,
                            icon: Icons.trending_down,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 54,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filter == 'All',
                          onSelected: () {
                            setState(() => _filter = 'All');
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Sales',
                          selected: _filter == 'Sales',
                          onSelected: () {
                            setState(() => _filter = 'Sales');
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Expenses',
                          selected: _filter == 'Expenses',
                          onSelected: () {
                            setState(() => _filter = 'Expenses');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredTransactions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TransactionTile(
                            transaction: transaction,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Transaction> _filteredTransactions(
    List<Transaction> transactions,
  ) {
    final result = switch (_filter) {
      'Sales' => transactions
          .where(
            (transaction) => transaction.category == TransactionCategory.sales,
          )
          .toList(),
      'Expenses' => transactions
          .where(
            (transaction) =>
                transaction.category == TransactionCategory.expense,
          )
          .toList(),
      _ => List<Transaction>.from(transactions),
    };

    result.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    );

    return result;
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.category == TransactionCategory.expense;

    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(transaction.timestamp);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: Text(
            transaction.category.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          transaction.customerName ?? _categoryName(transaction.category),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_categoryName(transaction.category)} • $formattedDate',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? '-' : '+'}₹${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              transaction.isSynced ? 'Synced' : 'Local',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _categoryName(TransactionCategory category) {
    return switch (category) {
      TransactionCategory.groceries => 'Groceries',
      TransactionCategory.vegetables => 'Vegetables',
      TransactionCategory.auto => 'Auto',
      TransactionCategory.sales => 'Sale',
      TransactionCategory.expense => 'Expense',
      TransactionCategory.other => 'Other',
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transactions you record will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
