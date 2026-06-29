import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════
/// ConfettiOverlay — Animation confetti khi hoàn thành
/// ────────────────────────────────────────────────────────────────────
/// Hiệu ứng particles rơi xuống với nhiều màu.
/// Tự kết thúc sau [duration].
/// ════════════════════════════════════════════════════════════════════

class ConfettiOverlay extends StatefulWidget {
  final Duration duration;
  final int particleCount;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    this.duration = const Duration(milliseconds: 2500),
    this.particleCount = 60,
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rand = math.Random();

  static const _colors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFFFFD93D), // Yellow
    Color(0xFF6BCB77), // Green
    Color(0xFF4D96FF), // Blue
    Color(0xFFC084FC), // Purple
    Color(0xFFF472B6), // Pink
    Color(0xFFFB923C), // Orange
    Color(0xFF22D3EE), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => _genParticle());
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      })
      ..forward();
  }

  _Particle _genParticle() {
    return _Particle(
      x: _rand.nextDouble(),
      y: -0.1 - _rand.nextDouble() * 0.3,
      speed: 0.3 + _rand.nextDouble() * 0.7,
      size: 4 + _rand.nextDouble() * 8,
      rotation: _rand.nextDouble() * math.pi * 2,
      rotationSpeed: (_rand.nextDouble() - 0.5) * 6,
      wobble: _rand.nextDouble() * 0.03,
      wobbleSpeed: 1 + _rand.nextDouble() * 3,
      color: _colors[_rand.nextInt(_colors.length)],
      shape: _rand.nextInt(3), // 0=rect, 1=circle, 2=star
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _ctrl.value,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double wobble;
  final double wobbleSpeed;
  final Color color;
  final int shape;

  const _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.wobble,
    required this.wobbleSpeed,
    required this.color,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = progress;
      final currentY = p.y + p.speed * t;
      final currentX = p.x + math.sin(t * p.wobbleSpeed * math.pi * 2) * p.wobble;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      if (currentY > 1.2) continue;

      final px = currentX * size.width;
      final py = currentY * size.height;
      final rot = p.rotation + p.rotationSpeed * t;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);

      switch (p.shape) {
        case 0: // Rectangle
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            paint,
          );
          break;
        case 1: // Circle
          canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
          break;
        case 2: // Star
          _drawStar(canvas, p.size * 0.5, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a = (i * 72 - 90) * math.pi / 180;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final innerA = ((i * 72 + 36) - 90) * math.pi / 180;
      final ix = r * 0.4 * math.cos(innerA);
      final iy = r * 0.4 * math.sin(innerA);
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}

/// Helper widget to show confetti as an overlay on any widget.
/// Usage:
/// ```dart
/// ConfettiTrigger(
///   trigger: _showConfetti,
///   child: MyContent(),
/// )
/// ```
class ConfettiTrigger extends StatelessWidget {
  final bool trigger;
  final Widget child;
  final VoidCallback? onConfettiComplete;

  const ConfettiTrigger({
    super.key,
    required this.trigger,
    required this.child,
    this.onConfettiComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (trigger)
          Positioned.fill(
            child: ConfettiOverlay(
              onComplete: onConfettiComplete,
            ),
          ),
      ],
    );
  }
}
