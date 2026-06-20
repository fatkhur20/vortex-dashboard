import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class AltimeterGauge extends StatelessWidget {
  final double altitude;
  final double maxAltitude;
  final double minAltitude;
  final double size;

  const AltimeterGauge({
    super.key,
    required this.altitude,
    this.maxAltitude = 0,
    this.minAltitude = 0,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final maxDisplay = maxAltitude > 0 ? maxAltitude : 5000.0;
    final ratio = (altitude / maxDisplay).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size * 0.7,
            child: CustomPaint(
              painter: _AltimeterPainter(
                ratio: ratio,
                altitude: altitude,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${altitude.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'm',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('MAX', maxAltitude, ThemeConstants.warningColor),
              _buildStat('MIN', minAltitude, ThemeConstants.primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(0)}m',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _AltimeterPainter extends CustomPainter {
  final double ratio;
  final double altitude;

  _AltimeterPainter({required this.ratio, required this.altitude});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withOpacity(0.6);
    canvas.drawCircle(center, radius, bgPaint);

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.1);
    canvas.drawCircle(center, radius, borderPaint);

    // Arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = altitude > 0
          ? ThemeConstants.warningColor.withOpacity(0.8)
          : ThemeConstants.primaryColor.withOpacity(0.8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2,
      math.pi * 2 * ratio,
      false,
      arcPaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = (altitude > 0
          ? ThemeConstants.warningColor
          : ThemeConstants.primaryColor).withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius * 0.6, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _AltimeterPainter oldDelegate) {
    return oldDelegate.ratio != ratio;
  }
}
