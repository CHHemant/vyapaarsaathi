// lib/screens/dashboard/heatmap_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/kirana_colors.dart';

class HeatmapScreen extends ConsumerWidget {
  const HeatmapScreen({super.key});

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
                      _buildHeroHeadline(),
                      _buildSubNavPills(),
                      _buildHeatmapBentoCard(),
                      _buildSelectedDayDetail(),
                      _buildRiskAlertCard(),
                      _buildUpcomingEvents(),
                      _buildTrustMarker(),
                    ],
                  ),
                ),
              ),
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

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: KiranaColors.bg,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VYAPAAR\nSAATHI',
                  style: GoogleFonts.bebasNeue(
                      fontSize: 20, color: KiranaColors.primary, height: 0.9)),
              Text('CASHFLOW RADAR • NIC & GST RECON',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45)),
            ],
          ),
          Row(
            children: [
              CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Colors.black),
                      onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 8),
              const CircleAvatar(
                  backgroundColor: KiranaColors.primary,
                  child: Stack(alignment: Alignment.center, children: [
                    Icon(Icons.analytics_outlined,
                        color: Colors.white, size: 20),
                    Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                            radius: 3, backgroundColor: KiranaColors.secondary))
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeadline() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CASHFLOW',
              style: GoogleFonts.bebasNeue(
                  fontSize: 58, height: 0.88, color: KiranaColors.primary)),
          Text('HEATMAP &',
              style: GoogleFonts.bebasNeue(
                  fontSize: 58, height: 0.88, color: KiranaColors.secondary)),
          Text('FORECAST',
              style: GoogleFonts.bebasNeue(
                  fontSize: 58, height: 0.88, color: KiranaColors.primary)),
        ],
      ),
    );
  }

  Widget _buildSubNavPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPill('Cash In/Out', isActive: true),
          _buildPill('GST Outflows'),
          _buildPill('Supplier Due Dates'),
        ],
      ),
    );
  }

  Widget _buildPill(String label, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: isActive ? KiranaColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: isActive ? KiranaColors.primary : Colors.black12)),
      child: Row(
        children: [
          if (isActive) ...[
            const CircleAvatar(
                radius: 3, backgroundColor: KiranaColors.secondary),
            const SizedBox(width: 8)
          ],
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildHeatmapBentoCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: KiranaColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF8DAF9F))),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('OCTOBER 2024 • DAILY LIQUIDITY DENSITY',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54)),
                  Text('Rolling Inflow vs Commitments',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))
                ]),
                const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black,
                    child: Text('✱',
                        style: TextStyle(color: Colors.white, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetric('Exp. Inflows', '₹8,42,500'),
                  _buildMetric('Tax & Debits', '₹3,18,200'),
                  _buildMetric('Net Projected', '+₹5,24,300',
                      isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Simulated Heatmap Matrix
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(31, (index) => _buildHeatCell(index + 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String val, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: Colors.black45)),
        const SizedBox(height: 2),
        Text(val,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.green.shade900 : Colors.black)),
      ],
    );
  }

  Widget _buildHeatCell(int day) {
    Color color = Colors.green.shade100;
    if (day % 7 == 0) color = KiranaColors.secondary;
    if (day % 5 == 0) color = Colors.green.shade800;
    if (day == 24) {
      return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: Center(
              child: Text('$day',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))));
    }
    return Container(
        width: 38,
        height: 38,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Center(
            child: Text('$day',
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold))));
  }

  Widget _buildSelectedDayDetail() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#DAY-RECON • THU, 24 OCT 2024',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          color: Colors.black38,
                          fontWeight: FontWeight.bold)),
                  Text('Realized Daily Ledger',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14))
                ]),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(100)),
                    child: Text('SURPLUS (+₹2,26,500)',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800))),
              ],
            ),
            const SizedBox(height: 16),
            _buildTransRow('Shree Ganesh Logistics', '+₹3,45,000', true),
            const SizedBox(height: 8),
            _buildTransRow(
                'Vendor 27AAACR (Raw Materials)', '-₹1,18,500', false),
          ],
        ),
      ),
    );
  }

  Widget _buildTransRow(String title, String amount, bool isIn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: isIn ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(
                  isIn
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: isIn ? Colors.green : Colors.red)),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
        ]),
        Text(amount,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isIn ? Colors.green.shade800 : Colors.red.shade800)),
      ],
    );
  }

  Widget _buildRiskAlertCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: KiranaColors.secondary,
            borderRadius: BorderRadius.circular(28)),
        child: Column(
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
                    child: const Text('RUNWAY ALERT • 4 DAYS REMAINING',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold))),
                const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Text('✱',
                        style: TextStyle(
                            color: KiranaColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 12),
            Text('Upcoming GST & Vendor Runway Warning',
                style:
                    GoogleFonts.bebasNeue(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 4),
            const Text(
                '₹1,84,000 due on Oct 28. Cash runway projected at ₹3,40,300 post-payment with zero buffer breach.',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('UPCOMING SCHEDULED DEBITS',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const Text('2 OF 9',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 12),
          _buildEvent('OCT 28', 'GSTR-3B Auto Tax Debit', '₹76,400', 'FUNDED'),
          const SizedBox(height: 8),
          _buildEvent(
              'NOV 02', 'Bulk Cement Order Payout', '₹1,50,000', 'ACTION REQ.',
              isPending: true),
        ],
      ),
    );
  }

  Widget _buildEvent(String date, String title, String amount, String status,
      {bool isPending = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: KiranaColors.bg,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(date,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              Text(amount,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: Colors.black45,
                      fontWeight: FontWeight.bold))
            ])
          ]),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color:
                      isPending ? Colors.amber.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6)),
              child: Text(status,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isPending
                          ? Colors.amber.shade800
                          : Colors.green.shade800))),
        ],
      ),
    );
  }

  Widget _buildTrustMarker() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text('POWERED BY AA ACCOUNT AGGREGATOR • RBI LICENSED',
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38)),
            Text('ON-DEVICE ENCLAVE ENCRYPTED • ZERO CLOUD EXPOSURE',
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38)),
          ],
        ),
      ),
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
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                  color: KiranaColors.secondary,
                  borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('SIMULATE RUNWAY',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                  const SizedBox(width: 8),
                  const Text('→', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Row(children: [
            Icon(Icons.search_rounded, color: Colors.white54, size: 20),
            SizedBox(width: 16),
            Icon(Icons.bookmark_border_rounded, color: Colors.white54, size: 20)
          ]),
          const SizedBox(width: 12),
          Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: Colors.white10, shape: BoxShape.circle),
              child: const Center(
                  child: Text('VS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)))),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
