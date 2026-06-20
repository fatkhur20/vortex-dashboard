import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/providers/altimeter_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/widgets/common/stat_tile.dart';
import 'package:vortex_dashboard/core/utils/extensions.dart';

class TripAnalyticsScreen extends ConsumerStatefulWidget {
  const TripAnalyticsScreen({super.key});

  @override
  ConsumerState<TripAnalyticsScreen> createState() => _TripAnalyticsScreenState();
}

class _TripAnalyticsScreenState extends ConsumerState<TripAnalyticsScreen> {
  final List<FlSpot> _speedSpots = [];
  final List<FlSpot> _altitudeSpots = [];

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingStateProvider);
    final altimeter = ref.watch(altimeterStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRIP ANALYTICS'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsOverview(tracking),
              const SizedBox(height: 16),
              _buildChartSection(
                'SPEED OVER TIME',
                Icons.speed,
                _speedSpots,
                ThemeConstants.primaryColor,
                'km/h',
              ),
              const SizedBox(height: 16),
              _buildChartSection(
                'ALTITUDE OVER TIME',
                Icons.height,
                _altitudeSpots,
                ThemeConstants.warningColor,
                'm',
              ),
              const SizedBox(height: 16),
              _buildRideStats(tracking, altimeter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(tracking) {
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.speed, color: ThemeConstants.primaryColor, size: 24),
              const SizedBox(height: 4),
              Text(
                '${tracking.maxSpeed.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Max KM/H',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.straighten, color: ThemeConstants.warningColor, size: 24),
              const SizedBox(height: 4),
              Text(
                '${tracking.totalDistance.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total KM',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.timer, color: ThemeConstants.successColor, size: 24),
              const SizedBox(height: 4),
              Text(
                tracking.currentRide?.duration.shortFormat ?? '00:00',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Duration',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
    String title,
    IconData icon,
    List<FlSpot> spots,
    Color color,
    String unit,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'Start tracking to see chart',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withValues(alpha: 0.05),
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}s',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 10,
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.3),
                                color.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(1)} $unit',
                                TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideStats(tracking, altimeter) {
    return GlassCard(
      child: Column(
        children: [
          StatTile(
            label: 'Max Speed',
            value: '${tracking.maxSpeed.toStringAsFixed(1)} km/h',
            icon: Icons.trending_up,
            valueColor: ThemeConstants.warningColor,
          ),
          const Divider(),
          StatTile(
            label: 'Total Distance',
            value: '${tracking.totalDistance.toStringAsFixed(2)} km',
            icon: Icons.straighten,
          ),
          const Divider(),
          StatTile(
            label: 'Max Altitude',
            value: '${altimeter.maxAltitude.toStringAsFixed(0)} m',
            icon: Icons.height,
          ),
          const Divider(),
          StatTile(
            label: 'Min Altitude',
            value: '${altimeter.minAltitude.toStringAsFixed(0)} m',
            icon: Icons.height,
          ),
          const Divider(),
          StatTile(
            label: 'Ride Duration',
            value: tracking.currentRide?.duration.shortFormat ?? '00:00',
            icon: Icons.timer,
          ),
        ],
      ),
    );
  }
}
