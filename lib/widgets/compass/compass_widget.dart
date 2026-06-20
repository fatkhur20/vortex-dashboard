import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class CompassWidget extends StatelessWidget {
  final double heading;
  final double size;

  const CompassWidget({
    super.key,
    required this.heading,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassPainter(heading: heading),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${heading.toStringAsFixed(0)}\u00B0',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getDirection(heading),
                style: TextStyle(
                  color: ThemeConstants.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDirection(double heading) {
    final directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((heading + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;

  _CompassPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    _drawOuterRing(canvas, center, radius);
    _drawCardinalPoints(canvas, center, radius);
    _drawDirectionIndicators(canvas, center, radius);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.8);
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ThemeConstants.primaryColor.withValues(alpha: 0.5);
    canvas.drawCircle(center, radius, borderPaint);

    final glowPaint = Paint()
      ..color = ThemeConstants.primaryColor.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius, glowPaint);
  }

  void _drawCardinalPoints(Canvas canvas, Offset center, double radius) {
    final northAngle = (heading - 90) * math.pi / 180;

    const points = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = northAngle + (i * 90 * math.pi / 180);
      final isNorth = i == 0;

      final point = Offset(
        center.dx + (radius - 30) * math.cos(angle),
        center.dy + (radius - 30) * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: points[i],
          style: TextStyle(
            color: isNorth
                ? ThemeConstants.errorColor
                : Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: isNorth ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        point - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawDirectionIndicators(Canvas canvas, Offset center, double radius) {
    final northAngle = (heading - 90) * math.pi / 180;

    for (int i = 0; i < 24; i++) {
      final angle = northAngle + (i * 15 * math.pi / 180);
      final isMajor = i % 3 == 0;

      final innerRadius = radius - (isMajor ? 18 : 14);
      final outerRadius = radius - (isMajor ? 8 : 10);

      final startPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      final paint = Paint()
        ..color = isMajor
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = isMajor ? 1.5 : 1;

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.heading != heading;
  }
}
