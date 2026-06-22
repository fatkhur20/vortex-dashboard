import 'package:flutter/material.dart';
import 'package:vortex_dashboard/models/geofence.dart';

class GeofenceRenderData {
  final Offset screenCenter;
  final double screenRadius;
  final Color color;
  final String name;

  const GeofenceRenderData({
    required this.screenCenter,
    required this.screenRadius,
    required this.color,
    required this.name,
  });
}

class GeofenceOverlayPainter extends CustomPainter {
  final List<GeofenceRenderData> geofences;
  final bool showLabels;

  GeofenceOverlayPainter({
    required this.geofences,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final gf in geofences) {
      if (showLabels && gf.screenRadius > 10) {
        _drawLabel(canvas, gf.name, gf.screenCenter, gf.color, gf.screenRadius);
      }
    }
  }

  void _drawLabel(Canvas canvas, String name, Offset center, Color color, double radius) {
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: Colors.white.withAlpha(200),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(color: Colors.black.withAlpha(200), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 2);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - radius - tp.height - 6));

    final dotPaint = Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(GeofenceOverlayPainter old) {
    if (old.geofences.length != geofences.length) return true;
    for (int i = 0; i < geofences.length; i++) {
      if (geofences[i].screenCenter != old.geofences[i].screenCenter) return true;
      if (geofences[i].screenRadius != old.geofences[i].screenRadius) return true;
      if (geofences[i].color != old.geofences[i].color) return true;
    }
    return false;
  }
}
