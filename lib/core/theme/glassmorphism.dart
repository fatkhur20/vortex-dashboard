import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class Glassmorphism {
  static BoxDecoration glassDecoration({
    double blur = 10,
    double opacity = 0.15,
    double radius = 16,
    Color? borderColor,
    double borderWidth = 0.5,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.2),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: ThemeConstants.primaryColor.withOpacity(0.1),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration gradientGlassDecoration({
    List<Color>? gradientColors,
    double blur = 10,
    double opacity = 0.1,
    double radius = 16,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors ??
            [
              Colors.white.withOpacity(opacity),
              Colors.white.withOpacity(opacity * 0.5),
            ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withOpacity(0.15),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: ThemeConstants.primaryColor.withOpacity(0.08),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration neonBorder({
    Color neonColor = ThemeConstants.neonBlue,
    double radius = 16,
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: neonColor.withOpacity(0.5),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: neonColor.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: neonColor.withOpacity(0.1),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
