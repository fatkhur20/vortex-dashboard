import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

Color _avatarColor(String id) {
  final hash = id.hashCode;
  final h = (hash.abs() % 360).toDouble();
  return HSVColor.fromAHSV(1.0, h, 0.45, 0.55).toColor();
}

class MemberMapMarker extends StatelessWidget {
  final String memberId;
  final String memberName;
  final String activityEmoji;
  final bool isMe;
  final double? battery;
  final VoidCallback onTap;

  const MemberMapMarker({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.activityEmoji,
    this.isMe = false,
    this.battery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = memberName.isNotEmpty ? memberName[0].toUpperCase() : '?';
    final color = isMe ? ThemeConstants.primaryColor : _avatarColor(memberId);
    final size = isMe ? 44.0 : 36.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1),
                  ],
                ),
                child: Center(
                  child: Text(initial,
                      style: TextStyle(
                        fontSize: size * 0.45,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 3)],
                      )),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -4,
                child: Text(activityEmoji, style: const TextStyle(fontSize: 14)),
              ),
              if (battery != null)
                Positioned(
                  top: -2,
                  left: -2,
                  child: _batteryIcon(battery!),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(memberName,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ),
        ],
      ),
    );
  }

  Widget _batteryIcon(double level) {
    IconData icon;
    Color col;
    if (level > 75) {
      icon = Icons.battery_full;
      col = const Color(0xFF00E676);
    } else if (level > 50) {
      icon = Icons.battery_std;
      col = const Color(0xFFFFC107);
    } else if (level > 20) {
      icon = Icons.battery_unknown;
      col = const Color(0xFFFF9800);
    } else {
      icon = Icons.battery_alert;
      col = const Color(0xFFFF1744);
    }
    return Icon(icon, color: col, size: 12);
  }
}

class MemberStatusLabel extends StatelessWidget {
  final String presence;
  final double speed;
  final String activity;

  const MemberStatusLabel({
    super.key,
    required this.presence,
    required this.speed,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = presence == 'online';
    final isAway = presence == 'away';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isOnline ? const Color(0xFF00E676) : isAway ? const Color(0xFFFFC107) : Colors.red).withAlpha(160),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        speed > 0 ? '${speed.toStringAsFixed(0)} km/h' : activity,
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
