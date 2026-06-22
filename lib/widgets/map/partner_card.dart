import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class FloatingPartnerCard extends StatelessWidget {
  final String partnerName;
  final bool isOnline;
  final String distance;
  final String? activity;
  final double? battery;
  final VoidCallback onTap;

  const FloatingPartnerCard({
    super.key,
    required this.partnerName,
    required this.isOnline,
    required this.distance,
    this.activity,
    this.battery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: 16,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4081),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4081).withAlpha(80),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      partnerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? '\u{25CF} Online' : '\u{25CB} Offline',
                      style: TextStyle(
                        fontSize: 10,
                        color: isOnline
                            ? ThemeConstants.successColor
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$distance \u{2022} ${activity ?? "---"} \u{2022} ${battery?.toStringAsFixed(0) ?? "--"}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withAlpha(150),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: Colors.white.withAlpha(80)),
          ],
        ),
      ),
    );
  }
}
