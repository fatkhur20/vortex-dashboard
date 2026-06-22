import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/settings_provider.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/providers/activity_provider.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/services/notification_service.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

final locationSharingProvider = StateProvider<bool>((ref) => true);
final backgroundTrackingProvider = StateProvider<bool>((ref) => false);
final arrivalAlertsProvider = StateProvider<bool>((ref) => false);
final departureAlertsProvider = StateProvider<bool>((ref) => false);
final devModeProvider = StateProvider<bool>((ref) => false);

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(locationSharingProvider.notifier).state = prefs.getBool('location_sharing') ?? true;
    ref.read(backgroundTrackingProvider.notifier).state = prefs.getBool('background_tracking') ?? false;
    ref.read(arrivalAlertsProvider.notifier).state = prefs.getBool('arrival_alerts') ?? false;
    ref.read(departureAlertsProvider.notifier).state = prefs.getBool('departure_alerts') ?? false;
    ref.read(devModeProvider.notifier).state = prefs.getBool('dev_mode') ?? false;
  }

  Future<void> _persist(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final useKmh = ref.watch(useKmhProvider);
    final themeMode = ref.watch(themeModeProvider);
    final gpsData = ref.watch(gpsDataProvider);
    final compassHeading = ref.watch(compassHeadingProvider);
    final uid = ref.watch(userIdProvider);
    final members = ref.watch(activeGroupMembersProvider);
    final gpsH = gpsData?.heading ?? -1;
    final speed = gpsData?.speed ?? 0;
    final loc = ref.watch(currentLocationProvider);
    final activityAsync = ref.watch(currentActivityLabelProvider);
    final memberCount = members.length;

    final locationSharing = ref.watch(locationSharingProvider);
    final backgroundTracking = ref.watch(backgroundTrackingProvider);
    final arrivalAlerts = ref.watch(arrivalAlertsProvider);
    final departureAlerts = ref.watch(departureAlertsProvider);
    final devMode = ref.watch(devModeProvider);

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
                      Text('$memberCount group${memberCount == 1 ? '' : 's'}',
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
                _switchTile(Icons.gps_fixed, 'Location Sharing', locationSharing, (v) {
                  ref.read(locationSharingProvider.notifier).state = v;
                  _persist('location_sharing', v);
                  if (!v) ref.read(trackingServiceProvider).stopSync();
                  else ref.read(trackingServiceProvider).startSync(ref, groupId: ref.read(trackingServiceProvider).activeGroupId ?? '');
                }),
                const Divider(color: Colors.white12, height: 8),
                _switchTile(Icons.battery_charging_full, 'Background Tracking', backgroundTracking, (v) {
                  ref.read(backgroundTrackingProvider.notifier).state = v;
                  _persist('background_tracking', v);
                  if (v) _startBackgroundService();
                  else _stopBackgroundService();
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Notifications'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _switchTile(Icons.place, 'Arrival Alerts', arrivalAlerts, (v) {
                  ref.read(arrivalAlertsProvider.notifier).state = v;
                  _persist('arrival_alerts', v);
                  if (v) notificationService.addArrival('Test', 'Home');
                }),
                const Divider(color: Colors.white12, height: 8),
                _switchTile(Icons.departure_board, 'Departure Alerts', departureAlerts, (v) {
                  ref.read(departureAlertsProvider.notifier).state = v;
                  _persist('departure_alerts', v);
                  if (v) notificationService.addDeparture('Test', 'Home');
                }),
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
                _switchTile(Icons.developer_mode, 'Developer Mode', devMode, (v) {
                  ref.read(devModeProvider.notifier).state = v;
                  _persist('dev_mode', v);
                }),
                if (devMode) ...[
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('User ID', uid ?? '--'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('FPS', '0'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('GPS Accuracy', '${(gpsData?.accuracy ?? 0).toStringAsFixed(1)}m'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Heading', '${gpsH >= 0 ? gpsH.toStringAsFixed(1) : "---"}\u{00B0}'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Compass', '${compassHeading.toStringAsFixed(1)}\u{00B0}'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Speed', '${speed.toStringAsFixed(1)} km/h'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Location', '${(loc["lat"] ?? 0).toStringAsFixed(4)}, ${(loc["lng"] ?? 0).toStringAsFixed(4)}'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Activity', activityAsync.valueOrNull ?? '--'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Members', '$memberCount'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Groups', '${ref.watch(groupsProvider).valueOrNull?.length ?? 0}'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Upload', 'Every 10s'),
                  const Divider(color: Colors.white12, height: 8),
                  _infoRow('Poll', 'Every 5s'),
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

  void _startBackgroundService() {
    // Android foreground service would be started here via MethodChannel
    debugPrint('Background tracking started');
  }

  void _stopBackgroundService() {
    // Android foreground service would be stopped here via MethodChannel
    debugPrint('Background tracking stopped');
  }
}
