// lib/screens/hardware/office_kit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/kirana_colors.dart';

class OfficeKitScreen extends ConsumerStatefulWidget {
  const OfficeKitScreen({super.key});

  @override
  ConsumerState<OfficeKitScreen> createState() => _OfficeKitScreenState();
}

class _OfficeKitScreenState extends ConsumerState<OfficeKitScreen> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Column(
          children: [
            Text('OFFICE KIT',
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
              _buildTelemetryBar(),
              const SizedBox(height: 16),
              _buildHeroHeadline(),
              const SizedBox(height: 24),
              _buildTabs(),
              const SizedBox(height: 24),
              _buildActiveTabContent(),
              const SizedBox(height: 24),
              _buildDiscoveredNodes(),
              const SizedBox(height: 24),
              _buildTopologyBanner(),
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

  Widget _buildTelemetryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: KiranaColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: KiranaColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(100)),
                  child: const Text('LOCAL LAN P2P • ZERO CLOUD LATENCY',
                      style:
                          TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
              Row(children: [
                _buildSignalChip(Icons.wifi_tethering_rounded, 'WIFI-D'),
                const SizedBox(width: 6),
                _buildSignalChip(Icons.bluetooth_rounded, 'BLE 5.3')
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NODE: VYAPAAR-COUNTER-01 (192.168.1.142)',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 8, color: Colors.black45)),
              const Text('PORT 9100 / 8080 OPEN',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: KiranaColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100)),
      child: Row(children: [
        Icon(icon, size: 10),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))
      ]),
    );
  }

  Widget _buildHeroHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OFFICE KIT &',
            style: GoogleFonts.bebasNeue(
                fontSize: 32, color: KiranaColors.primary, letterSpacing: 1.0)),
        Text('SCREEN MIRROR',
            style: GoogleFonts.bebasNeue(
                fontSize: 48,
                color: KiranaColors.secondaryContainer,
                height: 0.9)),
        const SizedBox(height: 8),
        Text(
            'Stream real-time checkout & invoice displays to customer counter tablets and thermal POS printers.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: KiranaColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: KiranaColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildTab(0, 'Customer Mirror', isActive: _activeTabIndex == 0),
          _buildTab(1, 'POS Printer', isActive: _activeTabIndex == 1),
          _buildTab(2, 'P2P Drop', isActive: _activeTabIndex == 2),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, {bool isActive = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4)
                    ]
                  : null),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.black45)),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: KiranaColors.tertiaryFixed,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: KiranaColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(100)),
                  child: const Row(children: [
                    CircleAvatar(
                        radius: 3, backgroundColor: Colors.greenAccent),
                    SizedBox(width: 6),
                    Text('STREAM ACTIVE #01',
                        style:
                            TextStyle(fontSize: 9, fontWeight: FontWeight.bold))
                  ])),
              const Text('SAMSUNG TAB A9 (COUNTER 1)',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.storefront_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('SHREE GANESH WHOLESALE',
                            style: GoogleFonts.bebasNeue(fontSize: 14))
                      ]),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: KiranaColors.bg,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('#8942',
                              style: TextStyle(
                                  fontSize: 8, fontWeight: FontWeight.bold)))
                    ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Live Customer Total',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.black45)),
                          Text('₹1,85,400',
                              style: GoogleFonts.bebasNeue(
                                  fontSize: 28, color: KiranaColors.secondary))
                        ]),
                    Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: KiranaColors.bg,
                            borderRadius: BorderRadius.circular(4)),
                        child: Image.network(
                            'https://api.qrserver.com/v1/create-qr-code/?size=60x60&data=VYAPAAR',
                            width: 32,
                            height: 32)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _MiniStat('Latency', '14 MS'),
              SizedBox(width: 8),
              _MiniStat('Frame Rate', '60 FPS'),
              SizedBox(width: 8),
              _MiniStat('Encryption', 'WPA3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredNodes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LOCAL HARDWARE PERIPHERALS',
                style: GoogleFonts.bebasNeue(fontSize: 18)),
            const Text('2 FOUND READY',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.secondary)),
          ],
        ),
        const SizedBox(height: 12),
        _buildDeviceCard(
            'Epson TM-T82X Receipt Printer',
            'ESC/POS • IP: 192.168.1.88:9100',
            'PAIRED & ONLINE',
            Icons.print_rounded),
        _buildDeviceCard(
            'Storefront Secondary Phone',
            'Wi-Fi Direct Peer • 5.0 GHz',
            'READY TO CAST',
            Icons.phone_iphone_rounded,
            isSecondary: true),
      ],
    );
  }

  Widget _buildDeviceCard(
      String title, String meta, String status, IconData icon,
      {bool isSecondary = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: KiranaColors.bg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(meta,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.black45)),
                Row(children: [
                  const CircleAvatar(radius: 2, backgroundColor: Colors.green),
                  const SizedBox(width: 6),
                  Text(status,
                      style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.green))
                ])
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: isSecondary
                      ? KiranaColors.secondaryContainer
                      : KiranaColors.bg,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(isSecondary ? 'CAST' : 'TEST',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildTopologyBanner() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
            image: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBJnqcDPa_oHERp86PiQHCLlS2N02YwImMOVUmTfXO0N6dgy5_ftZx6ZSLnki4m88Cj-JwF1eyTXfjGYTjsjahZ6CJymnEtYa4drfOdqOeCHbTnrWWih_eNU4RDF_tuOPDDQbmm8SOntuEWB1grTVVwdwlhC8aovsBNcK3o-fCfhqxXBif8o0kijL_xIPISiYyssZSoimC7Bi_Pgo4N9AWxFtGSqml7oNyNy5zcMwUZU0buQDxISdhQeQ'),
            fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8)
                ])),
        padding: const EdgeInsets.all(16),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HARDWARE TOPOLOGY',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
              Text('Counter Mesh Sync Active',
                  style:
                      GoogleFonts.bebasNeue(color: Colors.white, fontSize: 20))
            ]),
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
              child: const Icon(Icons.add_rounded)),
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
                  Text('START P2P STREAM',
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String val;
  const _MiniStat(this.label, this.val);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45)),
          Text(val, style: GoogleFonts.bebasNeue(fontSize: 16))
        ]),
      ),
    );
  }
}
