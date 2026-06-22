import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/screens/map/map_screen.dart';
import 'package:vortex_dashboard/screens/groups/group_tab.dart';
import 'package:vortex_dashboard/screens/notifications/notifications_tab.dart';
import 'package:vortex_dashboard/screens/settings/settings_tab.dart';
import 'package:vortex_dashboard/widgets/common/side_drawer.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const MapScreen(isEmbeddedInShell: true),
      const GroupTab(),
      const SizedBox(),
      const NotificationsTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideDrawer(),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.12)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.map_outlined, Icons.map, 'Map', 0),
              _navItem(Icons.groups_outlined, Icons.groups, 'Groups', 1),
              _navItem(Icons.add_circle_outline, Icons.add_circle, '', 2),
              _navItem(Icons.notifications_outlined, Icons.notifications, 'Alerts', 3),
              _navItem(Icons.settings_outlined, Icons.settings, 'Settings', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData outlined, IconData filled, String label, int index) {
    final active = _currentIndex == index;
    final isCenter = index == 2;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          _showQuickActionsSheet();
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isCenter ? 0 : 4, horizontal: isCenter ? 0 : 12),
        child: isCenter
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(active ? filled : outlined, color: active ? ThemeConstants.primaryColor : Colors.white38, size: 22),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(fontSize: 9, color: active ? ThemeConstants.primaryColor : Colors.white38, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, top: 24, left: 20, right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2),
              )),
            ),
            const SizedBox(height: 20),
            const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _actionTile(Icons.add_circle_outline, 'Create Group', () { Navigator.pop(context); _navigateToGroups(); }),
            _actionTile(Icons.link, 'Join Group', () { Navigator.pop(context); _navigateToGroups(); }),
            _actionTile(Icons.place, 'Add Place', () { Navigator.pop(context); }),
            _actionTile(Icons.shield_outlined, 'Create Geofence', () { Navigator.pop(context); }),
            _actionTile(Icons.share, 'Share Location', () { Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: ThemeConstants.primaryColor, size: 24),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _navigateToGroups() {
    setState(() => _currentIndex = 1);
  }
}
