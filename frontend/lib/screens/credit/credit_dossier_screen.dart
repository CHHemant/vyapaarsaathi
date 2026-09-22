// lib/screens/credit/credit_dossier_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/kirana_colors.dart';

class CreditDossierScreen extends ConsumerWidget {
  const CreditDossierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Column(
          children: [
            Text('CREDIT DOSSIER',
                style: GoogleFonts.bebasNeue(fontSize: 20, letterSpacing: 1.0)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: KiranaColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(100)),
              child: Text('• RBI AA LICENSED PROTOCOL',
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
              _buildInstitutionalRibbon(),
              const SizedBox(height: 16),
              _buildScoreSlip(),
              const SizedBox(height: 24),
              _buildUnderwritingLedger(),
              const SizedBox(height: 24),
              _buildArbitrageBanner(),
              const SizedBox(height: 24),
              _buildSanctionedOffers(),
              const SizedBox(height: 24),
              _buildOfficeProofStream(),
              const SizedBox(height: 100),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionDock(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionalRibbon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: KiranaColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                      radius: 3,
                      backgroundColor: KiranaColors.secondaryContainer),
                  const SizedBox(width: 8),
                  Text('RBI AA LICENSED PROTOCOL',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: KiranaColors.secondary,
                          letterSpacing: 1.0)),
                ],
              ),
              Text('NODE: SLM-ON-DEVICE-HYD',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 8, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.storefront_rounded, size: 16),
                const SizedBox(width: 8),
                Text('RAMESH STORE (LAAD BAZAAR)',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.bold))
              ]),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: KiranaColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(100)),
                  child: const Text('GSTIN EXEMPT',
                      style:
                          TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSlip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AUDIT REGISTER 2024-Q3',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black38,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('CREDIT DOSSIER',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 32, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: KiranaColors.tertiaryFixed,
                    borderRadius: BorderRadius.circular(4)),
                child: Row(children: [
                  const Icon(Icons.gavel_rounded, size: 14),
                  const SizedBox(width: 6),
                  Text('GRADE A+ PRIME',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.bold))
                ]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('84',
                          style:
                              GoogleFonts.bebasNeue(fontSize: 64, height: 1.0)),
                      Text('/100',
                          style: GoogleFonts.bebasNeue(
                              fontSize: 24, color: Colors.black26)),
                    ],
                  ),
                  Text('INFORMAL CREDIT SCORE',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: KiranaColors.secondary,
                          letterSpacing: 1.0)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: KiranaColors.bg,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Image.network(
                        'https://api.qrserver.com/v1/create-qr-code/?size=60x60&data=CREDIT-DOSSIER-RAMESH',
                        width: 44,
                        height: 44,
                        color: Colors.black),
                    const SizedBox(height: 4),
                    Text('SHA256: 9e3f..b7',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: Colors.black38)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniFeature(Icons.memory_rounded, 'PHI-3 MINI SLM'),
              const SizedBox(width: 8),
              _buildMiniFeature(Icons.shield_rounded, 'ZERO ITR REQUIRED'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFeature(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: KiranaColors.bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderwritingLedger() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('UNDERWRITING LEDGER',
                style: GoogleFonts.bebasNeue(fontSize: 20, letterSpacing: 1.0)),
            Text('LOCAL MODEL VERIFIED',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38)),
          ],
        ),
        const SizedBox(height: 12),
        _buildFactorCard('01', 'TRANSACTION CONSISTENCY', '40% WT',
            '30-Day Daily Variance: <11.4%', 'Median Daily Vol: ₹3,420', 92),
        _buildFactorCard('02', 'CUSTOMER DIVERSITY', '25% WT',
            '148 Unique VPAs', '42 Cash Recurring Patrons', 85),
      ],
    );
  }

  Widget _buildFactorCard(String num, String title, String weight, String line1,
      String line2, int score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                      radius: 12,
                      backgroundColor: KiranaColors.bg,
                      child: Text(num,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black))),
                  const SizedBox(width: 8),
                  Text(title,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: KiranaColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(weight,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 8, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line1,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.6))),
                  Text(line2,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.6))),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$score',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 28, color: KiranaColors.secondary)),
                  Text('/100',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 14, color: Colors.black12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: score / 100,
              backgroundColor: KiranaColors.bg,
              color: KiranaColors.secondary,
              borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }

  Widget _buildArbitrageBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: KiranaColors.secondaryContainer,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.savings_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text('INFORMAL ARBITRAGE',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 1.2))
              ]),
              const SizedBox(height: 4),
              Text('SAVING ₹14,200/YEAR',
                  style:
                      GoogleFonts.bebasNeue(fontSize: 24, color: Colors.white)),
              Text('Bank APR 14.2% replaces 48% local debt.',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text('SAVINGS',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.secondary)),
              Text('70%',
                  style:
                      GoogleFonts.bebasNeue(fontSize: 24, color: Colors.black))
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSanctionedOffers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SANCTIONED CREDIT LINES',
                style: GoogleFonts.bebasNeue(fontSize: 20, letterSpacing: 1.0)),
            const Text('2 INSTANT OFFERS',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.secondary)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
              ]),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: KiranaColors.tertiaryFixed,
                                borderRadius: BorderRadius.circular(100)),
                            child: Text('PRIME PRE-SANCTION',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        const Text('ZERO COLLATERAL',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black38))
                      ]),
                      const SizedBox(height: 8),
                      Text('STATE BANK OF INDIA (SBI)',
                          style: GoogleFonts.bebasNeue(fontSize: 24)),
                      Text('PRADHAN MANTRI MUDRA SISHU',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 9, color: Colors.black45)),
                    ],
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('LIMIT',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 8, color: Colors.black45)),
                    Text('₹50,000',
                        style: GoogleFonts.bebasNeue(
                            fontSize: 32, color: KiranaColors.secondary))
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: KiranaColors.bg,
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FinanceCol('INTEREST', '14.2% p.a.'),
                      _FinanceCol('TENURE', '12 MONTHS'),
                      _FinanceCol('MONTHLY EMI', '₹4,495/mo', isHighlight: true)
                    ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfficeProofStream() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: KiranaColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.phonelink_rounded, size: 20),
                const SizedBox(width: 8),
                Text('OFFICE KIT P2P PROOF STREAM',
                    style: GoogleFonts.bebasNeue(fontSize: 18))
              ]),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: KiranaColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(100)),
                  child: const Text('READY',
                      style:
                          TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
              'Present this code to transmit the tamper-proof cryptographic ledger with zero Internet.',
              style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('P2P STREAM PAIRING TOKEN',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 8, color: Colors.black45)),
                  Text('7749 - 2810 - WY',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2))
                ]),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: KiranaColors.bg,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.content_copy_rounded, size: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionDock(BuildContext context) {
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
              child: const Icon(Icons.print_rounded)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                  color: KiranaColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                        color: KiranaColors.secondaryContainer
                            .withValues(alpha: 0.2),
                        blurRadius: 10)
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('DISBURSE TO SBI',
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

class _FinanceCol extends StatelessWidget {
  final String label;
  final String val;
  final bool isHighlight;
  const _FinanceCol(this.label, this.val, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 8, color: Colors.black45, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(val,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isHighlight ? KiranaColors.secondary : Colors.black))
    ]);
  }
}
