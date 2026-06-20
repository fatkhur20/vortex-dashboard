import 'dart:async';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/models/ride_model.dart';
import 'package:vortex_dashboard/services/gps_service.dart';
import 'package:vortex_dashboard/services/storage_service.dart';
import 'package:vortex_dashboard/core/utils/helpers.dart';
import 'package:uuid/uuid.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._();

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  RideModel? _currentRide;
  RideModel? get currentRide => _currentRide;

  final _trackingController = StreamController<RideModel>.broadcast();
  Stream<RideModel> get trackingStream => _trackingController.stream;

  StreamSubscription? _gpsSubscription;
  final List<GpsData> _trackPoints = [];
  final List<GpsData> _speedSamples = [];
  double _maxSpeed = 0;
  double _maxAltitude = 0;
  double _minAltitude = double.infinity;
  double _totalDistance = 0;
  GpsData? _lastPoint;
  final Uuid _uuid = const Uuid();

  List<GpsData> get trackPoints => List.unmodifiable(_trackPoints);
  double get maxSpeed => _maxSpeed;
  double get maxAltitude => _maxAltitude;
  double get minAltitude => _minAltitude == double.infinity ? 0 : _minAltitude;
  double get totalDistance => _totalDistance;

  Future<void> startTracking() async {
    if (_isTracking) return;

    _isTracking = true;
    _trackPoints.clear();
    _speedSamples.clear();
    _maxSpeed = 0;
    _maxAltitude = 0;
    _minAltitude = double.infinity;
    _totalDistance = 0;
    _lastPoint = null;

    _currentRide = RideModel(
      id: _uuid.v4(),
      startTime: DateTime.now(),
    );

    final gpsService = GpsService();
    await gpsService.startListening();

    _gpsSubscription = gpsService.gpsDataStream.listen(
      (GpsData data) {
        if (!_isTracking) return;

        _trackPoints.add(data);
        _speedSamples.add(data);

        if (data.speed > _maxSpeed) _maxSpeed = data.speed;
        if (data.altitude > _maxAltitude) _maxAltitude = data.altitude;
        if (data.altitude < _minAltitude) _minAltitude = data.altitude;

        if (_lastPoint != null) {
          _totalDistance += Helpers.calculateDistance(
            _lastPoint!.latitude, _lastPoint!.longitude,
            data.latitude, data.longitude,
          );
        }
        _lastPoint = data;

        final avgSpeed = _speedSamples.length > 1
            ? _speedSamples.map((e) => e.speed).reduce((a, b) => a + b) /
                _speedSamples.length
            : 0;

        _currentRide = _currentRide!.copyWith(
          distanceKm: _totalDistance,
          maxSpeedKmh: _maxSpeed,
          averageSpeedKmh: avgSpeed,
          maxAltitude: _maxAltitude,
          minAltitude: _minAltitude,
          trackPoints: List.from(_trackPoints),
        );

        _trackingController.add(_currentRide!);
      },
    );
  }

  Future<RideModel?> stopTracking() async {
    if (!_isTracking) return _currentRide;

    _isTracking = false;
    _gpsSubscription?.cancel();

    if (_currentRide != null) {
      final completedRide = _currentRide!.copyWith(
        endTime: DateTime.now(),
        endLatitude: _lastPoint?.latitude,
        endLongitude: _lastPoint?.longitude,
        startLatitude: _trackPoints.isNotEmpty
            ? _trackPoints.first.latitude
            : null,
        startLongitude: _trackPoints.isNotEmpty
            ? _trackPoints.first.longitude
            : null,
      );

      _currentRide = completedRide;
      await StorageService().saveRide(completedRide);
      _trackingController.add(completedRide);
    }

    GpsService().stopListening();
    return _currentRide;
  }

  void dispose() {
    _gpsSubscription?.cancel();
    _trackingController.close();
  }
}
