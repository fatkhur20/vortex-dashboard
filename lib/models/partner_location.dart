import 'dart:convert';

class PartnerLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? heading;
  final double? batteryLevel;
  final String? activity;
  final bool isOnline;
  final bool isMoving;
  final DateTime timestamp;
  final DateTime? lastSeen;

  PartnerLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    this.batteryLevel,
    this.activity,
    this.isOnline = false,
    this.isMoving = false,
    DateTime? timestamp,
    this.lastSeen,
  }) : timestamp = timestamp ?? DateTime.now();

  double get distanceToUser => 0;

  String get lastSeenAgo {
    if (lastSeen == null) return 'Never';
    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  PartnerLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? heading,
    double? batteryLevel,
    String? activity,
    bool? isOnline,
    bool? isMoving,
    DateTime? timestamp,
    DateTime? lastSeen,
  }) {
    return PartnerLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      activity: activity ?? this.activity,
      isOnline: isOnline ?? this.isOnline,
      isMoving: isMoving ?? this.isMoving,
      timestamp: timestamp ?? this.timestamp,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'latitude': latitude, 'longitude': longitude,
    'altitude': altitude, 'speed': speed, 'heading': heading,
    'batteryLevel': batteryLevel, 'activity': activity,
    'isOnline': isOnline, 'isMoving': isMoving,
    'timestamp': timestamp.toIso8601String(), 'lastSeen': lastSeen?.toIso8601String(),
  };

  factory PartnerLocation.fromJson(Map<String, dynamic> json) => PartnerLocation(
    id: json['id'], name: json['name'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    altitude: (json['altitude'] as num?)?.toDouble(),
    speed: (json['speed'] as num?)?.toDouble(),
    heading: (json['heading'] as num?)?.toDouble(),
    batteryLevel: (json['batteryLevel'] as num?)?.toDouble(),
    activity: json['activity'], isOnline: json['isOnline'] ?? false,
    isMoving: json['isMoving'] ?? false,
    timestamp: DateTime.parse(json['timestamp']),
    lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
  );
}

class CoupleData {
  final PartnerLocation user;
  final PartnerLocation? partner;
  final DateTime lastSync;

  CoupleData({required this.user, this.partner, DateTime? lastSync})
      : lastSync = lastSync ?? DateTime.now();

  double get distanceKm {
    if (partner == null) return 0;
    return _haversine(user.latitude, user.longitude, partner!.latitude, partner!.longitude);
  }

  String get distanceFormatted {
    final d = distanceKm;
    if (d < 1) return '${(d * 1000).toStringAsFixed(0)} m';
    return '${d.toStringAsFixed(1)} km';
  }

  String get etaFormatted {
    if (partner == null || user.speed == null || user.speed! < 1) return '--';
    final hours = distanceKm / user.speed!;
    if (hours < 1) return '${(hours * 60).ceil()} min';
    return '${hours.toStringAsFixed(1)} h';
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = _sin2(dLat / 2) + _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLon / 2);
    return r * 2 * _asin(_sqrt(a));
  }

  static double _rad(double d) => d * 3.141592653589793 / 180;
  static double _sin2(double x) { final s = _sin(x); return s * s; }
  static double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
  static double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
  static double _asin(double x) => x + x * x * x / 6 + x * x * x * x * x * 3 / 40;
  static double _sqrt(double x) => x < 0 ? 0 : x > 1 ? 1 : x == 0 ? 0 : _sqrtNewton(x, x);
  static double _sqrtNewton(double x, double g) => (g * g - x).abs() < 1e-10 ? g : _sqrtNewton(x, (g + x / g) / 2);
}
