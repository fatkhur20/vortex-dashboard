import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/widgets/map/map_enums.dart';

class MapStyleSheet extends StatelessWidget {
  final MapStyleLabel currentStyle;
  final ValueChanged<MapStyleLabel> onStyleChanged;

  const MapStyleSheet({
    super.key,
    required this.currentStyle,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Map Style',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...MapStyleLabel.values.map(
                (style) => _StyleSheetItem(
                  style: style,
                  active: currentStyle == style,
                  onTap: () {
                    onStyleChanged(style);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required MapStyleLabel currentStyle,
    required ValueChanged<MapStyleLabel> onStyleChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Map Style',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...MapStyleLabel.values.map(
                (style) => _StyleSheetItem(
                  style: style,
                  active: currentStyle == style,
                  onTap: () {
                    onStyleChanged(style);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleSheetItem extends StatelessWidget {
  final MapStyleLabel style;
  final bool active;
  final VoidCallback onTap;

  const _StyleSheetItem({
    required this.style,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: active
                ? ThemeConstants.primaryColor.withAlpha(25)
                : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? ThemeConstants.primaryColor.withAlpha(100)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                style.icon,
                size: 20,
                color: active ? ThemeConstants.primaryColor : Colors.white60,
              ),
              const SizedBox(width: 14),
              Text(
                style.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: active ? ThemeConstants.primaryColor : Colors.white,
                ),
              ),
              const Spacer(),
              if (active)
                Icon(
                  Icons.check_circle,
                  color: ThemeConstants.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
