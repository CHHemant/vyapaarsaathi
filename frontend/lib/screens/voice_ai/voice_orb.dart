import 'dart:math' as math;

import 'package:flutter/material.dart';

enum VoiceOrbState {
  idle,
  listening,
  thinking,
  success,
  error,
}

class VoiceOrb extends StatefulWidget {
  final VoiceOrbState state;
  final double size;
  final VoidCallback? onTap;

  const VoiceOrb({
    super.key,
    required this.state,
    this.size = 300,
    this.onTap,
  });

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  Offset _pointer = Offset.zero;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final random = math.Random(42);
    _particles = List.generate(1200, (index) {
      final y = 1 - (2 * index / 1199);
      final radius = math.sqrt(math.max(0, 1 - y * y));
      final theta = math.pi * (3 - math.sqrt(5)) * index;

      return _Particle(
        x: radius * math.cos(theta),
        y: y,
        z: radius * math.sin(theta),
        accent: random.nextDouble(),
        phase: random.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: (details) {
        setState(() {
          _pointer += details.delta;
          _pointer = Offset(
            _pointer.dx.clamp(-90, 90),
            _pointer.dy.clamp(-90, 90),
          );
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _VoiceOrbPainter(
                particles: _particles,
                progress: _controller.value,
                pointer: _pointer,
                state: widget.state,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VoiceOrbPainter extends CustomPainter {
  static const _carbon = Color(0xFF111111);
  static const _vermilion = Color(0xFFE84E1B);
  static const _warm = Color(0xFFD97736);

  final List<_Particle> particles;
  final double progress;
  final Offset pointer;
  final VoiceOrbState state;

  _VoiceOrbPainter({
    required this.particles,
    required this.progress,
    required this.pointer,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.235;

    final activity = switch (state) {
      VoiceOrbState.idle => 0.55,
      VoiceOrbState.listening => 1.25,
      VoiceOrbState.thinking => 0.9,
      VoiceOrbState.success => 1.05,
      VoiceOrbState.error => 0.35,
    };

    final rotation = progress * math.pi * 2;
    final pointerX = pointer.dx / 90;
    final pointerY = pointer.dy / 90;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var ring = 0; ring < 3; ring++) {
      final pulse =
          (math.sin(progress * math.pi * 2 * (1.2 + ring * 0.2)) + 1) / 2;
      final ringRadius =
          radius * (1.65 + ring * 0.35) * (0.97 + pulse * 0.035 * activity);

      ringPaint.color = ring == 1
          ? _vermilion.withValues(alpha: 0.24 + 0.10 * activity)
          : _carbon.withValues(alpha: 0.10 + 0.04 * activity);

      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: ringRadius * 2,
          height: ringRadius * 1.18,
        ),
        ringPaint,
      );
    }

    final sorted = <_ProjectedParticle>[];

    for (final particle in particles) {
      final wave = math.sin(
            progress * math.pi * 2 * (3.2 + activity) +
                particle.x * 4.2 +
                particle.y * 3.1 +
                particle.phase,
          ) *
          0.055 *
          activity;

      final scale = 1 + wave;
      var x = particle.x * scale;
      var y = particle.y * scale;
      var z = particle.z * scale;

      final yaw = rotation * 0.32 + pointerX * 0.42;
      final pitch = math.sin(progress * math.pi * 0.5) * 0.12 + pointerY * 0.25;

      final x1 = x * math.cos(yaw) - z * math.sin(yaw);
      final z1 = x * math.sin(yaw) + z * math.cos(yaw);
      final y1 = y * math.cos(pitch) - z1 * math.sin(pitch);
      final z2 = y * math.sin(pitch) + z1 * math.cos(pitch);

      x = x1;
      y = y1;
      z = z2;

      final perspective = 1.0 / (1.0 + z * 0.42);
      final px = center.dx + x * radius * 1.9 * perspective;
      final py = center.dy + y * radius * 1.9 * perspective;

      final depth = ((z + 1) / 2).clamp(0.0, 1.0);
      final alpha = (0.28 + depth * 0.72) * (0.72 + activity * 0.18);
      final particleSize = (0.65 + depth * 1.25) * (0.9 + activity * 0.25);

      final color = particle.accent > 0.90
          ? _vermilion
          : particle.accent > 0.64
              ? _warm
              : _carbon;

      sorted.add(
        _ProjectedParticle(
          offset: Offset(px, py),
          depth: z,
          color: color.withValues(alpha: alpha.clamp(0.0, 1.0)),
          size: particleSize,
        ),
      );
    }

    sorted.sort((a, b) => a.depth.compareTo(b.depth));

    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (final particle in sorted) {
      particlePaint.color = particle.color;
      canvas.drawCircle(particle.offset, particle.size, particlePaint);
    }

    final corePulse = 1 +
        ((math.sin(progress * math.pi * 2 * 1.8) + 1) / 2) * 0.06 * activity;

    final coreRadius = radius * 0.43 * corePulse;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _vermilion.withValues(alpha: 0.12 + activity * 0.08),
          _vermilion.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: coreRadius * 2.2),
      );

    canvas.drawCircle(center, coreRadius * 2.2, glow);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _carbon,
          _carbon.withValues(alpha: 0.94),
          _warm.withValues(alpha: 0.24),
        ],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );

    canvas.drawCircle(center, coreRadius, corePaint);

    final highlight = Paint()
      ..color = _vermilion.withValues(
        alpha: state == VoiceOrbState.listening ? 0.85 : 0.45,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(center, coreRadius * 0.82, highlight);
  }

  @override
  bool shouldRepaint(covariant _VoiceOrbPainter oldDelegate) => true;
}

class _Particle {
  final double x;
  final double y;
  final double z;
  final double accent;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.z,
    required this.accent,
    required this.phase,
  });
}

class _ProjectedParticle {
  final Offset offset;
  final double depth;
  final Color color;
  final double size;

  const _ProjectedParticle({
    required this.offset,
    required this.depth,
    required this.color,
    required this.size,
  });
}
