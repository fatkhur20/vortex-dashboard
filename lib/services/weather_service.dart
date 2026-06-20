import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vortex_dashboard/models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<WeatherModel> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,'
            'weather_code,wind_speed_10m,wind_direction_10m,visibility,'
            'surface_pressure,is_day',
        'timezone': 'auto',
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseWeatherResponse(data);
      }

      throw Exception('Failed to load weather: ${response.statusCode}');
    } catch (e) {
      return _getFallbackWeather();
    }
  }

  WeatherModel _parseWeatherResponse(Map<String, dynamic> data) {
    final current = data['current'];
    final cityName = _extractCityName(data);

    return WeatherModel(
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      windDeg: (current['wind_direction_10m'] as num).toDouble(),
      condition: _getWeatherCondition(current['weather_code'] as int),
      description: _getWeatherDescription(current['weather_code'] as int),
      icon: _getWeatherIcon(current['weather_code'] as int),
      visibility: (current['visibility'] as num?)?.toDouble() ?? 10000,
      pressure: (current['surface_pressure'] as num).toDouble(),
      cityName: cityName,
      country: '',
      timestamp: DateTime.now(),
      isDay: (current['is_day'] as int) == 1,
    );
  }

  String _extractCityName(Map<String, dynamic> data) {
    try {
      final timezone = data['timezone'] as String? ?? '';
      if (timezone.contains('/')) {
        return timezone.split('/').last.replaceAll('_', ' ');
      }
    } catch (_) {}
    return 'Current Location';
  }

  Future<String> getCityName(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(_geocodingUrl).replace(queryParameters: {
        'name': '$latitude,$longitude',
        'count': '1',
        'language': 'en',
        'format': 'json',
      });
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['name'] as String? ?? 'Unknown';
        }
      }
    } catch (_) {}
    return 'Unknown';
  }

  String _getWeatherCondition(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Clouds';
    if (code <= 48) return 'Fog';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain';
    if (code <= 86) return 'Snow';
    return 'Thunderstorm';
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code == 1) return 'Mainly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    return 'Thunderstorm';
  }

  String _getWeatherIcon(int code) {
    if (code == 0) return '01d';
    if (code == 1) return '02d';
    if (code == 2) return '03d';
    if (code == 3) return '04d';
    if (code <= 48) return '50d';
    if (code <= 57) return '09d';
    if (code <= 67) return '10d';
    if (code <= 77) return '13d';
    if (code <= 82) return '09d';
    if (code <= 86) return '13d';
    return '11d';
  }

  WeatherModel _getFallbackWeather() {
    return WeatherModel(
      temperature: 22,
      feelsLike: 20,
      humidity: 60,
      windSpeed: 10,
      windDeg: 180,
      condition: 'Clear',
      description: 'Weather data unavailable',
      icon: '01d',
      visibility: 10000,
      pressure: 1013,
      cityName: 'Offline',
      country: '',
      timestamp: DateTime.now(),
      isDay: true,
    );
  }
}
