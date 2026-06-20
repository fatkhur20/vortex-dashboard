import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/settings_provider.dart';
import 'package:vortex_dashboard/widgets/common/section_title.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  @override
  void dispose() {
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  String _formatGpsRate(int ms) {
    return '${ms ~/ 1000}s';
  }

  String _formatSpeedLimit(double limit) {
    final useKmh = ref.read(useKmhProvider);
    if (useKmh) {
      return '${limit.toInt()} km/h';
    }
    return '${(limit * 0.621371).toInt()} mph';
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Clear All Data',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all your data, including ride history, settings, and saved preferences. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: ThemeConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useKmh = ref.watch(useKmhProvider);
    final amoled = ref.watch(amoledModeProvider);
    final aod = ref.watch(alwaysOnDisplayProvider);
    final gpsRate = ref.watch(gpsRefreshRateProvider);
    final speedAlert = ref.watch(speedAlertProvider);
    final voiceAlerts = ref.watch(voiceAlertsProvider);
    final backgroundTracking = ref.watch(backgroundTrackingProvider);
    final autoRide = ref.watch(autoRideDetectionProvider);
    final crashDetection = ref.watch(crashDetectionProvider);

    return Scaffold(
      backgroundColor: amoled
          ? ThemeConstants.amoledBackground
          : ThemeConstants.darkBackground,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SectionTitle(title: 'Units', icon: Icons.speed),
          _buildSwitchTile(
            title: 'KM/H',
            subtitle: 'Use kilometers per hour',
            value: useKmh,
            onChanged: (_) => ref.read(useKmhProvider.notifier).toggle(),
            trailing: Text(
              'MPH',
              style: TextStyle(
                color: ThemeConstants.primaryColor.withValues(alpha: !useKmh ? 1 : 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SectionTitle(title: 'Display', icon: Icons.display_settings),
          _buildSwitchTile(
            title: 'AMOLED Mode',
            subtitle: 'Pure black background for OLED screens',
            value: amoled,
            onChanged: (_) => ref.read(amoledModeProvider.notifier).toggle(),
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Screen Always On',
            subtitle: 'Keep display active while riding',
            value: aod,
            onChanged: (_) => ref.read(alwaysOnDisplayProvider.notifier).toggle(),
          ),

          const SectionTitle(title: 'GPS', icon: Icons.gps_fixed),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Refresh Rate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatGpsRate(gpsRate),
                      style: TextStyle(
                        color: ThemeConstants.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'GPS location update interval',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: ThemeConstants.primaryColor,
                    inactiveTrackColor: ThemeConstants.primaryColor.withValues(alpha: 0.2),
                    thumbColor: ThemeConstants.primaryColor,
                    overlayColor: ThemeConstants.primaryColor.withValues(alpha: 0.1),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: gpsRate.toDouble(),
                    min: 1000,
                    max: 5000,
                    divisions: 2,
                    onChanged: (v) =>
                        ref.read(gpsRefreshRateProvider.notifier).set(v.toInt()),
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Alerts', icon: Icons.notifications),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Speed Alert',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Notify when speed exceeds limit',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: speedAlert.enabled,
                      onChanged: (_) =>
                          ref.read(speedAlertProvider.notifier).toggle(),
                      activeColor: ThemeConstants.primaryColor,
                    ),
                  ],
                ),
                if (speedAlert.enabled) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Speed Limit',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatSpeedLimit(speedAlert.limit),
                        style: TextStyle(
                          color: ThemeConstants.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: ThemeConstants.primaryColor,
                      inactiveTrackColor: ThemeConstants.primaryColor.withValues(alpha: 0.2),
                      thumbColor: ThemeConstants.primaryColor,
                      overlayColor: ThemeConstants.primaryColor.withValues(alpha: 0.1),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: speedAlert.limit,
                      min: 20,
                      max: 250,
                      divisions: 46,
                      onChanged: (v) =>
                          ref.read(speedAlertProvider.notifier).setLimit(v),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Voice Alerts',
            subtitle: 'Spoken alerts for speed and navigation',
            value: voiceAlerts,
            onChanged: (_) => ref.read(voiceAlertsProvider.notifier).toggle(),
          ),

          const SectionTitle(title: 'Tracking', icon: Icons.track_changes),
          _buildSwitchTile(
            title: 'Background Tracking',
            subtitle: 'Continue tracking when app is minimized',
            value: backgroundTracking,
            onChanged: (_) =>
                ref.read(backgroundTrackingProvider.notifier).toggle(),
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Auto Ride Detection',
            subtitle: 'Automatically detect when a ride starts',
            value: autoRide,
            onChanged: (_) =>
                ref.read(autoRideDetectionProvider.notifier).toggle(),
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Crash Detection',
            subtitle: 'Detect sudden deceleration and send alerts',
            value: crashDetection,
            onChanged: (_) =>
                ref.read(crashDetectionProvider.notifier).toggle(),
          ),

          const SectionTitle(title: 'Emergency', icon: Icons.emergency),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contact',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This contact will be notified in case of emergency',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emergencyNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contact Name',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: ThemeConstants.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: ThemeConstants.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GlassCard.neon(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextButton(
                      onPressed: () {
                        final name = _emergencyNameController.text.trim();
                        final phone = _emergencyPhoneController.text.trim();
                        if (name.isNotEmpty && phone.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Emergency contact saved'),
                              backgroundColor:
                                  ThemeConstants.successColor.withValues(alpha: 0.8),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('Please fill in all fields'),
                              backgroundColor:
                                  ThemeConstants.warningColor.withValues(alpha: 0.8),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'SAVE CONTACT',
                        style: TextStyle(
                          color: ThemeConstants.primaryColor,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Data', icon: Icons.storage),
          _buildDataTile(
            icon: Icons.upload_file,
            title: 'Export Settings',
            subtitle: 'Save your configuration to a file',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildDataTile(
            icon: Icons.download,
            title: 'Import Settings',
            subtitle: 'Restore configuration from a file',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildDataTile(
            icon: Icons.delete_forever,
            title: 'Clear All Data',
            subtitle: 'Remove all app data and reset settings',
            iconColor: ThemeConstants.errorColor,
            onTap: _showClearDataDialog,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing,
            const SizedBox(width: 12),
          ],
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDataTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? ThemeConstants.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
