import 'dart:async';
import 'dart:math';
import 'package:vortex_dashboard/models/partner_location.dart';
import 'package:vortex_dashboard/models/activity.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoupleTrackingService {
  static final CoupleTrackingService _instance = CoupleTrackingService._();
  factory CoupleTrackingService() => _instance;
  CoupleTrackingService._();

  final _partnerLocationController = StreamController<PartnerLocation>.broadcast();
  Stream<PartnerLocation> get partnerLocationStream => _partnerLocationController.stream;

  final _coupleDataController = StreamController<CoupleData>.broadcast();
  Stream<CoupleData> get coupleDataStream => _coupleDataController.stream;

  PartnerLocation? _lastPartnerLocation;
  PartnerLocation? get lastPartnerLocation => _lastPartnerLocation;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Timer? _syncTimer;
  Timer? _mockPartnerTimer;
  bool _useMockData = false;

  void startTracking(Ref ref) {
    if (_useMockData) return;
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncPartnerLocation();
    });
  }

  void startWithMockPartner() {
    _useMockData = true;
    final now = DateTime.now();
    _lastPartnerLocation = PartnerLocation(
      id: 'partner-1',
      name: 'Partner',
      latitude: -6.22,
      longitude: 106.83,
      altitude: 50,
      speed: 0,
      heading: 0,
      batteryLevel: 85,
      activity: UserActivity.stationary.label,
      isOnline: true,
      isMoving: false,
      timestamp: now,
      lastSeen: now,
    );
    _partnerLocationController.add(_lastPartnerLocation!);

    _mockPartnerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulatePartnerMovement();
    });
  }

  void _simulatePartnerMovement() {
    if (_lastPartnerLocation == null) return;
    final rng = Random();
    final latOffset = (rng.nextDouble() - 0.5) * 0.002;
    final lngOffset = (rng.nextDouble() - 0.5) * 0.002;
    final moving = rng.nextBool();
    final speed = moving ? 20 + rng.nextDouble() * 40 : 0.0;

    _lastPartnerLocation = _lastPartnerLocation!.copyWith(
      latitude: _lastPartnerLocation!.latitude + latOffset,
      longitude: _lastPartnerLocation!.longitude + lngOffset,
      speed: speed,
      heading: rng.nextDouble() * 360,
      batteryLevel: (85 - rng.nextDouble() * 10).clamp(0, 100),
      activity: speed > 0 ? UserActivity.driving.label : UserActivity.stationary.label,
      isOnline: true,
      isMoving: speed > 1,
      timestamp: DateTime.now(),
      lastSeen: DateTime.now(),
    );
    _partnerLocationController.add(_lastPartnerLocation!);
  }

  void _syncPartnerLocation() {
    // In production this would call a Firebase/API endpoint
    // For now using mock data
    if (_lastPartnerLocation == null) return;
    _partnerLocationController.add(_lastPartnerLocation!);
  }

  void emitCoupleData(CoupleData data) {
    _coupleDataController.add(data);
    _lastPartnerLocation = data.partner;
  }

  void stopTracking() {
    _syncTimer?.cancel();
    _mockPartnerTimer?.cancel();
    _syncTimer = null;
    _mockPartnerTimer = null;
    _useMockData = false;
  }

  void dispose() {
    stopTracking();
    _partnerLocationController.close();
    _coupleDataController.close();
  }
}
