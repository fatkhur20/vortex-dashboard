import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vortex_dashboard/models/partner_location.dart';

class WorkerSyncService {
  static final WorkerSyncService _instance = WorkerSyncService._();
  factory WorkerSyncService() => _instance;
  WorkerSyncService._();

  String? _baseUrl;
  String? _userId;
  String? _partnerId;

  final _locationController = StreamController<PartnerLocation>.broadcast();
  Stream<PartnerLocation> get partnerLocationStream => _locationController.stream;

  Timer? _pollTimer;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  int _failCount = 0;

  void connect({
    required String baseUrl,
    required String userId,
    String? partnerId,
  }) {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    _userId = userId;
    _partnerId = partnerId;
    _isConnected = true;

    if (partnerId != null) {
      _pair(partnerId);
    }

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollPartner());
  }

  Future<void> _pair(String partnerId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/pair'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _userId, 'partner_id': partnerId}),
      );
    } catch (_) {}
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    double altitude = 0,
    double speed = 0,
    double heading = 0,
    double battery = 100,
    String activity = 'Stationary',
  }) async {
    if (_baseUrl == null || _userId == null) return;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'partner_id': _partnerId,
          'latitude': latitude,
          'longitude': longitude,
          'altitude': altitude,
          'speed': speed,
          'heading': heading,
          'battery': battery,
          'activity': activity,
        }),
      );
      if (res.statusCode == 429) _failCount++;
      else _failCount = 0;
    } catch (_) {
      _failCount++;
    }
  }

  Future<void> _pollPartner() async {
    if (_baseUrl == null || _userId == null || _partnerId == null) return;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/partner/$_userId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['partner'] != null) {
          final p = data['partner'] as Map<String, dynamic>;
          _locationController.add(PartnerLocation(
            id: p['id'] ?? '',
            name: p['name'] ?? 'Partner',
            latitude: (p['latitude'] as num).toDouble(),
            longitude: (p['longitude'] as num).toDouble(),
            altitude: (p['altitude'] as num?)?.toDouble() ?? 0,
            speed: (p['speed'] as num?)?.toDouble() ?? 0,
            heading: (p['heading'] as num?)?.toDouble() ?? 0,
            batteryLevel: (p['battery'] as num?)?.toDouble(),
            activity: p['activity'] as String? ?? 'Stationary',
            isOnline: p['is_online'] as bool? ?? false,
            isMoving: p['is_moving'] as bool? ?? false,
            timestamp: p['timestamp'] != null ? DateTime.parse(p['timestamp']) : DateTime.now(),
            lastSeen: p['last_seen'] != null ? DateTime.parse(p['last_seen']) : DateTime.now(),
          ));
          _isConnected = true;
        } else {
          _isConnected = data['online'] as bool? ?? false;
        }
      }
    } catch (_) {
      _isConnected = false;
    }
  }

  void disconnect() {
    if (_baseUrl != null && _userId != null && _isConnected) {
      http.delete(Uri.parse('$_baseUrl/location/$_userId'));
    }
    _pollTimer?.cancel();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _locationController.close();
  }
}
