import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color paper = Color(0xFFEFE0C3);
  static const Color ink = Color(0xFF1C1712);
  static const Color marigold = Color(0xFFF2A900);
  static const Color teal = Color(0xFF2E7D6B);
  static const Color tealDark = Color(0xFF1F5A4C);
  static const Color red = Color(0xFFD6402C);
  static const Color redDark = Color(0xFFA72E1E);
  static const Color skin = Color(0xFFC98455);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Red Grid Background
          Container(
            color: red,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPainter(),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 26),
                  Text(
                    'OFFLINE-FIRST\nVOICE-FIRST',
                    style: GoogleFonts.quicksand(
                      color: paper.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.kaushanScript(
                        fontSize: 48,
                        height: 1.1,
                        color: paper,
                      ),
                      children: [
                        const TextSpan(text: 'Aapka\nVyapaar\n'),
                        TextSpan(
                          text: 'Saathi',
                          style: TextStyle(color: marigold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Logo Row
                  Row(
                    children: [
                      CustomPaint(
                        size: const Size(20, 20),
                        painter: _GemPainter(),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'VYAPAARSAATHI',
                        style: GoogleFonts.quicksand(
                          color: paper,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // CTA Button
                  GestureDetector(
                    onTap: () => context.goNamed('home'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: marigold,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ink, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: ink,
                            offset: Offset(6, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Shuru Karein',
                          style: GoogleFonts.quicksand(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Shopkeeper Illustration (Bleeding off-edge)
          Positioned(
            right: -40,
            bottom: 120,
            child: SizedBox(
              width: 300,
              height: 430,
              child: CustomPaint(
                painter: _ShopkeeperPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.5;

    const double step = 10.0;

    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height * 0.4)
      ..close();

    canvas.drawPath(path, Paint()..color = SplashScreen.marigold);
    canvas.drawPath(
      path,
      Paint()
        ..color = SplashScreen.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShopkeeperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Drawing a simplified version of the SVG shopkeeper
    final inkPaint = Paint()..color = SplashScreen.ink..style = PaintingStyle.stroke..strokeWidth = 4;
    final skinPaint = Paint()..color = SplashScreen.skin;
    final tealPaint = Paint()..color = SplashScreen.teal;
    final redDarkPaint = Paint()..color = SplashScreen.redDark;

    // Apron/Body
    final bodyPath = Path()
      ..moveTo(70, 220)
      ..quadraticBezierTo(70, 160, 150, 150)
      ..quadraticBezierTo(230, 160, 230, 220)
      ..lineTo(246, 400)
      ..quadraticBezierTo(150, 430, 54, 400)
      ..close();
    canvas.drawPath(bodyPath, tealPaint);
    canvas.drawPath(bodyPath, inkPaint);

    // Head
    canvas.drawCircle(const Offset(150, 95), 52, skinPaint);
    canvas.drawCircle(const Offset(150, 95), 52, inkPaint);

    // Cap
    final capPath = Path()
      ..moveTo(96, 78)
      ..quadraticBezierTo(100, 28, 150, 26)
      ..quadraticBezierTo(200, 28, 204, 78)
      ..quadraticBezierTo(150, 62, 96, 78)
      ..close();
    canvas.drawPath(capPath, redDarkPaint);
    canvas.drawPath(capPath, inkPaint);

    // Mustache
    final mustachePath = Path()
      ..moveTo(118, 120)
      ..quadraticBezierTo(150, 138, 182, 120)
      ..quadraticBezierTo(168, 132, 150, 130)
      ..quadraticBezierTo(132, 132, 118, 120)
      ..close();
    canvas.drawPath(mustachePath, Paint()..color = SplashScreen.ink);

    // Eyes
    canvas.drawCircle(const Offset(130, 98), 4.5, Paint()..color = SplashScreen.ink);
    canvas.drawCircle(const Offset(172, 98), 4.5, Paint()..color = SplashScreen.ink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
