import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/widgets/common/stat_tile.dart';

class GpsStatusScreen extends ConsumerWidget {
  const GpsStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsData = ref.watch(gpsDataProvider);

    final signalStrength = _getSignalStrength(gpsData.accuracy);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS STATUS'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSignalStrengthCard(signalStrength),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    StatTile(
                      label: 'Latitude',
                      value: gpsData.latitude.toStringAsFixed(6),
                      icon: Icons.public,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Longitude',
                      value: gpsData.longitude.toStringAsFixed(6),
                      icon: Icons.public,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'GPS Accuracy',
                      value: '${gpsData.accuracy.toStringAsFixed(1)} m',
                      icon: Icons.my_location,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Speed',
                      value: '${gpsData.speed.toStringAsFixed(1)} km/h',
                      icon: Icons.speed,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Altitude',
                      value: '${gpsData.altitude.toStringAsFixed(1)} m',
                      icon: Icons.height,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Heading',
                      value: '${gpsData.heading.toStringAsFixed(1)}\u00B0',
                      icon: Icons.explore,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Timestamp',
                      value: gpsData.timestamp.toIso8601String(),
                      icon: Icons.access_time,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    StatTile(
                      label: 'Speed Source',
                      value: 'GPS',
                      icon: Icons.satellite_alt,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Position Source',
                      value: gpsData.accuracy < 10 ? 'GPS Fix' : 'Approximate',
                      icon: Icons.satellite,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Fix Quality',
                      value: gpsData.accuracy < 5
                          ? 'Excellent'
                          : gpsData.accuracy < 15
                              ? 'Good'
                              : gpsData.accuracy < 30
                                  ? 'Fair'
                                  : 'Poor',
                      icon: Icons.signal_cellular_alt,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalStrengthCard(double strength) {
    final bars = _getSignalBars(strength);

    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIGNAL STRENGTH',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getSignalLabel(strength),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(
              5,
              (index) => Container(
                width: 8,
                height: 8 + (index * 8).toDouble(),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index < bars
                      ? _getSignalColor(strength)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getSignalBars(double accuracy) {
    if (accuracy < 5) return 5;
    if (accuracy < 10) return 4;
    if (accuracy < 20) return 3;
    if (accuracy < 50) return 2;
    return 1;
  }

  String _getSignalStrength(double accuracy) {
    if (accuracy < 5) return 'Strong';
    if (accuracy < 10) return 'Good';
    if (accuracy < 20) return 'Fair';
    if (accuracy < 50) return 'Weak';
    return 'Very Weak';
  }

  String _getSignalLabel(double accuracy) {
    if (accuracy < 5) return 'Excellent';
    if (accuracy < 10) return 'Good';
    if (accuracy < 20) return 'Fair';
    if (accuracy < 50) return 'Weak';
    return 'No Signal';
  }

  Color _getSignalColor(double accuracy) {
    if (accuracy < 5) return ThemeConstants.speedLow;
    if (accuracy < 10) return ThemeConstants.speedMedium;
    if (accuracy < 20) return ThemeConstants.warningColor;
    return ThemeConstants.errorColor;
  }
}
