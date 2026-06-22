import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;

  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white.withAlpha(128),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c,
            shadows: [Shadow(color: c.withAlpha(75), blurRadius: 4)],
          ),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(100)),
        ),
      ],
    );
  }
}
