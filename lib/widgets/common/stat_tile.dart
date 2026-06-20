import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final Color? iconColor;
  final double fontSize;
  final bool showGlow;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.iconColor,
    this.fontSize = 18,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: iconColor ?? ThemeConstants.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            shadows: showGlow
                ? [
                    Shadow(
                      color: (valueColor ?? Colors.white).withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
