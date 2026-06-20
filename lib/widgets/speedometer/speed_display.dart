import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/core/utils/extensions.dart';

class SpeedDisplay extends StatelessWidget {
  final double speed;
  final bool useKmh;

  const SpeedDisplay({
    super.key,
    required this.speed,
    this.useKmh = true,
  });

  @override
  Widget build(BuildContext context) {
    final displaySpeed = useKmh ? speed : speed * 0.621371;
    final color = speed.speedColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displaySpeed.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontSize: 72,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: color.withOpacity(0.4),
                blurRadius: 30,
              ),
              Shadow(
                color: color.withOpacity(0.2),
                blurRadius: 60,
              ),
            ],
          ),
        ),
        Text(
          useKmh ? 'KM/H' : 'MPH',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }
}
