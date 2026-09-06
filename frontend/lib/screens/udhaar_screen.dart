// frontend/lib/screens/udhaar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/credit_entry.dart';
import '../services/credit_service.dart';
import '../theme/kirana_colors.dart';
import '../widgets/kirana_card.dart';
import '../widgets/rupee_button.dart';
import '../widgets/entrance_animation.dart';

class UdhaarScreen extends ConsumerStatefulWidget {
  const UdhaarScreen({super.key});

  @override
  ConsumerState<UdhaarScreen> createState() => _UdhaarScreenState();
}

class _UdhaarScreenState extends ConsumerState<UdhaarScreen> {
  final CreditService _creditService = CreditService();
  List<CreditEntry> _entries = [];
  bool _isLoading = true;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _creditService.initialize();
    final entries = await _creditService.getAllEntries();
    final summary = await _creditService.getSummary();
    setState(() {
      _entries = entries;
      _summary = summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Udhaar (Credit)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEntryDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Summary Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: EntranceAnimation(
            delay: const Duration(milliseconds: 100),
            child: _buildSummaryCard(),
          ),
        ),

        // Entries List
        Expanded(
          child: _entries.isEmpty
              ? EntranceAnimation(
                  delay: const Duration(milliseconds: 200),
                  child: _buildEmptyState(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) => EntranceAnimation(
                    delay: Duration(milliseconds: 200 + (index * 50)),
                    child: _buildEntryTile(_entries[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);
    return KiranaCard(
      color: theme.brightness == Brightness.light ? KiranaColors.ink : KiranaColors.surfaceDark,
      borderColor: Colors.white10,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'You Gave',
                  amount: _summary?['totalGiven'] ?? 0,
                  color: KiranaColors.secondary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white10,
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'You Took',
                  amount: _summary?['totalTaken'] ?? 0,
                  color: KiranaColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: KiranaColors.tertiary, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Net Balance: ₹${(_summary?['netCredit'] ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double amount,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: theme.colorScheme.onPrimary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No credit entries yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add udhaar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(CreditEntry entry) {
    final theme = Theme.of(context);
    final isGiven = entry.type == 'given';
    final accentColor = isGiven ? KiranaColors.secondary : KiranaColors.error;

    return KiranaCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: accentColor.withOpacity(0.2),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: accentColor.withOpacity(0.1),
          child: Icon(
            isGiven ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: accentColor,
            size: 18,
          ),
        ),
        title: Text(
          entry.customerName,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          DateFormat('dd MMM, hh:mm a').format(entry.date),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '₹${entry.amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: accentColor,
          ),
        ),
        onTap: () => _showEntryDetails(entry),
      ),
    );
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEntryDialog(
        onAdd: (entry) async {
          await _creditService.addEntry(entry);
          await _loadData();
        },
      ),
    );
  }

  void _showEntryDetails(CreditEntry entry) {
    showDialog(
      context: context,
      builder: (context) => _EntryDetailsDialog(
        entry: entry,
        onMarkPaid: () async {
          await _creditService.markAsPaid(entry.id);
          await _loadData();
        },
        onDelete: () async {
          await _creditService.deleteEntry(entry.id);
          await _loadData();
        },
      ),
    );
  }
}

class _AddEntryDialog extends StatefulWidget {
  final Function(CreditEntry) onAdd;

  const _AddEntryDialog({required this.onAdd});

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'given';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Udhaar'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'given', label: Text('You Gave')),
                  ButtonSegment(value: 'taken', label: Text('You Took')),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> selected) {
                  setState(() => _type = selected.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final entry = CreditEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                customerId: DateTime.now().millisecondsSinceEpoch.toString(),
                customerName: _nameController.text,
                customerPhone: _phoneController.text,
                amount: double.parse(_amountController.text),
                type: _type,
                date: DateTime.now(),
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
              );
              widget.onAdd(entry);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _EntryDetailsDialog extends StatelessWidget {
  final CreditEntry entry;
  final VoidCallback onMarkPaid;
  final VoidCallback onDelete;

  const _EntryDetailsDialog({
    required this.entry,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(entry.customerName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phone: ${entry.customerPhone}'),
          const SizedBox(height: 8),
          Text(
            'Amount: ₹${entry.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text('Date: ${DateFormat('dd MMM yyyy').format(entry.date)}'),
          if (entry.notes != null) ...[
            const SizedBox(height: 8),
            Text('Notes: ${entry.notes}'),
          ],
        ],
      ),
      actions: [
        if (!entry.isPaid)
          FilledButton(
            onPressed: () {
              onMarkPaid();
              Navigator.pop(context);
            },
            child: const Text('Mark Paid'),
          ),
        TextButton(
          onPressed: () {
            onDelete();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}