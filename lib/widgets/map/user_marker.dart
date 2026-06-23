import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class _DirectionArrow extends CustomPainter {
  final Color color;

  _DirectionArrow({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h)
      ..lineTo(w * 0.65, h * 0.75)
      ..lineTo(w * 0.35, h * 0.75)
      ..lineTo(0, h)
      ..close();

    final glow = Paint()
      ..color = color.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glow);

    final body = Paint()
      ..color = color.withAlpha(240)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, body);

    final edge = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, edge);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UserBatteryBadge extends StatelessWidget {
  final double battery;

  const UserBatteryBadge({super.key, required this.battery});

  @override
  Widget build(BuildContext context) {
    final pct = battery.clamp(0, 100);
    final bars = (pct / 25).ceil().clamp(0, 4);
    final color = pct > 20 ? Colors.white : const Color(0xFFFF5252);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(190),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(40), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14, height: 8,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 0.5 : 0),
                    decoration: BoxDecoration(
                      color: i < bars ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(0.5),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 3),
          Text('${pct.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class UserMapMarker extends StatelessWidget {
  final double heading;
  final double arrowTurns;
  final String activityEmoji;
  final String? photoUrl;
  final double speed;
  final double battery;
  final VoidCallback onTap;

  const UserMapMarker({
    super.key,
    required this.heading,
    required this.arrowTurns,
    required this.activityEmoji,
    this.photoUrl,
    this.speed = 0,
    this.battery = 100,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showHeading = speed > 5;
    final arrowSize = 40.0;
    final avatarSize = 34.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: arrowSize + 16,
        height: arrowSize + avatarSize + 20,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: AnimatedRotation(
                turns: showHeading ? arrowTurns : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: arrowSize,
                  height: arrowSize,
                  child: CustomPaint(
                    painter: _DirectionArrow(color: ThemeConstants.primaryColor),
                  ),
                ),
              ),
            ),
            Positioned(
              top: arrowSize - 6,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.primaryColor.withAlpha(100),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ThemeConstants.primaryColor,
                      width: 2.5,
                    ),
                    color: Colors.black54,
                    image: photoUrl != null
                        ? DecorationImage(
                            image: FileImage(File(photoUrl!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl == null
                      ? Center(child: Text(activityEmoji, style: const TextStyle(fontSize: 16)))
                      : null,
                ),
              ),
            ),
            Positioned(
              top: arrowSize + avatarSize - 4,
              child: UserBatteryBadge(battery: battery),
            ),
          ],
        ),
      ),
    );
  }
}

class UserSpeedLabel extends StatelessWidget {
  final String speed;
  final Color color;
  final bool visible;

  const UserSpeedLabel({
    super.key,
    required this.speed,
    required this.color,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConstants.primaryColor.withAlpha(75),
          width: 0.5,
        ),
      ),
      child: Text(
        '$speed km/h',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
