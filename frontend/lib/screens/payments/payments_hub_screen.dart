import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/kirana_colors.dart';

class PaymentsHubScreen extends StatelessWidget {
  const PaymentsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      appBar: AppBar(
        title: Text(
          'PAYMENTS',
          style: GoogleFonts.bebasNeue(
            fontSize: 26,
            color: KiranaColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _hero(),
            const SizedBox(height: 20),
            _sectionTitle('COLLECT MONEY', '3 ACTIONS'),
            const SizedBox(height: 10),
            _actionCard(
              context,
              icon: Icons.link_rounded,
              title: 'REQUEST A PAYMENT',
              subtitle: 'Create a UPI payment request',
              color: KiranaColors.secondaryContainer,
              iconColor: KiranaColors.onSecondaryContainer,
              onTap: () => context.pushNamed('payment_link'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _smallAction(
                    context,
                    icon: Icons.qr_code_2_rounded,
                    title: 'QR & VPA',
                    subtitle: 'Show QR',
                    color: KiranaColors.tertiaryContainer,
                    iconColor: KiranaColors.onTertiaryContainer,
                    onTap: () => context.pushNamed('vpa_qr'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallAction(
                    context,
                    icon: Icons.history_rounded,
                    title: 'PAYMENT LOG',
                    subtitle: 'View records',
                    color: KiranaColors.surfaceContainer,
                    iconColor: KiranaColors.primary,
                    onTap: () => context.pushNamed('payment_log'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('YOUR COLLECTION SETUP', 'LOCAL & READY'),
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.pushNamed('vpa_qr'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KiranaColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          KiranaColors.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: KiranaColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR QR & UPI',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 21,
                                color: KiranaColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Manage your VPA, generate an amount QR and open a UPI app.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: KiranaColors.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: KiranaColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _infoCard(),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: KiranaColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COLLECT',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'GET PAID\nWITHOUT THE FRICTION.',
            style: GoogleFonts.bebasNeue(
              fontSize: 34,
              height: 0.95,
              color: Colors.white,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a payment request, show your QR, or review money already recorded in VyapaarSaathi.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white70,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String meta) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.bebasNeue(
              fontSize: 20,
              color: KiranaColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Text(
          meta,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 21,
                        color: iconColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: iconColor.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: iconColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 128,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 18,
                        color: iconColor,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        color: iconColor.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.phone_android_rounded,
            color: KiranaColors.tertiary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payment actions use the UPI URI and Android apps already available on your device. No fake payment confirmation is shown.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: KiranaColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
