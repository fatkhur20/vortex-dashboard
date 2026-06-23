import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/models/geofence.dart';
import 'package:vortex_dashboard/providers/geofence_provider.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/screens/map/map_screen.dart';
import 'package:vortex_dashboard/screens/groups/group_tab.dart';
import 'package:vortex_dashboard/screens/notifications/notifications_tab.dart';
import 'package:vortex_dashboard/screens/settings/settings_tab.dart';
import 'package:vortex_dashboard/screens/geofence/geofence_screen.dart';
import 'package:vortex_dashboard/widgets/common/side_drawer.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;
  bool _tabInitialized = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    if (!_tabInitialized) {
      final groups = ref.read(groupsProvider).valueOrNull ?? [];
      if (groups.isNotEmpty) {
        final hasRealGroup = groups.any((g) => g.memberCount > 1 || !g.isOwner);
        if (!hasRealGroup) {
          _currentIndex = 1;
        }
        _tabInitialized = true;
      }
    }
    final pages = <Widget>[
      const MapScreen(isEmbeddedInShell: true),
      const GroupTab(),
      const SizedBox(),
      const NotificationsTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: SideDrawer(
        onNavigate: (tab) => setState(() => _currentIndex = tab),
        onJoinGroup: _showJoinGroup,
        onCreateGroup: _showCreateGroup,
      ),
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
            _actionTile(Icons.add_circle_outline, 'Create Group', () { Navigator.pop(context); _showCreateGroup(); }),
            _actionTile(Icons.link, 'Join Group', () { Navigator.pop(context); _showJoinGroup(); }),
            _actionTile(Icons.place, 'Add Place', () { Navigator.pop(context); _addPlace(); }),
            _actionTile(Icons.shield_outlined, 'Create Geofence', () { Navigator.pop(context); _createGeofence(); }),
            _actionTile(Icons.list_alt, 'Manage Places', () { Navigator.pop(context); _manageGeofences(); }),
            _actionTile(Icons.share, 'Share Location', () { Navigator.pop(context); _shareLocation(); }),
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

  void _showCreateGroup() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Group', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Group name', hintStyle: TextStyle(color: Colors.white38),
            filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final g = await ref.read(groupActionsProvider).create(name);
              final invite = await ref.read(groupActionsProvider).createInvite(g.id);
              final code = invite['code'] as String? ?? invite['invite_code'] as String? ?? '--';
              ref.read(groupActionsProvider).refresh();
              setState(() => _currentIndex = 1);
              if (mounted) _showInviteCode(code);
            },
            child: const Text('Create', style: TextStyle(color: ThemeConstants.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showInviteCode(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Invite Code', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with friends to join your group:',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(code,
                  style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 8,
                    color: ThemeConstants.primaryColor,
                  )),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            child: const Text('Copy', style: TextStyle(color: ThemeConstants.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showJoinGroup() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Join Group', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter 6-character invite code', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ThemeConstants.primaryColor, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '', hintText: '------',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 28, letterSpacing: 8),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();
              if (code.length != 6) return;
              Navigator.pop(ctx);
              try {
                await ref.read(groupActionsProvider).join(code);
                ref.read(groupActionsProvider).refresh();
                setState(() => _currentIndex = 1);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joined group'), duration: Duration(seconds: 2)),
                );
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Join', style: TextStyle(color: ThemeConstants.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _addPlace() {
    final loc = ref.read(currentLocationProvider);
    final lat = loc['lat'] ?? 0.0;
    final lng = loc['lng'] ?? 0.0;
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Place', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Place name (e.g. Home, Work)', hintStyle: TextStyle(color: Colors.white38),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final gf = Geofence(
                id: const Uuid().v4(), name: name, type: GeofenceType.custom,
                latitude: lat, longitude: lng, radiusMeters: 25,
              );
              await ref.read(geofenceListProvider.notifier).add(gf);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved "$name"'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Save', style: TextStyle(color: ThemeConstants.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _createGeofence() {
    final loc = ref.read(currentLocationProvider);
    final lat = loc['lat'] ?? 0.0;
    final lng = loc['lng'] ?? 0.0;
    final nameCtrl = TextEditingController();
    int radiusMeters = 25;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ThemeConstants.darkBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Geofence', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Label (e.g. Home, Work)', hintStyle: TextStyle(color: Colors.white38),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Radius', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [25, 50, 100].map((r) {
                  final active = radiusMeters == r;
                  return ChoiceChip(
                    label: Text('${r}m'),
                    selected: active,
                    onSelected: (_) => setDialogState(() => radiusMeters = r),
                    selectedColor: ThemeConstants.primaryColor.withValues(alpha: 0.3),
                    labelStyle: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.w600),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                final gf = Geofence(
                  id: const Uuid().v4(), name: name, type: GeofenceType.custom,
                  latitude: lat, longitude: lng, radiusMeters: radiusMeters.toDouble(),
                );
                await ref.read(geofenceListProvider.notifier).add(gf);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Geofence "$name" (${radiusMeters}m)'), duration: Duration(seconds: 2)),
                );
              },
              child: const Text('Save', style: TextStyle(color: ThemeConstants.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _manageGeofences() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceScreen()));
  }

  void _shareLocation() {
    final loc = ref.read(currentLocationProvider);
    final lat = loc['lat'] ?? 0.0;
    final lng = loc['lng'] ?? 0.0;
    final url = 'https://maps.google.com/?q=$lat,$lng';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location link copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }
}
