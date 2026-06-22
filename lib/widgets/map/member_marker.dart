import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class MemberMapMarker extends StatelessWidget {
  final String memberName;
  final String activityEmoji;
  final bool isMe;
  final VoidCallback onTap;

  const MemberMapMarker({
    super.key,
    required this.memberName,
    required this.activityEmoji,
    this.isMe = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMe ? 48 : 40,
            height: isMe ? 48 : 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? ThemeConstants.primaryColor : Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: isMe ? Colors.white : Colors.white.withValues(alpha: 0.3),
                width: isMe ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isMe ? ThemeConstants.primaryColor : Colors.white).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(activityEmoji, style: TextStyle(fontSize: isMe ? 22 : 18)),
            ),
          ),
        ],
      ),
    );
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
