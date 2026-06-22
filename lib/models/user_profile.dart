class UserProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String deviceId;
  final DateTime createdAt;

  const UserProfile({
    required this.id, this.displayName, this.avatarUrl,
    required this.deviceId, required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'] ?? '', displayName: j['display_name'] as String?,
    avatarUrl: j['avatar_url'] as String?, deviceId: j['device_id'] as String? ?? '',
    createdAt: j['created_at'] != null ? DateTime.parse(j['created_at']) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'display_name': displayName, 'avatar_url': avatarUrl,
    'device_id': deviceId, 'created_at': createdAt.toIso8601String(),
  };

  UserProfile copyWith({String? displayName, String? avatarUrl}) => UserProfile(
    id: id, displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl, deviceId: deviceId, createdAt: createdAt,
  );
}
