import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';

class SideDrawer extends ConsumerWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(activeGroupMembersProvider);
    final uid = ref.watch(userIdProvider);
    final me = uid != null ? members.where((m) => m.id == uid).firstOrNull : null;
    final isOnline = me?.presence == 'online';

    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, me?.displayName ?? 'User', isOnline),
            const Divider(color: Colors.white12, height: 1),
            _navItem(context, Icons.map_outlined, 'Map', () => Navigator.pop(context)),
            _navItem(context, Icons.groups_outlined, 'Groups', () { Navigator.pop(context); }),
            _navItem(context, Icons.link, 'Join Group', () { Navigator.pop(context); }),
            _navItem(context, Icons.add_circle_outline, 'Create Group', () { Navigator.pop(context); }),
            _navItem(context, Icons.notifications_outlined, 'Notifications', () { Navigator.pop(context); }),
            _navItem(context, Icons.settings_outlined, 'Settings', () { Navigator.pop(context); }),
            const Spacer(),
            const Divider(color: Colors.white12, height: 1),
            _navItem(context, Icons.logout, 'Sign Out', () {}, color: Colors.redAccent),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, bool online) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ThemeConstants.primaryColor.withValues(alpha: 0.15),
              border: Border.all(color: online ? const Color(0xFF00E676) : Colors.white24, width: 2),
            ),
            child: const Center(child: Text('📍', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(online ? 'Online' : 'Offline',
                    style: TextStyle(fontSize: 12, color: online ? const Color(0xFF00E676) : Colors.white38, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: c.withValues(alpha: 0.7), size: 22),
      title: Text(label, style: TextStyle(color: c.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
