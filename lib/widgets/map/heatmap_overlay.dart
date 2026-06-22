import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/services/heatmap_service.dart';

class HeatmapOverlayPainter extends CustomPainter {
  final List<HeatmapPoint> points;
  final double opacity;
  final double radius;
  final Map<String, Offset> _offsetCache = {};

  HeatmapOverlayPainter({
    required this.points,
    this.opacity = 0.6,
    this.radius = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    _updateOffsets(size);
    if (points.length == 1) {
      _drawPoint(canvas, points[0]);
      return;
    }

    final weights = points.map((p) => p.weight).toList();
    final minW = weights.reduce(min);
    final maxW = weights.reduce(max);
    final range = maxW - minW;

    for (final pt in points) {
      final normalized = range > 0 ? (pt.weight - minW) / range : 0.5;
      _drawPoint(canvas, pt, normalized);
    }
  }

  void _updateOffsets(Size size) {
    _offsetCache.clear();
    for (final pt in points) {
      final x = ((pt.lng + 180) / 360) * size.width;
      final y = ((90 - pt.lat) / 180) * size.height;
      _offsetCache[pt.id] = Offset(x.toDouble(), y.toDouble());
    }
  }

  void _drawPoint(Canvas canvas, HeatmapPoint pt, [double normalized = 0.5]) {
    final offset = _offsetCache[pt.id];
    if (offset == null) return;

    final r = radius * (0.6 + normalized * 0.4);
    final alpha = (opacity * 255 * (0.3 + normalized * 0.7)).round().clamp(0, 255);

    final colors = [
      Color.fromARGB(alpha, 0, 100, 255),    // blue
      Color.fromARGB(alpha, 0, 229, 255),    // cyan
      Color.fromARGB(alpha, 0, 230, 118),    // green
      Color.fromARGB(alpha, 255, 171, 0),    // amber
      Color.fromARGB(alpha, 255, 23, 68),    // red
    ];
    final colorIndex = (normalized * (colors.length - 1)).round().clamp(0, colors.length - 1);
    final color = colors[colorIndex];

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withAlpha(alpha), color.withAlpha(0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: offset, radius: r));

    canvas.drawCircle(offset, r, paint);
  }

  @override
  bool shouldRepaint(HeatmapOverlayPainter old) {
    return old.points != points || old.opacity != opacity || old.radius != radius;
  }
}
