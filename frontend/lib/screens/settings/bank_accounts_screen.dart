// lib/screens/settings/bank_accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/kirana_colors.dart';

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Column(
          children: [
            Text('BANK ACCOUNTS',
                style: GoogleFonts.bebasNeue(fontSize: 20, letterSpacing: 1.0)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: KiranaColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(100)),
              child: Text('• RBI AA CONNECTED • NPCI RECON',
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
              _buildHeroHeader(),
              _buildNavTabs(),
              _buildPrimaryAccountCard(),
              _buildOtherAccountsSection(),
              _buildAaBento(),
              _buildSettlementRules(),
              _buildComplianceFooter(),
              const SizedBox(height: 100),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildFloatingDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const CircleAvatar(
              radius: 3, backgroundColor: KiranaColors.secondary),
          const SizedBox(width: 8),
          Text('MULTI-CURRENT A/C ROUTING',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0))
        ]),
        const SizedBox(height: 8),
        Text('LINKED BANKS',
            style: GoogleFonts.anton(
                fontSize: 52, height: 0.9, letterSpacing: -1.0)),
        Text('& SETTLEMENT',
            style: GoogleFonts.anton(
                fontSize: 52,
                height: 0.9,
                color: KiranaColors.secondary,
                letterSpacing: -1.0)),
        Text('ROUTING',
            style: GoogleFonts.anton(
                fontSize: 52, height: 0.9, letterSpacing: -1.0)),
      ],
    );
  }

  Widget _buildNavTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabPill('Active Accounts (3)', isActive: true),
            _buildTabPill('VPA / UPI Handles'),
            _buildTabPill('Mandates & e-NACH'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String label, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.black12)),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildPrimaryAccountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: KiranaColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(100)),
                  child: const Row(children: [
                    CircleAvatar(
                        radius: 2, backgroundColor: Colors.greenAccent),
                    SizedBox(width: 6),
                    Text('PRIMARY AUTO-SETTLE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold))
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('PENNY DROP VERIFIED',
                      style:
                          TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('HDFC Bank',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Smart Commercial Current Account',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withValues(alpha: 0.6)))
              ]),
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                      child: Text('HDFC',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white30, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildAccRow('Account No:', '•••• •••• 4092'),
                _buildAccRow('IFSC Code:', 'HDFC0000060'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Auto-sweep Party Collections',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text('Instant RTGS/IMPS transfer',
                    style: TextStyle(fontSize: 9, color: Colors.black54))
              ]),
              Switch(
                  value: true,
                  onChanged: (v) {},
                  activeThumbColor: Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccRow(String label, String val) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.black45)),
          Text(val,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, fontWeight: FontWeight.bold))
        ]));
  }

  Widget _buildOtherAccountsSection() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SECONDARY LINKED ACCOUNTS',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45)),
          const Text('2 OF 5 SLOTS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: KiranaColors.secondary))
        ]),
        const SizedBox(height: 12),
        _buildSecondaryCard('ICICI Bank — Business OD', 'A/C: ••••••••8819',
            'Utilized: ₹5,10,000 (34%)'),
        const SizedBox(height: 10),
        _buildSecondaryCard('State Bank of India (SBI)', 'A/C: ••••••••1044',
            'GSTR-3B LIQUIDITY RESERVE'),
      ],
    );
  }

  Widget _buildSecondaryCard(String title, String subtitle, String info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: KiranaColors.bg,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance_rounded, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black45)),
                const SizedBox(height: 4),
                Text(info,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: KiranaColors.secondary))
              ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildAaBento() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Column(
        children: [
          Row(children: [
            Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6)),
                child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 12)))),
            const SizedBox(width: 8),
            const Text('1-CLICK FAST LINK VIA RBI AA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
          ]),
          const SizedBox(height: 12),
          const Text(
              'Fetch and verify all GST-linked current accounts instantly via RBI-regulated Account Aggregators.',
              style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAaStep('01. OTP', 'Aadhaar'),
              Container(width: 1, height: 20, color: Colors.black12),
              _buildAaStep('02. VERIFY', 'Penny Drop'),
              Container(width: 1, height: 20, color: Colors.black12),
              _buildAaStep('03. READY', 'Instant'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAaStep(String t1, String t2) {
    return Column(children: [
      Text(t1,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: KiranaColors.secondary)),
      Text(t2,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
    ]);
  }

  Widget _buildSettlementRules() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INSTANT SETTLEMENT PREFERENCES',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black54)),
          const SizedBox(height: 16),
          _buildRuleRow('Real-time UPI Instant Credit',
              'Zero delay, direct credit', true),
          _buildRuleRow('Smart Hold for GST Debits',
              'Auto-diverts 18% of invoices', true),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String title, String sub, bool val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(sub,
                style: const TextStyle(fontSize: 10, color: Colors.black45))
          ]),
          Switch(value: val, onChanged: (v) {}, activeThumbColor: Colors.black),
        ],
      ),
    );
  }

  Widget _buildComplianceFooter() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
          '✓ 100% RBI AA LICENSED • HARDWARE ENCLAVE ENCRYPTED\nZERO PLAIN-TEXT BANK PASSWORDS STORED',
          style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black26),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildFloatingDock() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: KiranaColors.primary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ]),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              height: 48,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_rounded,
                        color: Colors.white, size: 16),
                    Text('SYNC',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold))
                  ])),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                  color: KiranaColors.secondary,
                  borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('+',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('LINK NEW BANK ACCOUNT',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
