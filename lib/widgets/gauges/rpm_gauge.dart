import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class RpmGauge extends StatelessWidget {
  final double rpm;
  final double maxRpm;
  final double size;

  const RpmGauge({
    super.key,
    required this.rpm,
    this.maxRpm = 8000,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (rpm / maxRpm).clamp(0.0, 1.0);
    final color = _getRpmColor(ratio);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RpmPainter(ratio: ratio, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rpm.toStringAsFixed(0),
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RPM',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: size * 0.06,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRpmColor(double ratio) {
    if (ratio < 0.5) return ThemeConstants.speedLow;
    if (ratio < 0.75) return ThemeConstants.speedMedium;
    if (ratio < 0.9) return ThemeConstants.speedHigh;
    return ThemeConstants.speedCritical;
  }
}

class _RpmPainter extends CustomPainter {
  final double ratio;
  final Color color;

  _RpmPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withOpacity(0.6);
    canvas.drawCircle(center, radius, bgPaint);

    // Segments
    const segments = 10;
    final segmentAngle = (math.pi * 1.5) / segments;

    for (int i = 0; i < segments; i++) {
      final startAngle = math.pi * 1.25 + i * segmentAngle;
      final isActive = i / segments <= ratio;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = isActive
            ? (i >= segments - 2 ? ThemeConstants.speedCritical : color)
            : Colors.white.withOpacity(0.1);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        startAngle,
        segmentAngle - 0.05,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RpmPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.color != color;
  }
}
