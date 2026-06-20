import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/altimeter_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/widgets/gauges/altimeter_gauge.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/widgets/common/stat_tile.dart';

class AltimeterScreen extends ConsumerStatefulWidget {
  const AltimeterScreen({super.key});

  @override
  ConsumerState<AltimeterScreen> createState() => _AltimeterScreenState();
}

class _AltimeterScreenState extends ConsumerState<AltimeterScreen> {
  @override
  Widget build(BuildContext context) {
    final altimeterState = ref.watch(altimeterStateProvider);
    final gpsData = ref.watch(gpsDataProvider);
    final altitude = gpsData?.altitude ?? 0;

    ref.read(altimeterStateProvider.notifier).updateAltitude(altitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ALTIMETER'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AltimeterGauge(
                altitude: altitude,
                maxAltitude: altimeterState.maxAltitude,
                minAltitude: altimeterState.minAltitude,
                size: 220,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        children: [
                          _buildValue('CURRENT', altitude, 'm'),
                          const SizedBox(height: 8),
                          _buildLabel('Current Altitude'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        children: [
                          _buildValue('MAX', altimeterState.maxAltitude, 'm',
                              color: ThemeConstants.warningColor),
                          const SizedBox(height: 8),
                          _buildLabel('Maximum Altitude'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        children: [
                          _buildValue('MIN', altimeterState.minAltitude, 'm',
                              color: ThemeConstants.primaryColor),
                          const SizedBox(height: 8),
                          _buildLabel('Minimum Altitude'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        children: [
                          _buildValue(
                            'RANGE',
                            altimeterState.maxAltitude - altimeterState.minAltitude,
                            'm',
                            color: ThemeConstants.secondaryColor,
                          ),
                          const SizedBox(height: 8),
                          _buildLabel('Total Range'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  children: [
                    StatTile(
                      label: 'GPS Accuracy',
                      value: '${(gpsData?.accuracy ?? 0).toStringAsFixed(1)} m',
                      icon: Icons.my_location,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Latitude',
                      value: (gpsData?.latitude ?? 0).toStringAsFixed(6),
                      icon: Icons.public,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Longitude',
                      value: (gpsData?.longitude ?? 0).toStringAsFixed(6),
                      icon: Icons.public,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GlassCard.neon(
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(altimeterStateProvider.notifier).reset();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    label: const Text(
                      'RESET ALTIMETER',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValue(String label, double value, String unit, {Color? color}) {
    return Text(
      '${value.toStringAsFixed(1)} $unit',
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 10,
        letterSpacing: 1,
      ),
    );
  }
}
