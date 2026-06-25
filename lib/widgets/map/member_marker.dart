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
    final w = size.width;
    final h = size.height;
    final dotR = 5.0;
    const arrowW = 10.0;
    const arrowH = 10.0;

    // Arrow pointing up
    final arrowPaint = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.fill;

    final arrowPath = Path()
      ..moveTo(w / 2, h - dotR - arrowH)
      ..lineTo(w / 2 - arrowW / 2, h - dotR)
      ..lineTo(w / 2 + arrowW / 2, h - dotR)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Dot
    final dotPaint = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h - dotR), dotR, dotPaint);

    // Dot border
    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(w / 2, h - dotR), dotR - 0.75, borderPaint);
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
  final double zoom;
  final VoidCallback onTap;

  const MemberMapMarker({
    super.key,
    required this.memberId,
    required this.memberName,
    this.photoUrl,
    this.isMe = false,
    this.isOnline = false,
    this.heading = 0,
    this.zoom = 18,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = memberName.isNotEmpty ? memberName[0].toUpperCase() : '?';
    final color = isMe ? ThemeConstants.primaryColor : _avatarColor(memberId);

    final avatarScale = (zoom / 18.0).clamp(0.5, 2.0);
    const baseAvatarSize = 22.0;
    const dotSize = 10.0;
    const arrowH = 12.0;
    const outerW = 28.0;
    const totalH = baseAvatarSize + arrowH + dotSize + 4;
    final avatarSize = baseAvatarSize;
    final headClamp = heading.clamp(0.0, 359.0);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: outerW,
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Transform.scale(
              scale: avatarScale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(180), width: 1.5),
                        color: Colors.black87,
                        boxShadow: [
                          BoxShadow(
                            color: isOnline ? const Color(0xFF00E676).withAlpha(100) : Colors.black.withAlpha(60),
                            blurRadius: isOnline ? 8 : 4,
                            spreadRadius: isOnline ? 1 : 0,
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
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )),
                            )
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        top: avatarSize - 4,
                        right: -1,
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E676),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: baseAvatarSize + 1,
              child: AnimatedRotation(
                turns: headClamp / 360.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: outerW,
                  height: arrowH + dotSize + 2,
                  child: CustomPaint(
                    size: Size(outerW, arrowH + dotSize),
                    painter: _MemberArrowPainter(color: color),
                  ),
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
