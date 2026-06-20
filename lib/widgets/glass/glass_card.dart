import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final double borderRadius;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    this.padding,
    this.height,
    this.width,
    this.borderRadius = 16,
    this.borderColor,
    this.gradientColors,
    this.blur = 10,
    this.opacity = 0.1,
    this.margin,
    required this.child,
  });

  factory GlassCard.neon({
    required Widget child,
    double borderRadius = 16,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassCard(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      borderColor: ThemeConstants.neonBlue.withValues(alpha: 0.3),
      gradientColors: [
        ThemeConstants.neonBlue.withValues(alpha: 0.03),
        Colors.transparent,
      ],
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradientColors != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors!,
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: opacity),
                  Colors.white.withValues(alpha: opacity * 0.5),
                ],
              ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConstants.primaryColor.withValues(alpha: 0.05),
            blurRadius: blur,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
