enum GeofenceType { home, office, school, custom }

class Geofence {
  final String id;
  final String name;
  final GeofenceType type;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool enabled;
  final bool notifyOnEntry;
  final bool notifyOnExit;
  final DateTime createdAt;
  final String? customIcon;

  Geofence({
    required this.id,
    required this.name,
    this.type = GeofenceType.custom,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
    this.enabled = true,
    this.notifyOnEntry = true,
    this.notifyOnExit = true,
    DateTime? createdAt,
    this.customIcon,
  }) : createdAt = createdAt ?? DateTime.now();

  bool isInside(double lat, double lng) {
    return _haversine(lat, lng, latitude, longitude) * 1000 <= radiusMeters;
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

  Geofence copyWith({
    String? id, String? name, GeofenceType? type,
    double? latitude, double? longitude, double? radiusMeters,
    bool? enabled, bool? notifyOnEntry, bool? notifyOnExit,
    String? customIcon,
  }) {
    return Geofence(
      id: id ?? this.id, name: name ?? this.name, type: type ?? this.type,
      latitude: latitude ?? this.latitude, longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      enabled: enabled ?? this.enabled,
      notifyOnEntry: notifyOnEntry ?? this.notifyOnEntry,
      notifyOnExit: notifyOnExit ?? this.notifyOnExit,
      createdAt: createdAt, customIcon: customIcon ?? this.customIcon,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type.name,
    'latitude': latitude, 'longitude': longitude,
    'radiusMeters': radiusMeters, 'enabled': enabled,
    'notifyOnEntry': notifyOnEntry, 'notifyOnExit': notifyOnExit,
    'createdAt': createdAt.toIso8601String(), 'customIcon': customIcon,
  };

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
    id: json['id'], name: json['name'],
    type: GeofenceType.values.firstWhere((e) => e.name == json['type'], orElse: () => GeofenceType.custom),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radiusMeters: (json['radiusMeters'] as num).toDouble(),
    enabled: json['enabled'] ?? true,
    notifyOnEntry: json['notifyOnEntry'] ?? true,
    notifyOnExit: json['notifyOnExit'] ?? true,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    customIcon: json['customIcon'],
  );
}

class GeofenceEvent {
  final String geofenceId;
  final String geofenceName;
  final bool isEntry;
  final DateTime timestamp;

  GeofenceEvent({
    required this.geofenceId, required this.geofenceName,
    required this.isEntry, DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
