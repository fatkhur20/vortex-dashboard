import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/services/notification_service.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  @override
  void initState() {
    super.initState();
    notificationService.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.amoledBackground,
      appBar: AppBar(
        title: const Text('Alerts', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: () => notificationService.clearAll(),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<TrackerNotification>>(
        valueListenable: notificationService.notifier,
        builder: (context, notifications, _) {
          if (notifications.isEmpty) return _buildEmptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (_, i) => _notificationTile(notifications[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(Icons.notifications_none, color: Colors.white.withValues(alpha: 0.3), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No notifications yet',
                style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Arrivals, departures, and group events will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile(TrackerNotification n) {
    final icon = _iconForType(n.type);
    final color = _colorForType(n.type);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => notificationService.markRead(n.id),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: n.read ? FontWeight.w400 : FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(_timeAgo(n.timestamp),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                ],
              ),
            ),
            if (!n.read)
              Container(width: 8, height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: ThemeConstants.primaryColor)),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(NotificationType t) {
    switch (t) {
      case NotificationType.arrival: return Icons.place;
      case NotificationType.departure: return Icons.departure_board;
      case NotificationType.groupJoin: return Icons.group_add;
      case NotificationType.groupLeave: return Icons.group_remove;
      case NotificationType.lowBattery: return Icons.battery_alert;
    }
  }

  Color _colorForType(NotificationType t) {
    switch (t) {
      case NotificationType.arrival: return const Color(0xFF00E676);
      case NotificationType.departure: return const Color(0xFFFFC107);
      case NotificationType.groupJoin: return const Color(0xFF448AFF);
      case NotificationType.groupLeave: return const Color(0xFFFF5252);
      case NotificationType.lowBattery: return const Color(0xFFFF1744);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
