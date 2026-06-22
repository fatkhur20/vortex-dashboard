import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

Color _avatarColor(String id) {
  final hash = id.hashCode;
  final h = (hash.abs() % 360).toDouble();
  return HSVColor.fromAHSV(1.0, h, 0.45, 0.55).toColor();
}

class _SmoothArrowPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  _SmoothArrowPainter({required this.color, this.isMe = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w / 2, h);
    path.quadraticBezierTo(w * 0.85, h * 0.7, w * 0.7, h * 0.35);
    path.quadraticBezierTo(w * 0.7, h * 0.1, w / 2, 0);
    path.quadraticBezierTo(w * 0.3, h * 0.1, w * 0.3, h * 0.35);
    path.quadraticBezierTo(w * 0.15, h * 0.7, w / 2, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MemberMapMarker extends StatelessWidget {
  final String memberId;
  final String memberName;
  final String activityEmoji;
  final bool isMe;
  final double? battery;
  final String? photoUrl;
  final VoidCallback onTap;

  const MemberMapMarker({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.activityEmoji,
    this.isMe = false,
    this.battery,
    this.photoUrl,
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
          SizedBox(
            width: size + 8,
            height: size + 12,
            child: CustomPaint(
              painter: _SmoothArrowPainter(color: color, isMe: isMe),
              child: Center(
                child: Container(
                  width: size - 10,
                  height: size - 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withAlpha(80),
                  ),
                  child: photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular((size - 10) / 2),
                          child: Image.network(photoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _initialText(initial, size - 10),
                          ),
                        )
                      : _initialText(initial, size - 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _initialText(String initial, double s) {
    return Center(
      child: Text(initial,
          style: TextStyle(
            fontSize: s * 0.5, fontWeight: FontWeight.w700, color: Colors.white,
          )),
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
