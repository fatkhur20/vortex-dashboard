import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/performance_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/widgets/common/stat_tile.dart';
import 'package:vortex_dashboard/core/utils/extensions.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  bool _isMonitoring = false;

  @override
  Widget build(BuildContext context) {
    final perf = ref.watch(performanceProvider);
    final gpsData = ref.watch(gpsDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PERFORMANCE'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCurrentSpeed(gpsData.speed),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: _buildTimerDisplay(
                        '0-60 km/h',
                        perf.zeroToSixtyTime,
                        Icons.speed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      child: _buildTimerDisplay(
                        '0-100 km/h',
                        perf.zeroToHundredTime,
                        Icons.speed,
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
                      child: _buildTimerDisplay(
                        'Quarter Mile',
                        perf.quarterMileTime,
                        Icons.timer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        children: [
                          Icon(Icons.timer, color: ThemeConstants.primaryColor, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            perf.rideDuration.shortFormat,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildLabel('Duration'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    StatTile(
                      label: 'Current Speed',
                      value: '${gpsData.speed.toStringAsFixed(1)} km/h',
                      icon: Icons.speed,
                      valueColor: gpsData.speed.speedColor,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Maximum Speed',
                      value: '${perf.maxSpeed.toStringAsFixed(1)} km/h',
                      icon: Icons.trending_up,
                      valueColor: ThemeConstants.warningColor,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Average Speed',
                      value: '${perf.averageSpeed.toStringAsFixed(1)} km/h',
                      icon: Icons.analytics,
                    ),
                    const Divider(),
                    StatTile(
                      label: 'Distance (est.)',
                      value: '${(perf.averageSpeed * perf.rideDuration.inHours).toStringAsFixed(2)} km',
                      icon: Icons.route,
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
                      if (_isMonitoring) {
                        ref.read(performanceProvider.notifier)
                            .stopPerformanceMonitoring();
                        setState(() => _isMonitoring = false);
                      } else {
                        ref.read(performanceProvider.notifier)
                            .startPerformanceMonitoring();
                        setState(() => _isMonitoring = true);
                      }
                    },
                    icon: Icon(
                      _isMonitoring ? Icons.stop : Icons.play_arrow,
                      color: _isMonitoring
                          ? ThemeConstants.errorColor
                          : ThemeConstants.successColor,
                    ),
                    label: Text(
                      _isMonitoring ? 'STOP MONITORING' : 'START MONITORING',
                      style: TextStyle(
                        color: _isMonitoring
                            ? ThemeConstants.errorColor
                            : ThemeConstants.successColor,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isMonitoring) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: GlassCard(
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(performanceProvider.notifier).reset();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: const Text(
                        'RESET',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSpeed(double speed) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            '${speed.toStringAsFixed(0)}',
            style: TextStyle(
              color: speed.speedColor,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: speed.speedColor.withOpacity(0.3),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
          _buildLabel('CURRENT SPEED (KM/H)'),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(String label, double? time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ThemeConstants.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          time != null ? '${time.toStringAsFixed(2)}s' : '--:--',
          style: TextStyle(
            color: time != null ? Colors.white : Colors.white.withOpacity(0.3),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildLabel(label),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 10,
        letterSpacing: 1,
      ),
    );
  }
}
