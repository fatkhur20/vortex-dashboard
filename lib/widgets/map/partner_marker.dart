import 'package:flutter/material.dart';

class PartnerMapMarker extends StatefulWidget {
  final String partnerName;
  final VoidCallback onTap;

  const PartnerMapMarker({
    super.key,
    required this.partnerName,
    required this.onTap,
  });

  @override
  State<PartnerMapMarker> createState() => _PartnerMapMarkerState();
}

class _PartnerMapMarkerState extends State<PartnerMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final scale = 1.0 + (_controller.value * 0.15);
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4081).withAlpha(100),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF4081).withAlpha(50),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF4081),
                ),
                child: Center(
                  child: Text(
                    widget.partnerName.isNotEmpty
                        ? widget.partnerName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartnerStatusLabel extends StatelessWidget {
  final bool isMoving;
  final double? speed;
  final String? activity;

  const PartnerStatusLabel({
    super.key,
    required this.isMoving,
    this.speed,
    this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final label = isMoving
        ? '\u{25CF} ${speed?.toStringAsFixed(0) ?? "--"} km/h'
        : '\u{25CF} ${activity ?? "Stationary"}';
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4081).withAlpha(180),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
