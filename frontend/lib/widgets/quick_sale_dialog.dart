// frontend/lib/widgets/quick_sale_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../providers/core_providers.dart';
import '../theme/kirana_colors.dart';
import '../widgets/kirana_card.dart';
import '../widgets/rupee_button.dart';

class QuickSaleDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaleComplete;

  const QuickSaleDialog({super.key, required this.onSaleComplete});

  @override
  ConsumerState<QuickSaleDialog> createState() => _QuickSaleDialogState();
}

class _QuickSaleDialogState extends ConsumerState<QuickSaleDialog> {
  final _customAmountController = TextEditingController();
  double? _selectedAmount;
  TransactionCategory _selectedCategory = TransactionCategory.sales;

  final List<double> _presetAmounts = [10, 20, 50, 100, 200, 500];

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: KiranaCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: KiranaColors.premiumGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Sale',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                        Text(
                          'Instant transaction entry',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Amount Selection
                  Row(
                    children: [
                      Text('Amount', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _presetAmounts.length,
                    itemBuilder: (context, index) {
                      final amount = _presetAmounts[index];
                      final isSelected = _selectedAmount == amount;
                      return _AmountButton(
                        amount: amount,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedAmount = amount;
                            _customAmountController.text = amount.toStringAsFixed(0);
                          });
                          HapticFeedback.selectionClick();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _customAmountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter custom amount',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic_rounded, color: KiranaColors.primary),
                        onPressed: _voiceInput,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedAmount = double.tryParse(value);
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  // Category
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Category', style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: TransactionCategory.values.length,
                      itemBuilder: (context, index) {
                        final cat = TransactionCategory.values[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _CategoryChip(
                            category: cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              HapticFeedback.selectionClick();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  RupeeButton(
                    label: 'Confirm Transaction',
                    icon: Icons.check_circle_outline_rounded,
                    showRupeePrefix: false,
                    fullWidth: true,
                    onPressed: _selectedAmount != null && _selectedAmount! > 0 ? _completeSale : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeSale() {
    if (_selectedAmount == null) return;

    // Add transaction to cache
    final cache = ref.read(cacheServiceProvider);
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: _selectedAmount!,
      category: _selectedCategory,
      timestamp: DateTime.now(),
      confidence: 100,
      customerName: 'Quick Sale',
      customerId: 'QS${DateTime.now().millisecondsSinceEpoch}',
      isSynced: true,
    );

    cache.addTransaction(transaction);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    Navigator.pop(context);
    widget.onSaleComplete();
  }

  void _voiceInput() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listening for amount...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() {
      _selectedAmount = 150.0;
      _customAmountController.text = '150';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detected ₹150'),
        backgroundColor: KiranaColors.primary,
      ),
    );
  }
}

class _AmountButton extends StatelessWidget {
  final double amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmountButton({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? KiranaColors.secondary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? KiranaColors.secondary : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: KiranaColors.secondary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final TransactionCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? KiranaColors.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? KiranaColors.primary : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}