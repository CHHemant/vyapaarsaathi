// frontend/lib/widgets/credit_score_gauge.dart

import 'dart:math' show pi;
import 'package:flutter/material.dart';
import '../models/credit_score.dart';
import '../theme/kirana_colors.dart';

class CreditScoreGauge extends StatefulWidget {
  final int score;
  final Duration animationDuration;
  final double size;

  const CreditScoreGauge({
    super.key,
    required this.score,
    this.animationDuration = const Duration(seconds: 1),
    this.size = 220,
  }) : assert(score >= 0 && score <= 100, 'score must be 0-100');

  @override
  State<CreditScoreGauge> createState() => _CreditScoreGaugeState();
}

class _CreditScoreGaugeState extends State<CreditScoreGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.animationDuration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CreditScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForTier(LoanEligibility tier) => switch (tier) {
        LoanEligibility.low => KiranaColors.error,
        LoanEligibility.medium => KiranaColors.tertiary,
        LoanEligibility.high => KiranaColors.secondary,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = _colorForTier(LoanEligibility.fromScore(widget.score));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedScore = (widget.score * _animation.value).round();
        return SizedBox(
          width: widget.size,
          height: widget.size / 2 + 24,
          child: CustomPaint(
            painter: _GaugePainter(
              sweepFraction: (widget.score / 100) * _animation.value,
              color: tierColor,
              trackColor: theme.colorScheme.onSurface.withOpacity(0.05),
            ),
            child: Align(
              alignment: const Alignment(0, 0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$animatedScore',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: widget.size * 0.07,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double sweepFraction;
  final Color color;
  final Color trackColor;

  const _GaugePainter({
    required this.sweepFraction, 
    required this.color,
    required this.trackColor,
  });

  static const double _strokeWidth = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - (_strokeWidth / 2) - 4);
    final radius = (size.width / 2) - (_strokeWidth / 2) - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, backgroundPaint);

    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi * sweepFraction, false, foregroundPaint);
    
    // Subtle inner shadow effect (simulated)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawArc(rect.deflate(2), pi, pi, false, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.sweepFraction != sweepFraction || oldDelegate.color != color;
  }
}
