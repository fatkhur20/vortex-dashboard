import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SosDialog extends StatelessWidget {
  final String heading;
  final VoidCallback onSendSos;

  const SosDialog({
    super.key,
    required this.heading,
    required this.onSendSos,
  });

  static void show(BuildContext context, {required String heading, required VoidCallback onSendSos}) {
    showDialog(
      context: context,
      builder: (_) => SosDialog(heading: heading, onSendSos: onSendSos),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'SOS Emergency',
        style: TextStyle(
          color: Color(0xFFFF1744),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Share your live location with emergency contacts?',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoRow('Location', 'Active'),
                _infoRow('Battery', '85%'),
                _infoRow('Heading', '$heading\u{00B0}'),
                _infoRow(
                  'Timestamp',
                  DateFormat('HH:mm:ss').format(DateTime.now()),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onSendSos();
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFFF1744).withAlpha(50),
          ),
          child: const Text(
            'SEND SOS',
            style: TextStyle(
              color: Color(0xFFFF1744),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withAlpha(100),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
