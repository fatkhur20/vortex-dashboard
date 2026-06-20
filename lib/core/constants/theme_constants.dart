import 'package:flutter/material.dart';

class ThemeConstants {
  static const Color primaryColor = Color(0xFF00E5FF);
  static const Color secondaryColor = Color(0xFF7C4DFF);
  static const Color accentColor = Color(0xFFFF3D00);
  static const Color successColor = Color(0xFF00E676);
  static const Color warningColor = Color(0xFFFFAB00);
  static const Color errorColor = Color(0xFFFF1744);

  static const Color amoledBackground = Color(0xFF000000);
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color cardBackground = Color(0xFF1A1A2E);
  static const Color glassBackground = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x66FFFFFF);

  static const Color speedLow = Color(0xFF00E676);
  static const Color speedMedium = Color(0xFFFFAB00);
  static const Color speedHigh = Color(0xFFFF3D00);
  static const Color speedCritical = Color(0xFFFF1744);

  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFF7C4DFF);
  static const Color neonPink = Color(0xFFFF4081);

  static const Color mapDarkMode = Color(0xFF121212);

  static const List<Color> speedGradient = [
    Color(0xFF00E676),
    Color(0xFF76FF03),
    Color(0xFFFFAB00),
    Color(0xFFFF3D00),
    Color(0xFFFF1744),
  ];

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 500);
  static const Duration animationSlow = Duration(milliseconds: 800);
}
