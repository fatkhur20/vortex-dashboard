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
    const dotR = 6.0;
    const arrowW = 12.0;
    const arrowH = 12.0;

    final arrowPaint = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.fill;

    final arrowPath = Path()
      ..moveTo(w / 2, h - dotR - arrowH)
      ..lineTo(w / 2 - arrowW / 2, h - dotR)
      ..lineTo(w / 2 + arrowW / 2, h - dotR)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    final glowPaint = Paint()
      ..color = color.withAlpha(60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, glowPaint);

    final dotPaint = Paint()
      ..color = color.withAlpha(230)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h - dotR), dotR, dotPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(w / 2, h - dotR), dotR - 1, borderPaint);
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
    const avatarSize = 24.0;
    const dotSize = 12.0;
    const arrowH = 14.0;
    const outerW = 32.0;
    const totalH = avatarSize + arrowH + dotSize + 4;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: outerW,
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
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
                  ? Center(
                      child: Text(
                        activityEmoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                    )
                  : null,
            ),
            Positioned(
              top: avatarSize + 1,
              child: AnimatedRotation(
                turns: arrowTurns,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: outerW,
                  height: arrowH + dotSize + 2,
                  child: CustomPaint(
                    size: Size(outerW, arrowH + dotSize),
                    painter: _DirectionArrow(color: ThemeConstants.primaryColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
