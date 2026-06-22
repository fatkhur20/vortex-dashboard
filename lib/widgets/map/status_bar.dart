import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class MapStatusBar extends StatelessWidget {
  final String accuracy;
  final int memberCount;
  final String lastUpdateAgo;
  final bool show3D;
  final bool showTerrain;
  final bool showGlobe;

  const MapStatusBar({
    super.key,
    required this.accuracy,
    required this.memberCount,
    required this.lastUpdateAgo,
    required this.show3D,
    required this.showTerrain,
    this.showGlobe = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item('GPS', accuracy, true),
          _item('Members', '$memberCount', true),
          _item('Update', lastUpdateAgo, true),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withAlpha(20),
          ),
          Icon(
            Icons.threed_rotation,
            size: 12,
            color: show3D ? ThemeConstants.primaryColor : Colors.white.withAlpha(80),
          ),
          const SizedBox(width: 4),
          Text(
            '3D',
            style: TextStyle(
              fontSize: 9,
              color: show3D ? ThemeConstants.primaryColor : Colors.white.withAlpha(80),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.landscape,
            size: 12,
            color: showTerrain ? ThemeConstants.primaryColor : Colors.white.withAlpha(80),
          ),
          const SizedBox(width: 4),
          Text(
            'TR',
            style: TextStyle(
              fontSize: 9,
              color: showTerrain ? ThemeConstants.primaryColor : Colors.white.withAlpha(80),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showGlobe) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.public,
              size: 12,
              color: ThemeConstants.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              'GL',
              style: TextStyle(
                fontSize: 9,
                color: ThemeConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _item(String label, String value, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.white.withAlpha(100),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? ThemeConstants.successColor : Colors.white.withAlpha(150),
          ),
        ),
      ],
    );
  }
}
