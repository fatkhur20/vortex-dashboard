import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/screens/groups/group_tab.dart';

class SideDrawer extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigate;
  final VoidCallback? onJoinGroup;
  final VoidCallback? onCreateGroup;

  const SideDrawer({super.key, this.onNavigate, this.onJoinGroup, this.onCreateGroup});

  @override
  ConsumerState<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends ConsumerState<SideDrawer> {
  @override
  Widget build(BuildContext context) {
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
            _navItem(Icons.map_outlined, 'Map', () => _navigateAndClose(0)),
            _navItem(Icons.groups_outlined, 'Groups', () => _navigateAndClose(1)),
            _navItem(Icons.link, 'Join Group', () { Navigator.pop(context); widget.onJoinGroup?.call(); }),
            _navItem(Icons.add_circle_outline, 'Create Group', () { Navigator.pop(context); widget.onCreateGroup?.call(); }),
            _navItem(Icons.notifications_outlined, 'Notifications', () => _navigateAndClose(3)),
            _navItem(Icons.settings_outlined, 'Settings', () => _navigateAndClose(4)),
            const Spacer(),
            const Divider(color: Colors.white12, height: 1),
            _navItem(Icons.logout, 'Sign Out', _showSignOutConfirm, color: Colors.redAccent),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateAndClose(int tab) {
    Navigator.pop(context);
    widget.onNavigate?.call(tab);
  }

  void _showSignOutConfirm() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Clear local data and sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              ref.read(trackingServiceProvider).stopSync();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SizedBox()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
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

  Widget _navItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: c.withValues(alpha: 0.7), size: 22),
      title: Text(label, style: TextStyle(color: c.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
