// lib/screens/payments/standee_export_modal.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/kirana_colors.dart';

class StandeeExportModal extends StatefulWidget {
  const StandeeExportModal({super.key});

  @override
  State<StandeeExportModal> createState() => _StandeeExportModalState();
}

class _StandeeExportModalState extends State<StandeeExportModal> {
  bool _printGstin = true;
  bool _addSoundboxBarcode = true;
  bool _dynamicGstPayload = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1B1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: KiranaColors.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeadline(),
                    _buildFormatTabs(),
                    _buildStandeePreview(),
                    _buildCustomizationOptions(),
                    _buildPrintSpecs(),
                    _buildDeliveryBanner(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomDock(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 20, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFE3DFC8))),
            child: Row(
              children: [
                const CircleAvatar(
                    radius: 4, backgroundColor: Color(0xFF00A86B)),
                const SizedBox(width: 8),
                Text('NPCI 300 DPI • VECTOR READY',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.black,
            child: const Icon(Icons.more_vert_rounded,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('●',
                style: TextStyle(color: KiranaColors.secondary, fontSize: 12)),
            const SizedBox(width: 8),
            Text('BHIM UPI 2.0 • HIGH-DENSITY VECTOR STAMP',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        Text('OFFICIAL STANDEE',
            style: GoogleFonts.oswald(
                fontSize: 34, height: 0.9, fontWeight: FontWeight.bold)),
        Text('& QR KIT EXPORT',
            style: GoogleFonts.oswald(
                fontSize: 34,
                height: 0.9,
                fontWeight: FontWeight.bold,
                color: KiranaColors.secondary)),
        const SizedBox(height: 8),
        Text(
            'Merchant asset package configured for retail counters, cash desks & direct print production.',
            style:
                GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _buildFormatTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          _buildTab('Counter Standee (A5)', isActive: true),
          _buildTab('Wall Poster (A4)'),
          _buildTab('Stickers Pack'),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFDDD8CB))),
      child: Text(label,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildStandeePreview() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Center(
                              child: Text('VS',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 8),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OFFICIAL MERCHANT KIT',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8, color: Colors.black45)),
                            Text('Vyapaar Logistics & POS',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))
                          ]),
                    ],
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('GSTIN VERIFIED',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 8, fontWeight: FontWeight.bold))),
                    Text('27AABCS1429B1Z8',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 8, color: Colors.black45))
                  ]),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                      color: KiranaColors.secondary,
                      borderRadius: BorderRadius.circular(100)),
                  child: Text('SCAN & PAY WITH ANY UPI APP',
                      style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(16)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                        'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=vyapaar.logistics@hdfcbank'),
                    Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: KiranaColors.secondary,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Center(
                            child: Text('V',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('vyapaar.logistics@hdfcbank',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('GPay',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('PhonePe',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Paytm',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('BHIM',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))
                  ]),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('NPCI BHIM UPI 2.0 ZERO MDR',
                    style: GoogleFonts.jetBrainsMono(fontSize: 8)),
                Text('T+0 AUTO KHATA RECON',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800))
              ]),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black26),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFDCD7CD)]),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationOptions() {
    return Column(
      children: [
        _buildOptionSection('1. Standee Visual Theme', [
          _buildThemeOption('Classic Editorial', 'High legibility',
              isActive: true),
          _buildThemeOption('Minimal Clean', 'Monochrome'),
          _buildThemeOption('Bilingual Hindi', 'दुकान क्यूआर'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: KiranaColors.tertiaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: KiranaColors.tertiaryContainer)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('2. Embedded Data Flags',
                  style: GoogleFonts.oswald(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildToggleRow(
                  'Print GSTIN & Legal Trade Name',
                  'Required for Input Tax Credit claims',
                  _printGstin,
                  (v) => setState(() => _printGstin = v)),
              _buildToggleRow(
                  'Add Soundbox Sync Barcode',
                  'Allows zero-click audio broadcast pairing',
                  _addSoundboxBarcode,
                  (v) => setState(() => _addSoundboxBarcode = v)),
              _buildToggleRow(
                  'Dynamic GST Invoice Payload',
                  'Auto-routes to Counter POS bill generator',
                  _dynamicGstPayload,
                  (v) => setState(() => _dynamicGstPayload = v)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE1DDCF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.oswald(
                  fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
              children: children
                  .map((c) => Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: c)))
                  .toList()),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, String subtitle,
      {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: isActive ? Colors.black12 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.black : Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.oswald(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          Text(subtitle,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 8, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, color: Colors.black54))
              ])),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.black),
        ],
      ),
    );
  }

  Widget _buildPrintSpecs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE1DDCF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRODUCTION SPECS',
              style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSpecItem('Dimensions', 'A5 (148x210)'),
              _buildSpecItem('Color Space', 'CMYK FOGRA39'),
              _buildSpecItem('Resolution', '300 DPI Vector', isHighlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value,
      {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: Colors.black45,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? KiranaColors.secondary : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildDeliveryBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.black, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXPRESS DISPATCH',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: KiranaColors.secondary,
                      fontWeight: FontWeight.bold)),
              Text('Order Hard Acrylic Standee',
                  style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text('Delivered in 48h to Mumbai Hub',
                  style: GoogleFonts.jetBrainsMono(
                      color: Colors.white54, fontSize: 9)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('₹299',
                  style: TextStyle(
                      color: Colors.white24,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 10)),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFF00E599).withValues(alpha: 0.1),
                      border: Border.all(
                          color:
                              const Color(0xFF00E599).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('FREE',
                      style: TextStyle(
                          color: Color(0xFF00E599),
                          fontWeight: FontWeight.bold,
                          fontSize: 11))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: KiranaColors.bg.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: Color(0xFFE1DDCF)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFDDD8CB)),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.share_rounded)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: KiranaColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color:
                                KiranaColors.secondary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Center(
                      child: Text('Download Print PDF (300 DPI)',
                          style: GoogleFonts.oswald(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('NPCI BHIM UPI 2.0 OFFICIAL SPEC • LOSSLESS CMYK VECTOR',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: Colors.black45,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
