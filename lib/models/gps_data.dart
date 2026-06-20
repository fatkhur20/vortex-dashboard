class GpsData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double accuracy;
  final double heading;
  final int? satelliteCount;
  final DateTime timestamp;

  GpsData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.accuracy,
    required this.heading,
    this.satelliteCount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  GpsData copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? accuracy,
    double? heading,
    int? satelliteCount,
    DateTime? timestamp,
  }) {
    return GpsData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      satelliteCount: satelliteCount ?? this.satelliteCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'accuracy': accuracy,
      'heading': heading,
      'satelliteCount': satelliteCount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GpsData.fromJson(Map<String, dynamic> json) {
    return GpsData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      satelliteCount: json['satelliteCount'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
