import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final String tooltip;

  const MapButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.active = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: disabled ? Colors.black.withAlpha(50) : Colors.black.withAlpha(128),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? ThemeConstants.primaryColor.withAlpha(128)
                  : Colors.white.withAlpha(disabled ? 12 : 25),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: disabled
                ? Colors.white24
                : (active ? ThemeConstants.primaryColor : Colors.white70),
            size: 20,
          ),
        ),
      ),
    );
  }
}
