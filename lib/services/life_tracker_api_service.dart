import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vortex_dashboard/models/user_profile.dart';
import 'package:vortex_dashboard/models/group_info.dart';
import 'package:vortex_dashboard/models/member_info.dart';

const String _baseUrl = 'https://vortex-tracker.vortex-x.workers.dev';

class LifeTrackerApiService {
  static final LifeTrackerApiService _instance = LifeTrackerApiService._();
  factory LifeTrackerApiService() => _instance;
  LifeTrackerApiService._();

  // ── Users ──

  Future<Map<String, dynamic>> registerUser({
    required String deviceId,
    String? displayName,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'display_name': displayName}),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<UserProfile> getMe(String userId) async {
    final res = await http.get(Uri.parse('$_baseUrl/users/me?user_id=$userId'));
    _check(res);
    return UserProfile.fromJson(jsonDecode(res.body));
  }

  Future<void> updateProfile(String userId, {String? displayName, String? avatarUrl}) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/users/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'display_name': displayName, 'avatar_url': avatarUrl}),
    );
    _check(res);
  }

  // ── Groups ──

  Future<List<GroupInfo>> getGroups(String userId) async {
    final res = await http.get(Uri.parse('$_baseUrl/groups?user_id=$userId'));
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['groups'] as List).map((g) => GroupInfo.fromJson(g as Map<String, dynamic>)).toList();
  }

  Future<GroupInfo> createGroup(String userId, String name) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/groups/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'name': name}),
    );
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return GroupInfo(
      id: data['group_id'] as String, name: data['name'] as String,
      ownerId: data['owner_id'] as String, role: 'owner', memberCount: 1,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  Future<GroupInfo> getGroup(String groupId) async {
    final res = await http.get(Uri.parse('$_baseUrl/groups/$groupId'));
    _check(res);
    return GroupInfo.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteGroup(String groupId, String userId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/groups/$groupId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    _check(res);
  }

  // ── Members ──

  Future<List<MemberInfo>> getMembers(String groupId) async {
    final res = await http.get(Uri.parse('$_baseUrl/groups/$groupId/members'));
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['members'] as List).map((m) => MemberInfo.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    _check(res);
  }

  Future<void> removeMember(String groupId, String userId, String targetId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/remove'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'target_id': targetId}),
    );
    _check(res);
  }

  // ── Invites ──

  Future<Map<String, dynamic>> createInvite(String groupId, String userId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/invite/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'group_id': groupId, 'user_id': userId}),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinInvite(String code, String userId, {String? displayName}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/invite/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'user_id': userId, 'display_name': displayName}),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInviteInfo(String code) async {
    final res = await http.get(Uri.parse('$_baseUrl/invite/$code'));
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Locations ──

  Future<void> uploadLocation({
    required String userId, required String groupId,
    required double latitude, required double longitude,
    double altitude = 0, double speed = 0, double heading = 0,
    double battery = 100, String activity = 'Stationary',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/location'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId, 'group_id': groupId, 'latitude': latitude,
        'longitude': longitude, 'altitude': altitude, 'speed': speed,
        'heading': heading, 'battery': battery, 'activity': activity,
      }),
    );
    _check(res);
  }

  Future<List<MemberInfo>> getGroupLocations(String groupId) async {
    final res = await http.get(Uri.parse('$_baseUrl/groups/$groupId/locations'));
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['locations'] as List).map((m) => MemberInfo.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<MemberInfo?> getMemberLocation(String groupId, String userId) async {
    final res = await http.get(Uri.parse('$_baseUrl/groups/$groupId/member/$userId'));
    _check(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['member'] == null) return null;
    return MemberInfo.fromJson(data['member'] as Map<String, dynamic>);
  }

  Future<bool> health() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/health'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      String msg;
      try { msg = (jsonDecode(res.body) as Map<String, dynamic>)['error'] as String? ?? 'unknown'; }
      catch (_) { msg = res.body; }
      throw Exception(msg);
    }
  }
}
