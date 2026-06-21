import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ThemeConstants.primaryColor.withAlpha(150)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.white.withAlpha(120),
          letterSpacing: 1.5,
        )),
      ],
    );
  }
}
