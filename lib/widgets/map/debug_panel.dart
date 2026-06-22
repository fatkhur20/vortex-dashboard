import 'package:flutter/material.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class DebugInfo {
  final String label;
  final String value;

  const DebugInfo(this.label, this.value);
}

class DebugPanel extends StatelessWidget {
  final List<DebugInfo> entries;
  final String? errorMessage;

  const DebugPanel({super.key, required this.entries, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...entries.map((e) => _row(e.label, e.value)),
          if (errorMessage != null) _row('Error', errorMessage!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withAlpha(100),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withAlpha(180),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
