import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/kirana_colors.dart';

class PaymentLinkScreen extends StatefulWidget {
  const PaymentLinkScreen({super.key});

  @override
  State<PaymentLinkScreen> createState() => _PaymentLinkScreenState();
}

class _PaymentLinkScreenState extends State<PaymentLinkScreen> {
  static const _merchantVpa = 'vyapaar.ramesh@icici';
  static const _merchantName = 'VyapaarSaathi';

  final _amountController = TextEditingController();
  final _customerController = TextEditingController();
  final _noteController = TextEditingController();

  String _channel = 'UPI';

  @override
  void dispose() {
    _amountController.dispose();
    _customerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  String get _upiUri {
    final amount = _amount;
    final note = _noteController.text.trim();

    final params = <String, String>{
      'pa': _merchantVpa,
      'pn': _merchantName,
      'cu': 'INR',
    };

    if (amount != null && amount > 0) {
      params['am'] = amount.toStringAsFixed(2);
    }
    if (note.isNotEmpty) {
      params['tn'] = note;
    }

    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: params,
    ).toString();
  }

  String get _shareText {
    final customer = _customerController.text.trim();
    final amount = _amount;

    return '''VyapaarSaathi payment request

${customer.isEmpty ? 'Customer' : customer}
${amount != null && amount > 0 ? 'Amount: ₹${amount.toStringAsFixed(2)}\n' : ''}UPI: $_merchantVpa
Payment URI:
$_upiUri''';
  }

  Future<void> _copyUri() async {
    await Clipboard.setData(ClipboardData(text: _upiUri));
    _message('UPI payment link copied.');
  }

  Future<void> _openUpi() async {
    final uri = Uri.parse(_upiUri);

    try {
      final canOpen = await canLaunchUrl(uri);

      if (canOpen) {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (opened) {
          return;
        }
      }

      await Clipboard.setData(
        ClipboardData(text: _upiUri),
      );

      _message(
        'No UPI app is available on this device. The payment link was copied.',
      );
    } catch (e) {
      await Clipboard.setData(
        ClipboardData(text: _upiUri),
      );

      _message(
        'Could not open a UPI app. The payment link was copied.',
      );
    }
  }

  Future<void> _openWhatsApp() async {
    try {
      final opened = await launchUrl(
        Uri.parse(
          'whatsapp://send?text=${Uri.encodeComponent(_shareText)}',
        ),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        await Clipboard.setData(ClipboardData(text: _shareText));
        _message('WhatsApp is unavailable. The message was copied.');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _shareText));
      _message('Could not open WhatsApp. The message was copied.');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setPreset(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    setState(() {});
  }

  void _clear() {
    _amountController.clear();
    _customerController.clear();
    _noteController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;

    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Text(
          'REQUEST PAYMENT',
          style: GoogleFonts.bebasNeue(
            fontSize: 25,
            color: KiranaColors.primary,
            letterSpacing: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _header(),
          const SizedBox(height: 16),
          _card(
            title: 'PAYMENT DETAILS',
            icon: Icons.edit_note_rounded,
            child: Column(
              children: [
                _field(
                  controller: _customerController,
                  label: 'CUSTOMER NAME',
                  hint: 'Optional',
                  icon: Icons.person_outline_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _field(
                  controller: _amountController,
                  label: 'AMOUNT',
                  hint: '0.00',
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final value in [500.0, 1000.0, 5000.0])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: value == 5000 ? 0 : 7,
                          ),
                          child: OutlinedButton(
                            onPressed: () => _setPreset(value),
                            child: Text('₹${value.toStringAsFixed(0)}'),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(
                  controller: _noteController,
                  label: 'NOTE',
                  hint: 'Invoice / purpose',
                  icon: Icons.notes_rounded,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'DELIVERY',
            icon: Icons.send_rounded,
            child: Row(
              children: [
                Expanded(
                    child: _buildChannel('UPI', Icons.account_balance_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _buildChannel('WHATSAPP', Icons.chat_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'PAYMENT PREVIEW',
            icon: Icons.qr_code_2_rounded,
            child: Column(
              children: [
                Container(
                  width: 190,
                  height: 190,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: amount != null && amount > 0
                      ? QrImageView(
                          data: _upiUri,
                          size: 166,
                          backgroundColor: Colors.white,
                        )
                      : const Center(
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 90,
                            color: KiranaColors.outlineVariant,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  amount != null && amount > 0
                      ? '₹${amount.toStringAsFixed(2)}'
                      : 'ENTER AN AMOUNT',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 30,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _merchantVpa,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyUri,
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: const Text('COPY LINK'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openUpi,
                        icon: const Icon(Icons.open_in_new_rounded, size: 17),
                        label: const Text('OPEN UPI'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'SEND REQUEST',
            icon: Icons.send_rounded,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _channel == 'WHATSAPP' ? _openWhatsApp : _openUpi,
                    icon: Icon(
                      _channel == 'WHATSAPP'
                          ? Icons.chat_rounded
                          : Icons.account_balance_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _channel == 'WHATSAPP' ? 'SEND WHATSAPP' : 'OPEN UPI',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear',
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'UPI URI • LOCAL QR • DEVICE APP HAND-OFF',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              color: KiranaColors.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KiranaColors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT REQUEST',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: KiranaColors.onSecondaryContainer.withValues(alpha: 0.72),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ASK FOR MONEY.\nCLEARLY.',
            style: GoogleFonts.bebasNeue(
              fontSize: 35,
              height: 0.95,
              color: KiranaColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter an amount, generate a real UPI URI + QR, then hand it to a UPI app or WhatsApp.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: KiranaColors.onSecondaryContainer.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildChannel(String value, IconData icon) {
    final selected = _channel == value;

    return Material(
      color: selected ? KiranaColors.primary : KiranaColors.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _channel = value),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : KiranaColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : KiranaColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
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
          color: KiranaColors.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: KiranaColors.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.bebasNeue(
                  fontSize: 19,
                  color: KiranaColors.primary,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
