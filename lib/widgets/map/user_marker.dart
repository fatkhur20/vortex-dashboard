import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class UserMapMarker extends StatelessWidget {
  final double heading;
  final String activityEmoji;
  final VoidCallback onTap;

  const UserMapMarker({
    super.key,
    required this.heading,
    required this.activityEmoji,
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
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.primaryColor.withAlpha(100),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: ThemeConstants.primaryColor.withAlpha(50),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withAlpha(100),
                ),
                child: Center(
                  child: Text(activityEmoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              Icon(
                Icons.navigation,
                color: Colors.white,
                size: 28,
                shadows: [
                  Shadow(
                    color: ThemeConstants.primaryColor.withAlpha(200),
                    blurRadius: 8,
                  ),
                ],
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
