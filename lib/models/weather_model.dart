class WeatherModel {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final double windDeg;
  final String condition;
  final String description;
  final String icon;
  final double visibility;
  final double pressure;
  final String cityName;
  final String country;
  final DateTime timestamp;
  final bool isDay;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.condition,
    required this.description,
    required this.icon,
    required this.visibility,
    required this.pressure,
    required this.cityName,
    required this.country,
    required this.timestamp,
    required this.isDay,
  });

  String get windDirection {
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((windDeg + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  String get visibilityFormatted {
    if (visibility >= 1000) {
      return '${(visibility / 1000).toStringAsFixed(1)} km';
    }
    return '${visibility.toStringAsFixed(0)} m';
  }

  String get weatherEmoji {
    switch (condition.toLowerCase()) {
      case 'clear':
        return isDay ? '\u2600\uFE0F' : '\uD83C\uDF19';
      case 'clouds':
        return '\u2601\uFE0F';
      case 'rain':
      case 'drizzle':
        return '\uD83C\uDF27\uFE0F';
      case 'thunderstorm':
        return '\u26C8\uFE0F';
      case 'snow':
        return '\u2744\uFE0F';
      case 'mist':
      case 'fog':
      case 'haze':
        return '\uD83C\uDF2B\uFE0F';
      default:
        return '\u2601\uFE0F';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDeg': windDeg,
      'condition': condition,
      'description': description,
      'icon': icon,
      'visibility': visibility,
      'pressure': pressure,
      'cityName': cityName,
      'country': country,
      'timestamp': timestamp.toIso8601String(),
      'isDay': isDay,
    };
  }

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      windDeg: (json['windDeg'] as num).toDouble(),
      condition: json['condition'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      visibility: (json['visibility'] as num).toDouble(),
      pressure: (json['pressure'] as num).toDouble(),
      cityName: json['cityName'] as String,
      country: json['country'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isDay: json['isDay'] as bool,
    );
  }
}
