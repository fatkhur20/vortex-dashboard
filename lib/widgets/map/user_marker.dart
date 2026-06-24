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

class UserMapMarker extends StatelessWidget {
  final double arrowTurns;
  final String activityEmoji;
  final String? photoUrl;
  final VoidCallback onTap;

  const UserMapMarker({
    super.key,
    required this.arrowTurns,
    required this.activityEmoji,
    this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const arrowSize = 40.0;
    const avatarSize = 34.0;
    const overlap = 6.0;
    const outerW = 56.0;
    const totalH = arrowSize + avatarSize - overlap;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedRotation(
        turns: arrowTurns,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: outerW,
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: (outerW - arrowSize) / 2,
                child: SizedBox(
                  width: arrowSize,
                  height: arrowSize,
                  child: CustomPaint(
                    painter: _DirectionArrow(color: ThemeConstants.primaryColor),
                  ),
                ),
              ),
              Positioned(
                top: arrowSize - overlap,
                left: (outerW - avatarSize) / 2,
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
            ],
          ),
        ),
      ),
    );
  }
}
