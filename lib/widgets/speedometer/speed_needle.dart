import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class SpeedNeedle extends StatelessWidget {
  final double speed;
  final double maxSpeed;
  final double size;

  const SpeedNeedle({
    super.key,
    required this.speed,
    this.maxSpeed = 320,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (speed / maxSpeed).clamp(0.0, 1.0);
    final angle = -210.0 + (240.0 * ratio);
    final color = _getSpeedColor(speed);

    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: CustomPaint(
        size: Size(size, size),
        painter: _NeedlePainter(color: color),
      ),
    );
  }

  Color _getSpeedColor(double speed) {
    if (speed < 60) return ThemeConstants.speedLow;
    if (speed < 100) return ThemeConstants.speedMedium;
    if (speed < 140) return ThemeConstants.speedHigh;
    return ThemeConstants.speedCritical;
  }
}

class _NeedlePainter extends CustomPainter {
  final Color color;

  _NeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(center.dx + size.width * 0.35, center.dy),
      needlePaint,
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawLine(
      center,
      Offset(center.dx + size.width * 0.35, center.dy),
      glowPaint,
    );

    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
    canvas.drawCircle(
      center, 8, Paint()
      ..color = ThemeConstants.primaryColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
