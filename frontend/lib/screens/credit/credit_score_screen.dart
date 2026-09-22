// lib/screens/credit/credit_score_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/kirana_colors.dart';

class CreditScoreScreen extends ConsumerWidget {
  const CreditScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroTitle(),
                      _buildCategoryPills(),
                      _buildScoreGaugeCard(),
                      _buildPreApprovedCard(),
                      _buildUnderwritingVectors(),
                      _buildComplianceBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: KiranaColors.bg,
      leadingWidth: 0,
      titleSpacing: 16,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VYAPAAR\nSAATHI',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: KiranaColors.onSurface,
                      height: 1.0)),
              Text('ON-DEVICE SLM CREDIT & OCEN PROTOCOL',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      color: Colors.black45,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                backgroundColor: KiranaColors.primary,
                child: Icon(Icons.menu_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTitle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'CREDIT\nSCORE\nCAPITAL',
        style: GoogleFonts.anton(
            fontSize: 66, height: 0.84, color: KiranaColors.primary),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPill('Score Breakdown', isActive: true),
          _buildPill('Loan Eligibility'),
          _buildPill('Credit Report'),
          _buildPill('Consent & AA'),
        ],
      ),
    );
  }

  Widget _buildPill(String label, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? KiranaColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        border:
            Border.all(color: isActive ? KiranaColors.primary : Colors.black12),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : KiranaColors.primary),
      ),
    );
  }

  Widget _buildScoreGaugeCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KiranaColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ON-DEVICE AI SCORING • PHI-3 SLM',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.black54)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(100)),
                  child: Row(children: [
                    const CircleAvatar(
                        radius: 2, backgroundColor: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text('ACTIVE SYNC',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 8, fontWeight: FontWeight.bold))
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MSME COMPOSITE INDEX',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.black45,
                              letterSpacing: 1.0)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('785',
                              style: GoogleFonts.anton(
                                  fontSize: 68, color: KiranaColors.primary)),
                          Text('/900',
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black38)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: KiranaColors.primary,
                            borderRadius: BorderRadius.circular(100)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text('TOP 5% MSME TIER',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: 0.87,
                        strokeWidth: 10,
                        backgroundColor: Colors.black12,
                        color: KiranaColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      children: [
                        Text('CIBIL EQ',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black45)),
                        Text('EXCELLENT',
                            style: GoogleFonts.anton(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GST Reconciled: 99.2%',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, fontWeight: FontWeight.bold)),
                const CircleAvatar(radius: 2, backgroundColor: Colors.black26),
                Text('Zero Bounce Record',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, fontWeight: FontWeight.bold)),
                const CircleAvatar(radius: 2, backgroundColor: Colors.black26),
                Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 12),
                  const SizedBox(width: 4),
                  Text('AA Verified',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w900))
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreApprovedCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: KiranaColors.secondary,
            borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(100)),
                    child: Text('COLLATERAL-FREE WORKING CAPITAL',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0))),
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text('₹10,00,000\nSANCTIONED',
                style: GoogleFonts.anton(
                    fontSize: 38, height: 0.9, color: Colors.white)),
            const SizedBox(height: 12),
            Text(
                'Instant drawdown against unpaid GST invoices via OCEN protocol. Zero branch visit required.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFinanceMetric('Interest', '8.9% p.a.'),
                const SizedBox(width: 6),
                _buildFinanceMetric('Tenure', '12–36 M'),
                const SizedBox(width: 6),
                _buildFinanceMetric('Disbursal', '3 Mins'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: KiranaColors.primary,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CLAIM SANCTION NOW',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        Text('OCEN-ID: #DL-MSME-9942',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, color: Colors.white38))
                      ]),
                  const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_forward_rounded,
                          color: KiranaColors.primary, size: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceMetric(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12)),
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold)),
            Text(val,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderwritingVectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UNDERWRITING VECTORS',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: KiranaColors.primary,
                      letterSpacing: 1.2)),
              Text('3 OF 3 VERIFIED',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: KiranaColors.primary,
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('AA METRICS',
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.bold)),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(100)),
                              child: const Text('GRADE A+',
                                  style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                      Text('CASHFLOW\nVELOCITY',
                          style: GoogleFonts.anton(
                              fontSize: 20, color: Colors.white, height: 1.0)),
                      Text('₹4.8L Avg Mo. Inflow',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 9, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TAX COMPLIANCE',
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8,
                                  color: Colors.black38,
                                  fontWeight: FontWeight.bold)),
                          const CircleAvatar(
                              radius: 3, backgroundColor: Colors.green),
                        ],
                      ),
                      Text('GST & E-WAY\nCONSISTENCY',
                          style: GoogleFonts.anton(fontSize: 20, height: 1.0)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('GSTR-1 Reco',
                                    style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                                Text('100%',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold))
                              ]),
                          const SizedBox(height: 4),
                          Container(
                              height: 2,
                              width: double.infinity,
                              color: Colors.black12,
                              child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 1.0,
                                  child: Container(color: Colors.black))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompText('POWERED BY OCEN'),
          const Text('•', style: TextStyle(color: KiranaColors.secondary)),
          _buildCompText('RBI LICENSED AA'),
          const Text('•', style: TextStyle(color: KiranaColors.secondary)),
          _buildCompText('NPCI RECONCILED'),
        ],
      ),
    );
  }

  Widget _buildCompText(String label) {
    return Text(label,
        style: GoogleFonts.jetBrainsMono(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: Colors.black45,
            letterSpacing: 1.0));
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: KiranaColors.primary,
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('APPLY NEW LOAN',
                      style: GoogleFonts.anton(
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 1.0)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: KiranaColors.secondary, size: 20),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: Colors.white54, size: 20),
                  const SizedBox(width: 16),
                  const Icon(Icons.bookmark_border_rounded,
                      color: Colors.white54, size: 20),
                  const SizedBox(width: 16),
                  Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          border: Border.all(color: Colors.white24),
                          shape: BoxShape.circle),
                      child: const Center(
                          child: Text('M',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
              width: 100,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}
