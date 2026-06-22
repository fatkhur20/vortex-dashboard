class PartnerLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double heading;
  final double? batteryLevel;
  final String activity;
  final bool isOnline;
  final bool isMoving;
  final DateTime? timestamp;
  final DateTime? lastSeen;

  const PartnerLocation({
    required this.id, required this.name, required this.latitude, required this.longitude,
    this.altitude = 0, this.speed = 0, this.heading = 0, this.batteryLevel,
    this.activity = 'Stationary', this.isOnline = false, this.isMoving = false,
    this.timestamp, this.lastSeen,
  });

  PartnerLocation copyWith({
    double? latitude, double? longitude, double? altitude, double? speed,
    double? heading, double? batteryLevel, String? activity, bool? isOnline,
    bool? isMoving, DateTime? timestamp, DateTime? lastSeen, String? name,
  }) => PartnerLocation(
    id: id, name: name ?? this.name,
    latitude: latitude ?? this.latitude, longitude: longitude ?? this.longitude,
    altitude: altitude ?? this.altitude, speed: speed ?? this.speed,
    heading: heading ?? this.heading, batteryLevel: batteryLevel ?? this.batteryLevel,
    activity: activity ?? this.activity, isOnline: isOnline ?? this.isOnline,
    isMoving: isMoving ?? this.isMoving, timestamp: timestamp ?? this.timestamp,
    lastSeen: lastSeen ?? this.lastSeen,
  );
}

class CoupleData {
  final double distanceKm;
  final int etaMinutes;
  final String activity;
  final double? batteryLevel;

  const CoupleData({
    this.distanceKm = 0, this.etaMinutes = 0,
    this.activity = 'Stationary', this.batteryLevel,
  });
}
