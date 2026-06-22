class MemberInfo {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final double? latitude;
  final double? longitude;
  final double speed;
  final double heading;
  final double? battery;
  final String activity;
  final bool isMoving;
  final String presence;
  final DateTime? lastSeen;
  final DateTime? joinedAt;

  const MemberInfo({
    required this.id, required this.displayName, this.avatarUrl,
    this.role = 'member', this.latitude, this.longitude,
    this.speed = 0, this.heading = 0, this.battery,
    this.activity = 'Stationary', this.isMoving = false,
    this.presence = 'offline', this.lastSeen, this.joinedAt,
  });

  factory MemberInfo.fromJson(Map<String, dynamic> j) => MemberInfo(
    id: j['id'] ?? j['user_id'] ?? '',
    displayName: j['display_name'] as String? ?? 'Unknown',
    avatarUrl: j['avatar_url'] as String?,
    role: j['role'] ?? 'member',
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    speed: (j['speed'] as num?)?.toDouble() ?? 0,
    heading: (j['heading'] as num?)?.toDouble() ?? 0,
    battery: (j['battery'] as num?)?.toDouble(),
    activity: j['activity'] as String? ?? 'Stationary',
    isMoving: j['is_moving'] as bool? ?? false,
    presence: j['presence'] as String? ?? 'offline',
    lastSeen: j['last_seen'] != null ? DateTime.parse(j['last_seen']) : null,
    joinedAt: j['joined_at'] != null ? DateTime.parse(j['joined_at']) : null,
  );

  bool get isOnline => presence == 'online';
  bool get isAway => presence == 'away';
}
