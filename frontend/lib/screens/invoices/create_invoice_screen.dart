import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/invoice.dart';
import '../../providers/invoices/invoice_provider.dart';
import '../../theme/kirana_colors.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _customerNameController = TextEditingController();
  final _gstinController = TextEditingController();

  bool _autoEway = true;
  bool _isSaving = false;

  final List<InvoiceItem> _items = [];

  @override
  void dispose() {
    _customerNameController.dispose();
    _gstinController.dispose();

    super.dispose();
  }

  double get _subtotal {
    return _items.fold(
      0,
      (sum, item) => sum + item.lineSubtotal,
    );
  }

  double get _gstTotal {
    return _items.fold(
      0,
      (sum, item) => sum + item.lineGst,
    );
  }

  double get _grandTotal {
    return _subtotal + _gstTotal;
  }

  Future<void> _addItem() async {
    final item = await showModalBottomSheet<InvoiceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddInvoiceItemSheet(),
    );

    if (item != null && mounted) {
      setState(() {
        _items.add(item);
      });
    }
  }

  Future<void> _deleteItem(int index) async {
    final item = _items[index];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete item?'),
          content: Text(
            'Remove "${item.name}" from this invoice?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  Future<void> _generateInvoice() async {
    if (_isSaving) return;

    final customerName = _customerNameController.text.trim();
    final gstin = _gstinController.text.trim().toUpperCase();

    if (customerName.isEmpty) {
      _showMessage(
        'Please enter the customer / buyer name.',
      );
      return;
    }

    if (_items.isEmpty) {
      _showMessage(
        'Please add at least one invoice item.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();

    final invoiceNumber =
        'VS-${now.year}-${now.microsecondsSinceEpoch % 100000000}';

    final invoice = Invoice(
      storageId: invoiceNumber,
      invoiceNumber: invoiceNumber,
      customerId: gstin.isEmpty ? null : gstin,
      customerName: customerName,
      items: List<InvoiceItem>.unmodifiable(_items),
      createdAt: now,
    );

    try {
      await ref.read(invoiceProvider.notifier).saveInvoice(invoice);

      if (!mounted) return;

      context.pushReplacementNamed(
        'invoice_preview',
        extra: invoice.storageId,
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Could not save invoice: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'BILL GENERATOR',
              style: GoogleFonts.bebasNeue(
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            Text(
              'CREATE • REVIEW • COLLECT',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              120,
            ),
            children: [
              _introCard(),
              const SizedBox(height: 14),
              _buyerCard(),
              const SizedBox(height: 14),
              _itemsCard(),
              const SizedBox(height: 14),
              _totalsCard(),
              const SizedBox(height: 14),
              _ewayCard(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _introCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEW B2B INVOICE',
            style: GoogleFonts.bebasNeue(
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Create a fresh invoice for each customer. '
            'GST and totals are calculated from the items you add.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _chip(
                'B2B REGULAR',
                active: true,
              ),
              _chip('GST AUTO-CALC'),
              _chip('OFFLINE READY'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String text, {
    bool active = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active ? KiranaColors.primary : KiranaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : KiranaColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buyerCard() {
    return _section(
      title: 'BUYER DETAILS',
      icon: Icons.business_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _customerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Customer / Buyer Name',
              hintText: 'e.g. Bharat Agro Traders',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gstinController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[A-Za-z0-9]'),
              ),
              LengthLimitingTextInputFormatter(15),
            ],
            decoration: const InputDecoration(
              labelText: 'Customer GSTIN',
              hintText: 'Optional',
              prefixIcon: Icon(
                Icons.verified_outlined,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _info(
                  'PLACE OF SUPPLY',
                  '27 - Maharashtra',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _info(
                  'TAX TYPE',
                  'CGST + SGST',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _itemsCard() {
    return _section(
      title: 'INVOICE ITEMS',
      icon: Icons.receipt_long_rounded,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _addItem,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text('ADD ITEM'),
            ),
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: KiranaColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No items added yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap ADD ITEM to add products or services.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      color: KiranaColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < _items.length; i++) ...[
              _itemRow(
                _items[i],
                i,
              ),
              if (i != _items.length - 1) const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }

  Widget _itemRow(
    InvoiceItem item,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: KiranaColors.surfaceContainerHigh,
            child: Text(
              '${index + 1}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatQuantity(item.quantity)} × '
                  '₹${item.unitPrice.toStringAsFixed(2)}'
                  ' • GST ${item.gstRate.percent}%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.lineTotal.toStringAsFixed(2)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: 'Delete item',
                visualDensity: VisualDensity.compact,
                onPressed: _isSaving ? null : () => _deleteItem(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalsCard() {
    return _section(
      title: 'TAX & TOTAL',
      icon: Icons.calculate_rounded,
      child: Column(
        children: [
          _totalRow(
            'Taxable value',
            _subtotal,
          ),
          _totalRow(
            'GST',
            _gstTotal,
          ),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NET PAYABLE',
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                ),
              ),
              Text(
                '₹${_grandTotal.toStringAsFixed(2)}',
                style: GoogleFonts.bebasNeue(
                  fontSize: 27,
                  color: KiranaColors.secondaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    double value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ewayCard() {
    return _section(
      title: 'E-WAY BILL',
      icon: Icons.local_shipping_rounded,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-generate e-Way Bill',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Enable when the shipment requires it.',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoEway,
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _autoEway = value;
                    });
                  },
            activeThumbColor: KiranaColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: KiranaColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        14,
      ),
      decoration: BoxDecoration(
        color: KiranaColors.bg,
        border: const Border(
          top: BorderSide(
            color: Colors.black12,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _generateInvoice,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.receipt_long_rounded,
                ),
          label: Text(
            _isSaving ? 'SAVING…' : 'REVIEW INVOICE',
            style: GoogleFonts.bebasNeue(
              fontSize: 18,
            ),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
          ),
        ),
      ),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(2);
  }
}

class _AddInvoiceItemSheet extends StatefulWidget {
  const _AddInvoiceItemSheet();

  @override
  State<_AddInvoiceItemSheet> createState() => _AddInvoiceItemSheetState();
}

class _AddInvoiceItemSheetState extends State<_AddInvoiceItemSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  GstRate _gstRate = GstRate.eighteen;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();

    final quantity = double.tryParse(
      _quantityController.text.trim(),
    );

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    if (name.isEmpty) {
      _message('Enter an item or service name.');
      return;
    }

    if (quantity == null || quantity <= 0) {
      _message('Enter a valid quantity.');
      return;
    }

    if (price == null || price < 0) {
      _message('Enter a valid price.');
      return;
    }

    Navigator.pop(
      context,
      InvoiceItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        quantity: quantity,
        unitPrice: price,
        gstRate: _gstRate,
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(
          context,
        ).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ADD INVOICE ITEM',
                style: GoogleFonts.bebasNeue(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Item / service name',
                  prefixIcon: Icon(
                    Icons.inventory_2_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(
                          Icons.numbers_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Unit price',
                        prefixIcon: Icon(
                          Icons.currency_rupee_rounded,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<GstRate>(
                initialValue: _gstRate,
                decoration: const InputDecoration(
                  labelText: 'GST rate',
                  prefixIcon: Icon(
                    Icons.percent_rounded,
                  ),
                ),
                items: GstRate.values
                    .map(
                      (rate) => DropdownMenuItem<GstRate>(
                        value: rate,
                        child: Text(
                          '${rate.percent}% GST',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gstRate = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(
                    Icons.add_rounded,
                  ),
                  label: const Text(
                    'ADD ITEM',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
