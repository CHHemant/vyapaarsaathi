import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  Timer? _navigationTimer;

  static const paper = Color(0xFFFCF9F2);
  static const ink = Color(0xFF111111);
  static const coral = Color(0xFFDF2E00);

  /// Splash duration before automatically opening the dashboard.
  static const Duration _splashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Automatically continue to the dashboard.
    _navigationTimer = Timer(_splashDuration, _openDashboard);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  /// Opens the main dashboard.
  ///
  /// Authentication is intentionally bypassed for the current
  /// hackathon/demo version. Login and onboarding routes remain
  /// available in the application for future use.
  void _openDashboard() {
    if (!mounted) return;

    context.goNamed('home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _BackgroundPainter(),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (_, __) {
              return CustomPaint(
                painter: _LedgerPainter(_animation.value),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const _Dot(),
                const Spacer(),
                _GoButton(
                  onTap: _openDashboard,
                ),
                const SizedBox(height: 28),
                const _Handle(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFCF9F2),
    );

    final grid = Paint()
      ..color = const Color(0x0A111111)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 32) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        grid,
      );
    }

    for (double y = 0; y <= size.height; y += 32) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        grid,
      );
    }

    final guides = Paint()
      ..color = const Color(0x14111111)
      ..strokeWidth = 1;

    for (final x in [
      size.width * .08,
      size.width * .5,
      size.width * .92,
    ]) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        guides,
      );
    }

    final shader = RadialGradient(
      colors: const [
        Color(0xF2FFFFFF),
        Color(0xCCFCF9F2),
        Color(0xFFF3EFE6),
      ],
    ).createShader(
      Rect.fromCircle(
        center: Offset(
          size.width / 2,
          size.height * .46,
        ),
        radius: size.width * .9,
      ),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LedgerPainter extends CustomPainter {
  const _LedgerPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(
      size.width / 2,
      size.height * .46,
    );

    final r = math.min(
      size.width * .40,
      size.height * .25,
    );

    _circle(
      canvas,
      c,
      r,
      const Color(0x1F111111),
      1,
    );

    _dashCircle(
      canvas,
      c,
      r * .89,
      const Color(0x4D111111),
      1.2,
      2,
      6,
      t,
    );

    _circle(
      canvas,
      c,
      r * .72,
      const Color(0x2E111111),
      1,
    );

    final a = t * math.pi * 2;

    _node(
      canvas,
      c +
          Offset(
            math.cos(a) * r * .72,
            math.sin(a) * r * .72,
          ),
      3,
      _SplashScreenState.ink,
    );

    _node(
      canvas,
      c +
          Offset(
            math.cos(a + math.pi) * r * .72,
            math.sin(a + math.pi) * r * .72,
          ),
      2.5,
      const Color(0x66111111),
    );

    _node(
      canvas,
      c + Offset(0, -r * .72),
      2.2,
      const Color(0x99111111),
    );

    _node(
      canvas,
      c + Offset(0, r * .72),
      2.2,
      const Color(0x80111111),
    );

    _dashCircle(
      canvas,
      c,
      r * .54,
      const Color(0xCC111111),
      1.6,
      6,
      9,
      -t * math.pi * 8,
    );

    final conduit = -math.pi / 2 + a;

    final cp = c +
        Offset(
          math.cos(conduit) * r * .54,
          math.sin(conduit) * r * .54,
        );

    _node(
      canvas,
      cp,
      4,
      _SplashScreenState.ink,
    );

    _node(
      canvas,
      cp,
      1.5,
      _SplashScreenState.paper,
    );

    canvas.save();

    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * math.pi * 4);

    _dashEllipse(
      canvas,
      Size(
        r * .88,
        r * .34,
      ),
    );

    canvas.restore();

    final ep = c +
        Offset(
          math.cos(t * math.pi * 4) * r * .44,
          math.sin(t * math.pi * 4) * r * .17,
        );

    _node(
      canvas,
      ep,
      2.75,
      _SplashScreenState.coral,
    );

    final cross = Paint()
      ..color = const Color(0x38111111)
      ..strokeWidth = 1;

    _dashLine(
      canvas,
      Offset(
        c.dx,
        c.dy - r * .42,
      ),
      Offset(
        c.dx,
        c.dy + r * .42,
      ),
      cross,
    );

    _dashLine(
      canvas,
      Offset(
        c.dx - r * .42,
        c.dy,
      ),
      Offset(
        c.dx + r * .42,
        c.dy,
      ),
      cross,
    );

    final pulse = .97 + .06 * ((math.sin(a) + 1) / 2);

    canvas.save();

    canvas.translate(
      c.dx,
      c.dy,
    );

    canvas.scale(pulse);

    canvas.rotate(math.pi / 4);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: r * .105,
        height: r * .105,
      ),
      Paint()..color = _SplashScreenState.ink,
    );

    canvas.restore();

    canvas.drawCircle(
      c,
      r * .015,
      Paint()..color = _SplashScreenState.paper,
    );
  }

  void _circle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double width,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _dashCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double width,
    double dash,
    double gap,
    double phase,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final path = Path();

    final step = (dash + gap) / radius;

    for (double angle = phase; angle < math.pi * 2 + phase; angle += step) {
      path.addArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        angle,
        math.min(
          dash / radius,
          step * .72,
        ),
      );
    }

    canvas.drawPath(
      path,
      paint,
    );
  }

  void _dashEllipse(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0x52111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.width,
      height: size.height,
    );

    for (int i = 0; i < 26; i++) {
      canvas.drawArc(
        rect,
        i / 26 * math.pi * 2,
        .055,
        false,
        paint,
      );
    }
  }

  void _dashLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final difference = end - start;
    final length = difference.distance;

    if (length == 0) return;

    final direction = difference / length;

    for (double x = 0; x < length; x += 6) {
      canvas.drawLine(
        start + direction * x,
        start +
            direction *
                math.min(
                  x + 2,
                  length,
                ),
        paint,
      );
    }
  }

  void _node(
    Canvas canvas,
    Offset position,
    double radius,
    Color color,
  ) {
    canvas.drawCircle(
      position,
      radius,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LedgerPainter oldDelegate,
  ) {
    return oldDelegate.t != t;
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x55111111),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0x24111111),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _GoButton extends StatefulWidget {
  const _GoButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_GoButton> createState() => _GoButtonState();
}

class _GoButtonState extends State<_GoButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap();
      },
      child: AnimatedScale(
        scale: pressed ? .95 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x1F111111),
                blurRadius: 18,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
