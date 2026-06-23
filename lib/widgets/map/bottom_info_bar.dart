import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class _InfoItem extends StatelessWidget {
  final String label, value, unit;
  final Color? color;
  const _InfoItem({required this.label, required this.value, required this.unit, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(100), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color ?? Colors.white)),
        Text(unit, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(80), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class BottomInfoBar extends StatelessWidget {
  final String distance;
  final String altitude;
  final String heading;
  final String headingDir;
  final String accuracy;
  final int memberCount;
  final Color? accuracyColor;

  const BottomInfoBar({
    super.key,
    required this.distance,
    required this.altitude,
    required this.heading,
    required this.headingDir,
    required this.accuracy,
    required this.memberCount,
    this.accuracyColor,
  });

  @override
  Widget build(BuildContext context) {
    final accColor = accuracyColor ??
        (((double.tryParse(accuracy) ?? 99) < 10)
            ? ThemeConstants.successColor
            : ThemeConstants.warningColor);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _InfoItem(label: 'DIST', value: '12.3', unit: 'km'),
          _InfoItem(label: 'ALT', value: altitude, unit: 'm'),
          _InfoItem(label: 'HDG', value: '$heading\u{00B0}', unit: headingDir),
          _InfoItem(label: 'ACC', value: accuracy, unit: 'm', color: accColor),
          _InfoItem(
            label: 'GROUP', value: '$memberCount', unit: 'members',
            color: memberCount > 1 ? ThemeConstants.primaryColor : Colors.white.withAlpha(150),
          ),
        ],
      ),
    );
  }
}
