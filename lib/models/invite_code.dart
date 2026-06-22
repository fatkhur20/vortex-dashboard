class InviteCode {
  final String code;
  final int expiresIn;

  const InviteCode({required this.code, required this.expiresIn});

  factory InviteCode.fromJson(Map<String, dynamic> json) => InviteCode(
    code: json['code'] as String,
    expiresIn: json['expires_in'] as int? ?? 3600,
  );
}

class PairInfo {
  final bool paired;
  final PartnerInfo? partner;
  final DateTime? pairedSince;

  const PairInfo({required this.paired, this.partner, this.pairedSince});

  factory PairInfo.fromJson(Map<String, dynamic> json) => PairInfo(
    paired: json['paired'] as bool? ?? false,
    partner: json['partner'] != null ? PartnerInfo.fromJson(json['partner'] as Map<String, dynamic>) : null,
    pairedSince: json['paired_since'] != null ? DateTime.parse(json['paired_since']) : null,
  );
}

class PartnerInfo {
  final String id;
  final String displayName;
  final double? latitude;
  final double? longitude;
  final double speed;
  final double heading;
  final double? battery;
  final String activity;
  final bool isOnline;
  final bool isMoving;
  final DateTime? lastSeen;

  const PartnerInfo({
    required this.id, required this.displayName, this.latitude, this.longitude,
    this.speed = 0, this.heading = 0, this.battery,
    this.activity = 'Stationary', this.isOnline = false, this.isMoving = false, this.lastSeen,
  });

  factory PartnerInfo.fromJson(Map<String, dynamic> json) => PartnerInfo(
    id: json['id'] as String? ?? '',
    displayName: json['display_name'] as String? ?? 'Partner',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    speed: (json['speed'] as num?)?.toDouble() ?? 0,
    heading: (json['heading'] as num?)?.toDouble() ?? 0,
    battery: (json['battery'] as num?)?.toDouble(),
    activity: json['activity'] as String? ?? 'Stationary',
    isOnline: json['is_online'] as bool? ?? false,
    isMoving: json['is_moving'] as bool? ?? false,
    lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
  );

  PartnerLocation toPartnerLocation() => PartnerLocation(
    id: id, name: displayName, latitude: latitude ?? 0, longitude: longitude ?? 0,
    speed: speed, heading: heading, batteryLevel: battery,
    activity: activity, isOnline: isOnline, isMoving: isMoving, lastSeen: lastSeen, timestamp: lastSeen,
  );
}
