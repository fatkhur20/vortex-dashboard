import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class SpeedometerWidget extends StatelessWidget {
  final double speed;
  final double maxSpeed;
  final bool useKmh;
  final double? rpm;
  final double size;

  const SpeedometerWidget({
    super.key,
    required this.speed,
    this.maxSpeed = 320,
    this.useKmh = true,
    this.rpm,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    final speedRatio = (speed / maxSpeed).clamp(0.0, 1.0);
    final color = _getSpeedColor(speed);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpeedometerPainter(
          speed: speedRatio,
          maxSpeed: maxSpeed,
          currentSpeed: speed,
          color: color,
          rpm: rpm,
          useKmh: useKmh,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              Text(
                useKmh
                    ? speed.toStringAsFixed(0)
                    : (speed * 0.621371).toStringAsFixed(0),
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              Text(
                useKmh ? 'KM/H' : 'MPH',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: size * 0.04,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 4,
                ),
              ),
              if (rpm != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${rpm!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: size * 0.035,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
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

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final double currentSpeed;
  final Color color;
  final double? rpm;
  final bool useKmh;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.currentSpeed,
    required this.color,
    this.rpm,
    required this.useKmh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    _drawBackground(canvas, center, radius);
    _drawArcScale(canvas, center, radius);
    _drawTickMarks(canvas, center, radius);
    _drawSpeedArc(canvas, center, radius);
    _drawNeedle(canvas, center, radius);
    _drawCenterDot(canvas, center);
    _drawInnerGlow(canvas, center, radius);
  }

  void _drawBackground(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1A1A2E).withValues(alpha: 0.8),
          const Color(0xFF0D0D0D).withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    canvas.drawCircle(center, radius * 1.5, paint);

    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, outerRingPaint);
  }

  void _drawArcScale(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const startAngle = -210.0 * math.pi / 180;
    const endAngle = 30.0 * math.pi / 180;
    const sweepAngle = 240.0 * math.pi / 180;

    paint.color = Colors.white.withValues(alpha: 0.05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Gradient arc background
    paint.shader = SweepGradient(
      startAngle: startAngle,
      endAngle: endAngle,
      colors: const [
        Color(0xFF00E676),
        Color(0xFF76FF03),
        Color(0xFFFFAB00),
        Color(0xFFFF3D00),
        Color(0xFFFF1744),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    paint.color = Colors.transparent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * 0.15,
      false,
      paint..color = color.withValues(alpha: 0.3),
    );
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke;

    const startAngle = -210.0;
    const endAngle = 30.0;
    const totalAngle = endAngle - startAngle;
    const tickCount = 32;

    for (int i = 0; i <= tickCount; i++) {
      final angle = (startAngle + (totalAngle * i / tickCount)) * math.pi / 180;
      final isMajor = i % 4 == 0;

      final innerRadius = isMajor ? radius - 20 : radius - 12;
      final outerRadius = radius - 4;

      final startPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      paint.color = isMajor
          ? Colors.white.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.2);
      paint.strokeWidth = isMajor ? 2 : 1;

      canvas.drawLine(startPoint, endPoint, paint);

      if (isMajor) {
        final labelRadius = radius - 32;
        final labelPoint = Offset(
          center.dx + labelRadius * math.cos(angle),
          center.dy + labelRadius * math.sin(angle),
        );

        final value = (maxSpeed * i / tickCount).round();
        final displayValue = useKmh ? value : (value * 0.621371).round();

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$displayValue',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          labelPoint - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  void _drawSpeedArc(Canvas canvas, Offset center, double radius) {
    if (speed <= 0) return;

    const startAngle = -210.0 * math.pi / 180;
    const sweepAngle = 240.0 * math.pi / 180;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.8);

    paint.shader = LinearGradient(
      colors: [
        color.withValues(alpha: 0.3),
        color,
        color.withValues(alpha: 0.8),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * speed,
      false,
      paint,
    );
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    if (speed <= 0) return;

    const startAngle = -210.0;
    const endAngle = 30.0;
    const totalAngle = endAngle - startAngle;

    final angle = (startAngle + totalAngle * speed) * math.pi / 180;

    final needleLength = radius - 30;
    final needlePoint = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );

    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needlePoint, needlePaint);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawLine(center, needlePoint, glowPaint);
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 6, dotPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 12, ringPaint);
  }

  void _drawInnerGlow(Canvas canvas, Offset center, double radius) {
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius * 0.8, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.color != color;
  }
}
