import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/credit_entry.dart';
import '../models/transaction.dart';
import '../providers/core_providers.dart';
import '../providers/khata/khata_provider.dart';
import '../providers/transactions/transaction_provider.dart';
import '../theme/kirana_colors.dart';
import 'kirana_card.dart';
import 'rupee_button.dart';

class QuickSaleDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaleComplete;

  const QuickSaleDialog({
    super.key,
    required this.onSaleComplete,
  });

  @override
  ConsumerState<QuickSaleDialog> createState() => _QuickSaleDialogState();
}

class _QuickSaleDialogState extends ConsumerState<QuickSaleDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _newCustomerNameController =
      TextEditingController();
  final TextEditingController _newCustomerPhoneController =
      TextEditingController();

  static const List<double> _presetAmounts = [
    10,
    20,
    50,
    100,
    200,
    500,
  ];

  double? _selectedAmount;

  TransactionCategory _selectedCategory = TransactionCategory.sales;

  bool _isSaving = false;

  /// false = Cash
  /// true = Credit
  bool _isCredit = false;

  /// Existing selected customer/party.
  _QuickSaleCustomer? _selectedCustomer;

  /// Whether the user is creating a new customer.
  bool _creatingNewCustomer = false;

  String _customerSearchQuery = '';

  @override
  void dispose() {
    _amountController.dispose();
    _customerSearchController.dispose();
    _newCustomerNameController.dispose();
    _newCustomerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final khataAsync = ref.watch(khataEntriesProvider);

    final customers = khataAsync.when(
      loading: () => <_QuickSaleCustomer>[],
      error: (_, __) => <_QuickSaleCustomer>[],
      data: _buildCustomers,
    );

    final filteredCustomers = customers.where((customer) {
      final query = _customerSearchQuery.trim().toLowerCase();

      if (query.isEmpty) return true;

      return customer.name.toLowerCase().contains(query) ||
          customer.phone.contains(query);
    }).toList();

    final canSubmit = !_isSaving &&
        _selectedAmount != null &&
        _selectedAmount! > 0 &&
        (!_isCredit ||
            (_creatingNewCustomer
                ? _newCustomerNameController.text.trim().isNotEmpty
                : _selectedCustomer != null));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 720,
        ),
        child: KiranaCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildAmountSection(theme),
                      const SizedBox(height: 28),
                      _buildCategorySection(theme),
                      const SizedBox(height: 28),
                      _buildPaymentTypeSection(),
                      if (_isCredit) ...[
                        const SizedBox(height: 24),
                        _buildCustomerSection(
                          filteredCustomers,
                        ),
                      ],
                      const SizedBox(height: 30),
                      RupeeButton(
                        label: _isSaving
                            ? 'Saving...'
                            : _isCredit
                                ? 'Save Credit Sale'
                                : 'Confirm Cash Sale',
                        icon: _isSaving
                            ? Icons.hourglass_top_rounded
                            : _isCredit
                                ? Icons.account_balance_wallet_rounded
                                : Icons.check_circle_outline_rounded,
                        showRupeePrefix: false,
                        fullWidth: true,
                        onPressed: canSubmit ? _completeTransaction : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: KiranaColors.premiumGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Record a transaction instantly',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.currency_rupee_rounded,
              size: 15,
              color: KiranaColors.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAmountPresets(),
        const SizedBox(height: 20),
        _buildAmountField(),
      ],
    );
  }

  Widget _buildAmountPresets() {
    return GridView.builder(
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

        return _AmountButton(
          amount: amount,
          isSelected: _selectedAmount == amount,
          onTap: () => _selectAmount(amount),
        );
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*\.?\d{0,2}'),
        ),
      ],
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
      decoration: const InputDecoration(
        hintText: 'Enter custom amount',
        prefixIcon: Icon(
          Icons.currency_rupee_rounded,
          size: 20,
        ),
      ),
      onChanged: _handleAmountChanged,
      onFieldSubmitted: (_) {
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildCategorySelector(),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TransactionCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = TransactionCategory.values[index];

          return _CategoryChip(
            category: category,
            isSelected: _selectedCategory == category,
            onTap: () => _selectCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildPaymentTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PaymentTypeCard(
                title: 'Cash',
                subtitle: 'Paid now',
                icon: Icons.payments_rounded,
                selected: !_isCredit,
                color: KiranaColors.primary,
                onTap: () {
                  if (_isSaving) return;

                  setState(() {
                    _isCredit = false;
                    _selectedCustomer = null;
                    _creatingNewCustomer = false;
                  });

                  HapticFeedback.selectionClick();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PaymentTypeCard(
                title: 'Credit',
                subtitle: 'Add to Khata',
                icon: Icons.account_balance_wallet_rounded,
                selected: _isCredit,
                color: KiranaColors.secondary,
                onTap: () {
                  if (_isSaving) return;

                  setState(() {
                    _isCredit = true;
                  });

                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerSection(
    List<_QuickSaleCustomer> customers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Customer / Party',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            if (!_creatingNewCustomer)
              TextButton.icon(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _creatingNewCustomer = true;
                          _selectedCustomer = null;
                        });
                      },
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 17,
                ),
                label: const Text('New'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_creatingNewCustomer)
          _buildNewCustomerForm()
        else
          _buildExistingCustomerSelector(customers),
      ],
    );
  }

  Widget _buildExistingCustomerSelector(
    List<_QuickSaleCustomer> customers,
  ) {
    return Column(
      children: [
        TextField(
          controller: _customerSearchController,
          onChanged: (value) {
            setState(() {
              _customerSearchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search customer...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _customerSearchQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _customerSearchController.clear();

                      setState(() {
                        _customerSearchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        if (customers.isEmpty)
          _buildEmptyCustomerState()
        else
          ...customers.take(5).map(
                (customer) => _buildCustomerTile(customer),
              ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSaving
                ? null
                : () {
                    setState(() {
                      _creatingNewCustomer = true;
                      _selectedCustomer = null;
                    });
                  },
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 18,
            ),
            label: const Text('Add New Customer'),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerTile(_QuickSaleCustomer customer) {
    final selected = _selectedCustomer?.id == customer.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
            ? KiranaColors.primary.withValues(alpha: 0.08)
            : KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? KiranaColors.primary
              : KiranaColors.outlineVariant.withValues(
                  alpha: 0.20,
                ),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: _isSaving
            ? null
            : () {
                setState(() {
                  _selectedCustomer = customer;
                });

                HapticFeedback.selectionClick();
              },
        leading: CircleAvatar(
          backgroundColor: KiranaColors.primary.withValues(alpha: 0.10),
          child: Text(
            _getInitials(customer.name),
            style: const TextStyle(
              color: KiranaColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          customer.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: customer.phone.isEmpty ? null : Text(customer.phone),
        trailing: selected
            ? const Icon(
                Icons.check_circle_rounded,
                color: KiranaColors.primary,
              )
            : const Icon(
                Icons.chevron_right_rounded,
                color: KiranaColors.onSurfaceVariant,
              ),
      ),
    );
  }

  Widget _buildNewCustomerForm() {
    return Column(
      children: [
        TextFormField(
          controller: _newCustomerNameController,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Customer name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _newCustomerPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number (optional)',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isSaving
                ? null
                : () {
                    setState(() {
                      _creatingNewCustomer = false;
                    });
                  },
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 17,
            ),
            label: const Text('Choose existing customer'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCustomerState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 32,
            color: KiranaColors.onSurfaceVariant,
          ),
          SizedBox(height: 8),
          Text(
            'No customers found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _selectAmount(double amount) {
    if (_isSaving) return;

    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
    });

    HapticFeedback.selectionClick();
  }

  void _handleAmountChanged(String value) {
    final normalizedValue =
        value.trim().startsWith('.') ? '0${value.trim()}' : value.trim();
    final amount = double.tryParse(normalizedValue);

    setState(() {
      _selectedAmount = amount != null && amount > 0 ? amount : null;
    });
  }

  void _selectCategory(TransactionCategory category) {
    if (_isSaving) return;

    setState(() {
      _selectedCategory = category;
    });

    HapticFeedback.selectionClick();
  }

  List<_QuickSaleCustomer> _buildCustomers(
    List<CreditEntry> entries,
  ) {
    final map = <String, _QuickSaleCustomer>{};

    for (final entry in entries) {
      final customerId = entry.customerId.trim();
      final customerName = entry.customerName.trim();

      if (customerId.isEmpty || customerName.isEmpty) {
        continue;
      }

      map.putIfAbsent(
        customerId,
        () => _QuickSaleCustomer(
          id: customerId,
          name: customerName,
          phone: entry.customerPhone.trim(),
        ),
      );
    }

    final customers = map.values.toList();

    customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return customers;
  }

  String _getCustomerId(
    String name,
    String phone,
  ) {
    final normalized =
        '${name.trim().toLowerCase()}_${phone.replaceAll(RegExp(r'\D'), '')}';

    var hash = 0;

    for (final codeUnit in normalized.codeUnits) {
      hash = ((hash << 5) - hash + codeUnit) & 0x7fffffff;
    }

    return 'party_$hash';
  }

  String _getInitials(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    final parts = trimmed.split(RegExp(r'\s+'));

    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  Future<void> _completeTransaction() async {
    if (_isSaving) return;

    final amount = _selectedAmount;

    if (amount == null || amount <= 0) {
      return;
    }

    String customerId = '';
    String customerName = 'Cash Sale';
    String customerPhone = '';

    if (_isCredit) {
      if (_creatingNewCustomer) {
        customerName = _newCustomerNameController.text.trim();
        customerPhone = _newCustomerPhoneController.text.trim();

        if (customerName.isEmpty) {
          _showError('Please enter the customer name.');
          return;
        }

        customerId = _getCustomerId(
          customerName,
          customerPhone,
        );
      } else {
        final customer = _selectedCustomer;

        if (customer == null) {
          _showError('Please select a customer.');
          return;
        }

        customerId = customer.id;
        customerName = customer.name;
        customerPhone = customer.phone;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();

    /*
     * One transaction ID is generated here.
     *
     * CASH:
     *   Transaction only.
     *
     * CREDIT:
     *   Same transaction + one CreditEntry.
     */
    final transactionId = now.microsecondsSinceEpoch.toString();

    final transaction = Transaction(
      id: transactionId,
      amount: amount,
      category: _selectedCategory,
      timestamp: now,
      confidence: 100,
      customerName: customerName,
      customerId: _isCredit ? customerId : null,
      isSynced: false,
    );

    try {
      final cacheService = ref.read(cacheServiceProvider);

      // For a credit sale, write the Khata entry first. This prevents a
      // transaction from being recorded without its corresponding Khata
      // entry when the Khata write fails.
      if (_isCredit) {
        final creditEntry = CreditEntry(
          id: 'khata_$transactionId',
          customerId: customerId,
          customerName: customerName,
          customerPhone: customerPhone,
          amount: amount,
          type: 'given',
          date: now,
          notes: 'Credit sale',
          isPaid: false,
        );

        await ref.read(khataEntriesProvider.notifier).addEntry(creditEntry);
      }

      // Save exactly one transaction for every successful sale.
      await cacheService.addTransaction(transaction);

      ref.invalidate(transactionProvider);
      ref.invalidate(todayTransactionsProvider);
      ref.invalidate(weeklyTransactionsProvider);

      if (_isCredit) {
        ref.invalidate(khataEntriesProvider);
      }

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      widget.onSaleComplete();
    } catch (error, stackTrace) {
      debugPrint('QuickSaleDialog: failed to save sale: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        _isCredit
            ? 'Could not save the credit sale. Please try again.'
            : 'Could not save the sale. Please try again.',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _QuickSaleCustomer {
  final String id;
  final String name;
  final String phone;

  const _QuickSaleCustomer({
    required this.id,
    required this.name,
    required this.phone,
  });
}

class _PaymentTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.09)
                : KiranaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? color
                  : KiranaColors.outlineVariant.withValues(
                      alpha: 0.20,
                    ),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: KiranaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: color,
                ),
            ],
          ),
        ),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: isSelected
                ? KiranaColors.secondary
                : KiranaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? KiranaColors.secondary
                  : KiranaColors.outlineVariant.withValues(
                      alpha: 0.25,
                    ),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: KiranaColors.secondary.withValues(
                        alpha: 0.2,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : KiranaColors.primary,
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? KiranaColors.primary
                : KiranaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? KiranaColors.primary
                  : KiranaColors.outlineVariant.withValues(
                      alpha: 0.25,
                    ),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : KiranaColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
