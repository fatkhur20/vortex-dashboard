class SpeedRecord {
  final DateTime timestamp;
  final double speed;
  final double? altitude;

  SpeedRecord({
    required this.timestamp,
    required this.speed,
    this.altitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'altitude': altitude,
    };
  }

  factory SpeedRecord.fromJson(Map<String, dynamic> json) {
    return SpeedRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
    );
  }
}
