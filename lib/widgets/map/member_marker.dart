import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

Color _avatarColor(String id) {
  final hash = id.hashCode;
  final h = (hash.abs() % 360).toDouble();
  return HSVColor.fromAHSV(1.0, h, 0.45, 0.55).toColor();
}

class _MemberArrowPainter extends CustomPainter {
  final Color color;

  _MemberArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(200)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w / 2, h);
    path.quadraticBezierTo(w * 0.8, h * 0.6, w * 0.65, h * 0.25);
    path.quadraticBezierTo(w * 0.65, h * 0.05, w / 2, 0);
    path.quadraticBezierTo(w * 0.35, h * 0.05, w * 0.35, h * 0.25);
    path.quadraticBezierTo(w * 0.2, h * 0.6, w / 2, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MemberMapMarker extends StatelessWidget {
  final String memberId;
  final String memberName;
  final String? photoUrl;
  final bool isMe;
  final bool isOnline;
  final double heading;
  final VoidCallback onTap;

  const MemberMapMarker({
    super.key,
    required this.memberId,
    required this.memberName,
    this.photoUrl,
    this.isMe = false,
    this.isOnline = false,
    this.heading = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = memberName.isNotEmpty ? memberName[0].toUpperCase() : '?';
    final color = isMe ? ThemeConstants.primaryColor : _avatarColor(memberId);
    final avatarSize = isMe ? 40.0 : 32.0;
    final showHeading = !isMe && heading > 0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: avatarSize + 12,
        height: avatarSize + 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showHeading)
              Positioned(
                top: 0,
                child: AnimatedRotation(
                  turns: heading / 360,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: SizedBox(
                    width: avatarSize,
                    height: avatarSize - 4,
                    child: CustomPaint(
                      painter: _MemberArrowPainter(color: color),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: showHeading ? 6 : 0,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(180), width: 2),
                  color: Colors.black54,
                  boxShadow: [
                    BoxShadow(
                      color: isOnline ? const Color(0xFF00E676).withAlpha(80) : Colors.black.withAlpha(60),
                      blurRadius: isOnline ? 10 : 6,
                      spreadRadius: isOnline ? 2 : 0,
                    ),
                  ],
                  image: photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl == null
                    ? Center(
                        child: Text(initial,
                            style: TextStyle(
                              fontSize: avatarSize * 0.45,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      )
                    : null,
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E676),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withAlpha(120),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MemberNameLabel extends StatelessWidget {
  final String name;

  const MemberNameLabel({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(name,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
    );
  }
}

class MemberClusterBadge extends StatelessWidget {
  final int count;

  const MemberClusterBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 40,
      decoration: BoxDecoration(
        color: ThemeConstants.primaryColor.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('\u{1F465}', style: TextStyle(fontSize: 16)),
          Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}
