import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class MapStatusBar extends StatelessWidget {
  final String accuracy;
  final int memberCount;
  final String lastUpdateAgo;

  const MapStatusBar({
    super.key,
    required this.accuracy,
    required this.memberCount,
    required this.lastUpdateAgo,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item('GPS', accuracy),
          _item('Members', '$memberCount'),
          _item('Update', lastUpdateAgo),
        ],
      ),
    );
  }

  Widget _item(String label, String value) {
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
            color: Colors.white.withAlpha(200),
          ),
        ),
      ],
    );
  }
}
