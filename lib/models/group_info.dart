class GroupInfo {
  final String id;
  final String name;
  final String ownerId;
  final String role;
  final int memberCount;
  final DateTime createdAt;
  final DateTime? joinedAt;

  const GroupInfo({
    required this.id, required this.name, required this.ownerId,
    this.role = 'member', this.memberCount = 1,
    required this.createdAt, this.joinedAt,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> j) => GroupInfo(
    id: j['id'] ?? '', name: j['name'] ?? 'Unnamed',
    ownerId: j['owner_id'] ?? '', role: j['role'] ?? 'member',
    memberCount: j['member_count'] as int? ?? 1,
    createdAt: j['created_at'] != null ? DateTime.parse(j['created_at']) : DateTime.now(),
    joinedAt: j['joined_at'] != null ? DateTime.parse(j['joined_at']) : null,
  );

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
  String get typeLabel {
    if (memberCount == 1) return 'Personal';
    if (memberCount == 2) return 'Couple';
    return 'Group';
  }
}
