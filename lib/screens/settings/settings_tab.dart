import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/settings_provider.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  bool _showDevMode = false;

  @override
  Widget build(BuildContext context) {
    final useKmh = ref.watch(useKmhProvider);
    final themeMode = ref.watch(themeModeProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final memberCount = ref.watch(activeGroupMembersProvider).length;
    final uid = ref.watch(userIdProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.amoledBackground,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Profile'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ThemeConstants.primaryColor.withValues(alpha: 0.15),
                  ),
                  child: const Center(child: Text('📍', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Display Name', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(memberCount > 0 ? '${memberCount} group${memberCount == 1 ? '' : 's'}' : 'No groups',
                          style: TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Tracking'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _switchTile(Icons.gps_fixed, 'Location Sharing', true, (_) {}),
                const Divider(color: Colors.white12, height: 8),
                _switchTile(Icons.battery_charging_full, 'Background Tracking', false, (_) {}),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Notifications'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _switchTile(Icons.place, 'Arrival Alerts', false, (_) {}),
                const Divider(color: Colors.white12, height: 8),
                _switchTile(Icons.departure_board, 'Departure Alerts', false, (_) {}),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Appearance'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _switchTile(Icons.speed, 'km/h', useKmh, (v) => ref.read(useKmhProvider.notifier).toggle()),
                const Divider(color: Colors.white12, height: 8),
                _switchTile(
                  themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  'Dark Theme',
                  themeMode == ThemeMode.dark,
                  (v) => ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Developer'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _switchTile(Icons.developer_mode, 'Developer Mode', _showDevMode, (v) {
                  setState(() => _showDevMode = v);
                }),
                if (_showDevMode) ...[
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('User ID', uid ?? '--'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Groups', '${groupsAsync.valueOrNull?.length ?? 0}'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Members', '$memberCount'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('FPS', '0'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Map Style', 'Satellite Hybrid'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('3D', _show3DGlobal ? 'ON' : 'OFF'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Terrain', 'ON'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Globe', 'OFF'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle('About'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow('Version', '1.0.0'),
                const Divider(color: Colors.white12, height: 8),
                _infoRow('Build', '2025.08'),
                const Divider(color: Colors.white12, height: 8),
                _infoRow('Worker', 'vortex-tracker.vortex-x.workers.dev'),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
    );
  }

  Widget _switchTile(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: ThemeConstants.primaryColor, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: ThemeConstants.primaryColor,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  bool get _show3DGlobal => false;
}
