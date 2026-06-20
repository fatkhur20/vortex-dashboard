import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/weather_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/widgets/common/stat_tile.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WEATHER'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(weatherProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: weatherAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Colors.white.withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Weather data unavailable',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your internet connection',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (weather) => _buildWeatherContent(context, weather),
        ),
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context, weather) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard.neon(
            child: Column(
              children: [
                Text(
                  weather.weatherEmoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 8),
                Text(
                  '${weather.temperature.toStringAsFixed(1)}\u00B0C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather.description.toUpperCase(),
                  style: TextStyle(
                    color: ThemeConstants.primaryColor,
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather.cityName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: _buildWeatherStat(
                    Icons.thermostat,
                    'Feels Like',
                    '${weather.feelsLike.toStringAsFixed(1)}\u00B0C',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  child: _buildWeatherStat(
                    Icons.water_drop,
                    'Humidity',
                    '${weather.humidity.toStringAsFixed(0)}%',
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
                  child: _buildWeatherStat(
                    Icons.air,
                    'Wind Speed',
                    '${weather.windSpeed.toStringAsFixed(1)} km/h',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  child: _buildWeatherStat(
                    Icons.explore,
                    'Wind Direction',
                    weather.windDirection,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                StatTile(
                  label: 'Visibility',
                  value: weather.visibilityFormatted,
                  icon: Icons.visibility,
                ),
                const Divider(),
                StatTile(
                  label: 'Pressure',
                  value: '${weather.pressure.toStringAsFixed(0)} hPa',
                  icon: Icons.speed,
                ),
                const Divider(),
                StatTile(
                  label: 'Condition',
                  value: weather.condition,
                  icon: Icons.wb_cloudy,
                ),
                const Divider(),
                StatTile(
                  label: 'Updated',
                  value: weather.timestamp.toIso8601String(),
                  icon: Icons.access_time,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: ThemeConstants.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
