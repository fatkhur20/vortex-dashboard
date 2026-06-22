import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vortex_dashboard/models/invite_code.dart';
import 'package:vortex_dashboard/models/user_profile.dart';

class CoupleApiService {
  static const String _baseUrl = 'https://vortex-tracker.vortex-x.workers.dev';

  static final CoupleApiService _instance = CoupleApiService._();
  factory CoupleApiService() => _instance;
  CoupleApiService._();

  Future<UserProfile> registerUser({
    required String deviceId,
    String? displayName,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'display_name': displayName}),
    );
    if (res.statusCode != 200) throw Exception('register failed: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfile(
      id: data['user_id'] as String,
      deviceId: deviceId,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
  }

  Future<InviteCode> createInvite(String userId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/invite/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'create invite failed');
    }
    return InviteCode.fromJson(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> joinInvite({
    required String code,
    required String userId,
    String? displayName,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/invite/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'user_id': userId, 'display_name': displayName}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'join failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<PairInfo> getPairStatus(String userId) async {
    final res = await http.get(Uri.parse('$_baseUrl/pair/status?user_id=$userId'));
    if (res.statusCode != 200) throw Exception('status failed');
    return PairInfo.fromJson(jsonDecode(res.body));
  }

  Future<void> disconnectPair(String userId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/pair/disconnect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    if (res.statusCode != 200) throw Exception('disconnect failed');
  }

  Future<Map<String, dynamic>> uploadLocation({
    required String userId,
    required double latitude,
    required double longitude,
    double altitude = 0,
    double speed = 0,
    double heading = 0,
    double battery = 100,
    String activity = 'Stationary',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/location'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId, 'latitude': latitude, 'longitude': longitude,
        'altitude': altitude, 'speed': speed, 'heading': heading,
        'battery': battery, 'activity': activity,
      }),
    );
    if (res.statusCode != 200) throw Exception('location upload failed');
    return jsonDecode(res.body);
  }

  Future<PartnerInfo?> getPartnerLocation(String userId) async {
    final res = await http.get(Uri.parse('$_baseUrl/partner/$userId'));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['partner'] == null) return null;
    return PartnerInfo.fromJson(data['partner'] as Map<String, dynamic>);
  }

  Future<bool> health() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/health'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
