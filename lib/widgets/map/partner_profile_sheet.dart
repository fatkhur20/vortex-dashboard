import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/models/partner_location.dart';

class PartnerProfileSheet extends StatelessWidget {
  final PartnerLocation partner;
  final String distance;
  final VoidCallback onLocate;
  final VoidCallback onHistory;
  final VoidCallback onNotify;

  const PartnerProfileSheet({
    super.key,
    required this.partner,
    required this.distance,
    required this.onLocate,
    required this.onHistory,
    required this.onNotify,
  });

  static void show(
    BuildContext context, {
    required PartnerLocation partner,
    required String distance,
    required VoidCallback onLocate,
    required VoidCallback onHistory,
    required VoidCallback onNotify,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: PartnerProfileSheet(
            partner: partner,
            distance: distance,
            onLocate: onLocate,
            onHistory: onHistory,
            onNotify: onNotify,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(50),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          partner.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: partner.isOnline
                    ? ThemeConstants.successColor
                    : Colors.grey,
                boxShadow: partner.isOnline
                    ? [
                        BoxShadow(
                          color: ThemeConstants.successColor.withAlpha(120),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              partner.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: partner.isOnline
                    ? ThemeConstants.successColor
                    : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('Distance', distance),
            _stat('Battery', '${partner.batteryLevel?.toStringAsFixed(0) ?? "--"}%'),
            _stat('Speed', '${partner.speed?.toStringAsFixed(0) ?? "--"} km/h'),
            _stat('Activity', partner.activity ?? '---'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _actionButton(Icons.map, 'Locate', onLocate)),
            const SizedBox(width: 10),
            Expanded(child: _actionButton(Icons.route, 'History', onHistory)),
            const SizedBox(width: 10),
            Expanded(child: _actionButton(Icons.notifications, 'Notify', onNotify)),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(100),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
