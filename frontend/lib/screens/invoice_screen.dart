// frontend/lib/screens/invoice_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../models/customer.dart';
import '../models/invoice.dart';
import '../providers/core_providers.dart';
import '../services/api_service.dart';
import '../services/office_kit_service.dart';
import '../theme/kirana_colors.dart';
import '../widgets/kirana_card.dart';
import '../widgets/rupee_button.dart';
import '../widgets/entrance_animation.dart';

class _DraftItem {
  final String id;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  GstRate gstRate;

  _DraftItem({
    required this.id,
    String name = '',
    String quantity = '',
    String price = '',
    this.gstRate = GstRate.zero,
  })  : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity),
        priceController = TextEditingController(text: price);

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get unitPrice => double.tryParse(priceController.text) ?? 0;
  double get lineSubtotal => quantity * unitPrice;
  double get lineGst => lineSubtotal * gstRate.percent / 100;

  bool get isValid => nameController.text.trim().isNotEmpty && quantity > 0 && unitPrice > 0;

  InvoiceItem toInvoiceItem() => InvoiceItem(
        id: id,
        name: nameController.text.trim(),
        quantity: quantity,
        unitPrice: unitPrice,
        gstRate: gstRate,
      );

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class InvoiceScreen extends ConsumerStatefulWidget {
  const InvoiceScreen({super.key});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  final List<_DraftItem> _items = [_DraftItem(id: 'item-0')];
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();

  Customer? _selectedCustomer;
  List<Customer> _knownCustomers = [];
  Invoice? _generatedInvoice;
  Uint8List? _pdfBytes;
  bool _isGenerating = false;
  bool _isSending = false;
  bool _isListeningForItem = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _harvestKnownCustomers();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _customerSearchController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _harvestKnownCustomers() async {
    final cache = ref.read(cacheServiceProvider);
    final cached = cache.getCachedTransactions().data;
    final seen = <String, Customer>{};
    for (final t in cached) {
      if (t.customerId != null && t.customerName != null) {
        seen[t.customerId!] = Customer(id: t.customerId!, name: t.customerName!, phoneHash: '');
      }
    }
    if (mounted) setState(() => _knownCustomers = seen.values.toList());
  }

  void _addBlankItem() {
    setState(() => _items.add(_DraftItem(id: 'item-${DateTime.now().millisecondsSinceEpoch}')));
  }

  void _removeItem(_DraftItem item) {
    setState(() {
      _items.remove(item);
      item.dispose();
    });
  }

  Future<void> _addItemByVoice() async {
    setState(() => _isListeningForItem = true);
    try {
      final voice = ref.read(voiceServiceProvider);
      final parsed = await voice.listenForInvoiceItem();
      final draft = _DraftItem(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        name: parsed.name ?? '',
        quantity: parsed.quantity?.toString() ?? '',
        price: parsed.unitPrice?.toString() ?? '',
      );
      setState(() => _items.add(draft));
      if (!parsed.isComplete && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't catch everything — please check the new row.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isListeningForItem = false);
    }
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.lineSubtotal);
  double get _gstTotal => _items.fold(0, (s, i) => s + i.lineGst);
  double get _grandTotal => _subtotal + _gstTotal;

  Future<void> _generateBill() async {
    final validItems = _items.where((i) => i.isValid).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one complete item (name, quantity, price).')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    
    // Simulate API call and PDF generation
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _generatedInvoice = Invoice(
          customerId: _selectedCustomer?.id,
          customerName: _selectedCustomer?.name ?? 'Guest',
          items: validItems.map((i) => i.toInvoiceItem()).toList(),
          pdfPath: 'INV-${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        // We simulate having the PDF bytes for preview
        _pdfBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]); // Mock PDF bytes
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice generated!'),
          backgroundColor: KiranaColors.success,
        ),
      );
    }
  }

  Future<void> _sendViaOfficeKit() async {
    if (_pdfBytes == null) return;

    setState(() => _isSending = true);
    final officeKit = ref.read(officeKitServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/invoice.pdf');
      await file.writeAsBytes(_pdfBytes!);
      
      final result = await officeKit.transferFile(file.path);
      switch (result) {
        case OfficeKitSuccess():
          messenger.showSnackBar(const SnackBar(content: Text('Invoice sent to laptop!')));
        case OfficeKitFailure(:final reason):
          messenger.showSnackBar(SnackBar(content: Text(reason)));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('GST Invoice')),
      body: _generatedInvoice != null && _pdfBytes != null ? _buildPdfPreview() : _buildComposer(),
    );
  }

  Widget _buildComposer() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.surface, theme.colorScheme.surface.withOpacity(0.5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EntranceAnimation(
            delay: const Duration(milliseconds: 100),
            child: KiranaCard(
              elevation: 8,
              padding: const EdgeInsets.all(24),
              child: _CustomerSection(
                searchController: _customerSearchController,
                phoneController: _customerPhoneController,
                knownCustomers: _knownCustomers,
                selectedCustomer: _selectedCustomer,
                onCustomerSelected: (c) => setState(() => _selectedCustomer = c),
                onNewCustomer: () => setState(() => _selectedCustomer = null),
              ),
            ),
          ),
          const SizedBox(height: 32),
          EntranceAnimation(
            delay: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Text('Line Items', style: theme.textTheme.titleLarge),
                const Spacer(),
                _IconButtonPremium(
                  icon: Icons.mic_rounded,
                  color: KiranaColors.primary,
                  onTap: _isListeningForItem ? null : _addItemByVoice,
                  isLoading: _isListeningForItem,
                ),
                const SizedBox(width: 12),
                _IconButtonPremium(
                  icon: Icons.add_rounded,
                  color: KiranaColors.secondary,
                  onTap: _addBlankItem,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _items.length,
            (index) => EntranceAnimation(
              delay: Duration(milliseconds: 300 + (index * 50)),
              child: _ItemRow(
                key: ValueKey(_items[index].id),
                item: _items[index],
                onChanged: () => setState(() {}),
                onRemove: _items.length > 1 ? () => _removeItem(_items[index]) : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          EntranceAnimation(
            delay: Duration(milliseconds: 400 + (_items.length * 50)),
            child: KiranaCard(
              color: KiranaColors.primary.withOpacity(0.05),
              borderColor: KiranaColors.primary.withOpacity(0.1),
              child: Column(
                children: [
                  _SummaryRow(label: 'Net Amount', amount: _subtotal),
                  _SummaryRow(label: 'Total GST', amount: _gstTotal),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _SummaryRow(label: 'Grand Total', amount: _grandTotal, isBold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          EntranceAnimation(
            delay: Duration(milliseconds: 500 + (_items.length * 50)),
            child: RupeeButton(
              label: 'Generate Digital Bill',
              icon: Icons.auto_awesome_rounded,
              showRupeePrefix: false,
              fullWidth: true,
              isLoading: _isGenerating || _isDownloading,
              onPressed: _generateBill,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Column(
      children: [
        Expanded(
          child: _pdfBytes != null && _pdfBytes!.length > 10 
            ? SfPdfViewer.memory(_pdfBytes!)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description, size: 64, color: KiranaColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Invoice Preview Generated',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Ready to send via Office Kit'),
                  ],
                ),
              ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _generatedInvoice = null;
                      _pdfBytes = null;
                    }),
                    child: const Text('Back to Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RupeeButton(
                    label: 'Send via Office Kit',
                    icon: Icons.send,
                    showRupeePrefix: false,
                    isLoading: _isSending,
                    onPressed: _sendViaOfficeKit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IconButtonPremium extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _IconButtonPremium({
    required this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController phoneController;
  final List<Customer> knownCustomers;
  final Customer? selectedCustomer;
  final ValueChanged<Customer> onCustomerSelected;
  final VoidCallback onNewCustomer;

  const _CustomerSection({
    required this.searchController,
    required this.phoneController,
    required this.knownCustomers,
    required this.selectedCustomer,
    required this.onCustomerSelected,
    required this.onNewCustomer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<Customer>(
          displayStringForOption: (c) => c.name,
          optionsBuilder: (value) {
            if (value.text.isEmpty) return const Iterable<Customer>.empty();
            return knownCustomers.where((c) => c.name.toLowerCase().contains(value.text.toLowerCase()));
          },
          onSelected: onCustomerSelected,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Customer name (optional)',
                border: const OutlineInputBorder(),
                suffixIcon: selectedCustomer == null
                    ? null
                    : IconButton(icon: const Icon(Icons.close), onPressed: () {
                        controller.clear();
                        onNewCustomer();
                      }),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Customer phone (for GST record)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final _DraftItem item;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _ItemRow({super.key, required this.item, required this.onChanged, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: KiranaCard(
        padding: const EdgeInsets.all(12),
        elevation: 1,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: item.nameController,
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Item Name', isDense: true),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: KiranaColors.error),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: item.quantityController,
                    onChanged: (_) => onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: item.priceController,
                    onChanged: (_) => onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '₹/each', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<GstRate>(
                    initialValue: item.gstRate,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'GST', isDense: true),
                    items: GstRate.values.map((r) => DropdownMenuItem(value: r, child: Text('${r.percent}%'))).toList(),
                    onChanged: (r) {
                      if (r != null) {
                        item.gstRate = r;
                        onChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const _SummaryRow({required this.label, required this.amount, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
      fontSize: isBold ? 20 : 16,
      color: theme.colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: style.copyWith(
              fontFamily: 'Quicksand',
              color: theme.colorScheme.onSurface.withOpacity(isBold ? 1.0 : 0.7),
            ),
          ),
          Text('₹${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
