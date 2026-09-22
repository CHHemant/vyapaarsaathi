import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/kirana_colors.dart';

class VpaQrScreen extends StatefulWidget {
  const VpaQrScreen({super.key});

  @override
  State<VpaQrScreen> createState() => _VpaQrScreenState();
}

class _VpaQrScreenState extends State<VpaQrScreen> {
  static const _vpa = 'vyapaar.ramesh@icici';
  static const _merchantName = 'VyapaarSaathi';

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _includeAmount = true;

  double? get _amount => double.tryParse(_amountController.text.trim());

  String get _upiUri {
    final params = <String, String>{
      'pa': _vpa,
      'pn': _merchantName,
      'cu': 'INR',
    };

    final amount = _amount;
    final note = _noteController.text.trim();

    if (_includeAmount && amount != null && amount > 0) {
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

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    _message(message);
  }

  Future<void> _openUpi() async {
    try {
      final opened = await launchUrl(
        Uri.parse(_upiUri),
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        await Clipboard.setData(ClipboardData(text: _upiUri));
        _message('No UPI app opened. Payment link copied.');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _upiUri));
      _message('Could not open UPI. Payment link copied.');
    }
  }

  Future<void> _whatsapp() async {
    final amount = _amount;
    final text = '''VyapaarSaathi UPI payment

UPI: $_vpa
${amount != null && amount > 0 ? 'Amount: ₹${amount.toStringAsFixed(2)}\n' : ''}${_noteController.text.trim().isNotEmpty ? 'Note: ${_noteController.text.trim()}\n' : ''}
Payment URI:
$_upiUri''';

    try {
      final opened = await launchUrl(
        Uri.parse(
          'whatsapp://send?text=${Uri.encodeComponent(text)}',
        ),
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        await Clipboard.setData(ClipboardData(text: text));
        _message('WhatsApp unavailable. Message copied.');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      _message('Could not open WhatsApp. Message copied.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void _reset() {
    _amountController.clear();
    _noteController.clear();
    setState(() => _includeAmount = true);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;

    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Text(
          'QR & UPI',
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
          _vpaCard(),
          const SizedBox(height: 12),
          _qrCard(amount),
          const SizedBox(height: 12),
          _actions(),
          const SizedBox(height: 12),
          _options(),
          const SizedBox(height: 16),
          Text(
            'UPI HANDLE • QR GENERATED ON DEVICE',
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
        color: KiranaColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: KiranaColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR UPI COLLECTION',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: KiranaColors.onTertiaryContainer,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'SHOW. SCAN. PAY.',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 27,
                    color: KiranaColors.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vpaCard() {
    return _card(
      title: 'UPI HANDLE',
      icon: Icons.alternate_email_rounded,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _vpa,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: KiranaColors.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy VPA',
            onPressed: () => _copy(_vpa, 'VPA copied.'),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }

  Widget _qrCard(double? amount) {
    return _card(
      title: 'PAYMENT QR',
      icon: Icons.qr_code_rounded,
      child: Column(
        children: [
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: _upiUri,
              size: 196,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amount != null && amount > 0 && _includeAmount
                ? '₹${amount.toStringAsFixed(2)}'
                : 'ANY AMOUNT',
            style: GoogleFonts.bebasNeue(
              fontSize: 29,
              color: KiranaColors.primary,
            ),
          ),
          Text(
            _includeAmount
                ? 'QR contains the entered amount when provided.'
                : 'Customer enters the amount in their UPI app.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return _card(
      title: 'ACTIONS',
      icon: Icons.touch_app_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copy(_upiUri, 'UPI payment link copied.'),
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _whatsapp,
              icon: const Icon(Icons.chat_rounded, size: 17),
              label: const Text('SEND ON WHATSAPP'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _options() {
    return _card(
      title: 'QR OPTIONS',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'INCLUDE AMOUNT',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              'Turn off for a reusable open-amount QR.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
            value: _includeAmount,
            onChanged: (value) => setState(() => _includeAmount = value),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'AMOUNT',
              hintText: 'Optional',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: _noteController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'NOTE',
              hintText: 'Optional payment note',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('RESET'),
            ),
          ),
        ],
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
