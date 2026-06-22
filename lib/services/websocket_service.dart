import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:vortex_dashboard/models/partner_location.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  WebSocket? _ws;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _serverUrl;
  String? _userId;
  String? _partnerId;

  final _locationController = StreamController<PartnerLocation>.broadcast();
  Stream<PartnerLocation> get partnerLocationStream => _locationController.stream;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  void connect({
    required String serverUrl,
    required String userId,
    String? partnerId,
  }) {
    _serverUrl = serverUrl;
    _userId = userId;
    _partnerId = partnerId;
    _doConnect();
  }

  void _doConnect() async {
    if (_serverUrl == null || _userId == null) return;
    try {
      final ws = await WebSocket.connect('$_serverUrl/ws/$_userId');
      _ws = ws;
      _isConnected = true;
      _connectionController.add(true);
      _reconnectTimer?.cancel();

      if (_partnerId != null) {
        _send({'type': 'subscribe', 'partner_id': _partnerId});
      }

      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _send({'type': 'ping'});
      });

      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _handleMessage(msg);
          } catch (_) {}
        },
        onDone: () {
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onError: (_) {
          _isConnected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
      );
    } catch (_) {
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) _doConnect();
    });
  }

  void sendLocation({
    required double latitude,
    required double longitude,
    double altitude = 0,
    double speed = 0,
    double heading = 0,
    double battery = 100,
    String activity = 'Stationary',
  }) {
    _send({
      'type': 'location_update',
      'user_id': _userId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'battery': battery,
      'activity': activity,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_ws != null && _isConnected) {
      _ws!.add(jsonEncode(data));
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'partner_location') {
      final partner = msg['partner'] as Map<String, dynamic>;
      _locationController.add(_parsePartner(partner));
    }
  }

  PartnerLocation _parsePartner(Map<String, dynamic> data) {
    return PartnerLocation(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Partner',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      altitude: (data['altitude'] as num?)?.toDouble() ?? 0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0,
      heading: (data['heading'] as num?)?.toDouble() ?? 0,
      batteryLevel: (data['battery'] as num?)?.toDouble(),
      activity: data['activity'] as String? ?? 'Stationary',
      isOnline: data['is_online'] as bool? ?? true,
      isMoving: data['is_moving'] as bool? ?? false,
      timestamp: data['timestamp'] != null ? DateTime.parse(data['timestamp']) : DateTime.now(),
      lastSeen: data['last_seen'] != null ? DateTime.parse(data['last_seen']) : DateTime.now(),
    );
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _ws?.close();
    _ws = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _locationController.close();
    _connectionController.close();
  }
}
