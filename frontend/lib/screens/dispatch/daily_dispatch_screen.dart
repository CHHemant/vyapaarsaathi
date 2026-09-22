// lib/screens/dispatch/daily_dispatch_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/kirana_colors.dart';

class DailyDispatchScreen extends ConsumerWidget {
  const DailyDispatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Column(
          children: [
            Text('BILL GENERATOR',
                style: GoogleFonts.bebasNeue(fontSize: 20, letterSpacing: 1.0)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: KiranaColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(100)),
              child: Text('• NIC EWB PORTAL • GSTN 2.0 SYNCED',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0)),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTelemetryStrip(),
              const SizedBox(height: 16),
              _buildHeroDispatchCard(),
              const SizedBox(height: 24),
              _buildDossierSectionHeader(),
              const SizedBox(height: 12),
              _buildSalesDossier(),
              const SizedBox(height: 12),
              _buildCreditDossier(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildBentoDossier(
                          '03. KHATA UDHAAR', '₹2,400', '3 parties')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildBentoDossier(
                          '04. GSTN / TAX EXEMPT', 'COMPOSITE', 'Day-Sheet')),
                ],
              ),
              const SizedBox(height: 24),
              _buildAutomationControls(),
              const SizedBox(height: 24),
              _buildWhatsappPreview(),
              const SizedBox(height: 120),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: KiranaColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const CircleAvatar(
                    radius: 3,
                    backgroundColor: KiranaColors.secondaryContainer),
                const SizedBox(width: 8),
                Text('NIC & NPCI Encrypted Dispatch',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 1.0))
              ]),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: KiranaColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(100)),
                  child: const Text('STATUS: READY',
                      style:
                          TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 18, color: KiranaColors.secondary),
                  const SizedBox(width: 8),
                  Text('NETWORK WATCHER: OFFLINE QUEUED',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.bold))
                ]),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: KiranaColors.bg,
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('WI-FI / 4G TRIGGER',
                        style: TextStyle(fontSize: 8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroDispatchCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: KiranaColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OFFLINE SLM ENGINE • BAZAAR EDITION',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 8, color: Colors.white54, letterSpacing: 1.5)),
              const Icon(Icons.verified_user_rounded,
                  color: KiranaColors.tertiaryFixed, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text('EOD AUTO-SYNC\nDISPATCH',
              style: GoogleFonts.bebasNeue(
                  fontSize: 32, color: Colors.white, height: 1.0)),
          const SizedBox(height: 8),
          const Text(
              'End-of-day audited ledger and analytics queued locally on NPU. Dispatches automatically on connection.',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 20),
          _buildRecipientPill(
              Icons.chat_rounded, '+91 98480 ••••• (Verified Meta Business)'),
          const SizedBox(height: 8),
          _buildRecipientPill(
              Icons.mail_rounded, 'ramesh.stores.hyd@gmail.com (OAuth 2.0)'),
        ],
      ),
    );
  }

  Widget _buildRecipientPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: KiranaColors.tertiaryFixed),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
          const Icon(Icons.check_circle_rounded,
              size: 14, color: KiranaColors.tertiaryFixed),
        ],
      ),
    );
  }

  Widget _buildDossierSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Text('4 CORE DAILY DOSSIERS',
              style: GoogleFonts.bebasNeue(fontSize: 20)),
          const SizedBox(width: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: KiranaColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(100)),
              child: const Text('READY TO SYNC',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)))
        ]),
        const Text('BUFFER: 420 KB',
            style: TextStyle(
                fontSize: 9,
                color: Colors.black45,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSalesDossier() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
          ]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('01. TOTAL DAILY SALES & CASHFLOW',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.secondary)),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: KiranaColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('+8.6% DoD',
                      style:
                          TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('₹4,850', style: GoogleFonts.bebasNeue(fontSize: 32)),
                Text('NET REVENUE',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38))
              ]),
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('42 TRANSACTIONS',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('Margin: 22.4%',
                        style: TextStyle(fontSize: 9, color: Colors.black38))
                  ]),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _MiniTile('UPI (Soundbox)', '₹3,100')),
              SizedBox(width: 8),
              Expanded(child: _MiniTile('Cash Drawer', '₹1,750')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditDossier() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('02. CREDIT SCORE & LOAN DOSSIER',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.secondary)),
              const Text('PRIME A+',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: KiranaColors.bg, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Bazaar Credit Score',
                      style: TextStyle(fontSize: 10, color: Colors.black45)),
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('84', style: GoogleFonts.bebasNeue(fontSize: 24)),
                        const Text('/ 100',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black26))
                      ])
                ]),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Active Facility',
                          style:
                              TextStyle(fontSize: 10, color: Colors.black45)),
                      Text('SBI Mudra Sishu',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('EMI ₹4,495 Due in 12d',
                          style: TextStyle(
                              fontSize: 10,
                              color: KiranaColors.secondary,
                              fontWeight: FontWeight.bold))
                    ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoDossier(String title, String val, String subtitle) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: KiranaColors.secondary)),
          Text(val, style: GoogleFonts.bebasNeue(fontSize: 24)),
          Text(subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildAutomationControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Smart Reconnect Rules',
              style: GoogleFonts.bebasNeue(fontSize: 20)),
          const Spacer(),
          const Icon(Icons.tune_rounded, size: 20, color: Colors.black45)
        ]),
        const SizedBox(height: 12),
        _buildControlItem('Instant Auto-Send PDF',
            'Auto-compiles encrypted daily ledger statement.',
            isActive: true),
        _buildControlItem(
            'Encrypted PDF to Gmail', 'Lock with Merchant PAN/Phone digits.',
            isChecked: true),
        _buildControlItem(
            'WhatsApp Voice Note Audio', 'AI verbal summary note.',
            isChecked: true),
      ],
    );
  }

  Widget _buildControlItem(String title, String desc,
      {bool isActive = false, bool isChecked = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border(
                  left: BorderSide(
                      color: KiranaColors.secondaryContainer, width: 4))
              : null),
      child: Row(
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: KiranaColors.tertiaryFixed,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('ZERO TOUCH',
                            style: TextStyle(
                                fontSize: 7, fontWeight: FontWeight.bold)))
                  ]
                ]),
                Text(desc,
                    style: const TextStyle(fontSize: 11, color: Colors.black45))
              ])),
          if (isActive)
            const Icon(Icons.check_circle_rounded,
                color: KiranaColors.secondaryContainer, size: 20)
          else
            Checkbox(
                value: isChecked,
                onChanged: (v) {},
                activeColor: KiranaColors.secondary),
        ],
      ),
    );
  }

  Widget _buildWhatsappPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.visibility_outlined, size: 18),
            const SizedBox(width: 8),
            Text('WhatsApp Live Preview',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 13))
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: KiranaColors.bg,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔔 VyapaarSaathi EOD Report — 24 Oct',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: KiranaColors.secondary)),
                const SizedBox(height: 8),
                const Text(
                    'Namaste Ramesh ji, today\'s shop summary:\n💰 Total Sales: ₹4,850\n📈 Credit Score: 84/100\n📄 PDF Statement attached.',
                    style: TextStyle(fontSize: 11, height: 1.4)),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.picture_as_pdf_rounded,
                      color: KiranaColors.secondary, size: 14),
                  const SizedBox(width: 6),
                  const Text('eod_24oct_ledger.pdf',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('310 KB',
                          style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.bold)))
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionDock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
            KiranaColors.bg,
            KiranaColors.bg.withValues(alpha: 0.9),
            Colors.transparent
          ])),
      child: Row(
        children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(100)),
              child: const Icon(Icons.send_rounded, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                  color: KiranaColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SAVE AUTO-DISPATCH RULES',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 20,
                          color: Colors.white,
                          letterSpacing: 1.0)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final String label;
  final String val;
  const _MiniTile(this.label, this.val);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: KiranaColors.bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black45,
                  fontWeight: FontWeight.bold)),
          Text(val,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
