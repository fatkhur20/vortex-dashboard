import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:vortex_dashboard/models/gps_data.dart';

class GpsService {
  static final GpsService _instance = GpsService._();
  factory GpsService() => _instance;
  GpsService._();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isListening = false;

  final _gpsDataController = StreamController<GpsData>.broadcast();
  Stream<GpsData> get gpsDataStream => _gpsDataController.stream;
  GpsData? _lastGpsData;

  Position? get currentPosition => _currentPosition;
  GpsData? get lastGpsData => _lastGpsData;
  bool get isListening => _isListening;

  void setUpdateInterval(int ms) {
    if (_isListening) {
      stopListening();
      startListening();
    }
  }

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> startListening() async {
    if (_isListening) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _isListening = true;
    
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        final gpsData = GpsData(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          speed: position.speed * 3.6,
          accuracy: position.accuracy,
          heading: position.heading,
          timestamp: position.timestamp,
        );
        _lastGpsData = gpsData;
        _gpsDataController.add(gpsData);
      },
      onError: (error) {
        _gpsDataController.addError(error);
      },
    );
  }

  void stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isListening = false;
  }

  Future<GpsData?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _currentPosition = position;
      final gpsData = GpsData(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        speed: position.speed * 3.6,
        accuracy: position.accuracy,
        heading: position.heading,
        timestamp: position.timestamp,
      );
      _lastGpsData = gpsData;
      return gpsData;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  void dispose() {
    stopListening();
    _gpsDataController.close();
  }
}
