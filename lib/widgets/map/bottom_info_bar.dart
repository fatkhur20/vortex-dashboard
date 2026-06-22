import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/widgets/map/info_tile.dart';

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
          const InfoTile(label: 'DIST', value: '12.3', unit: 'km'),
          InfoTile(label: 'ALT', value: altitude, unit: 'm'),
          InfoTile(
            label: 'HDG',
            value: '$heading\u{00B0}',
            unit: headingDir,
          ),
          InfoTile(
            label: 'ACC',
            value: accuracy,
            unit: 'm',
            color: accColor,
          ),
          InfoTile(
            label: 'GROUP',
            value: '$memberCount',
            unit: 'members',
            color: memberCount > 1 ? ThemeConstants.primaryColor : Colors.white.withAlpha(150),
          ),
        ],
      ),
    );
  }
}
