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
      if (gf.screenRadius < 3) continue;

      final fill = Paint()
        ..color = gf.color.withAlpha(40)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(gf.screenCenter, gf.screenRadius, fill);

      final border = Paint()
        ..color = gf.color.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(gf.screenCenter, gf.screenRadius, border);

      if (showLabels && gf.screenRadius > 20) {
        _drawLabel(canvas, gf.name, gf.screenCenter, gf.color, gf.screenRadius);
      }
    }
  }

  void _drawLabel(Canvas canvas, String name, Offset center, Color color, double radius) {
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(color: Colors.black.withAlpha(200), blurRadius: 4),
            Shadow(color: color.withAlpha(100), blurRadius: 8),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 2);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - radius - tp.height - 6));
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
