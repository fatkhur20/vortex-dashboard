import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class _SmoothArrowPainter extends CustomPainter {
  final Color color;

  _SmoothArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w / 2, h);
    path.quadraticBezierTo(w * 0.85, h * 0.7, w * 0.7, h * 0.35);
    path.quadraticBezierTo(w * 0.7, h * 0.1, w / 2, 0);
    path.quadraticBezierTo(w * 0.3, h * 0.1, w * 0.3, h * 0.35);
    path.quadraticBezierTo(w * 0.15, h * 0.7, w / 2, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UserMapMarker extends StatelessWidget {
  final double heading;
  final String activityEmoji;
  final String? photoUrl;
  final VoidCallback onTap;

  const UserMapMarker({
    super.key,
    required this.heading,
    required this.activityEmoji,
    this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedRotation(
        turns: heading / 360,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 64,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 64,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.primaryColor.withAlpha(80),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _SmoothArrowPainter(color: ThemeConstants.primaryColor),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black45,
                        image: photoUrl != null ? DecorationImage(
                          image: FileImage(File(photoUrl!)),
                          fit: BoxFit.cover,
                        ) : null,
                      ),
                      child: photoUrl == null
                          ? Center(child: Text(activityEmoji, style: const TextStyle(fontSize: 14)))
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserSpeedLabel extends StatelessWidget {
  final String speed;
  final Color color;

  const UserSpeedLabel({super.key, required this.speed, required this.color});

  @override
  Widget build(BuildContext context) {
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
