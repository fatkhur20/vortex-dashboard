import 'package:hive/hive.dart';
import 'package:vortex_dashboard/core/constants/app_constants.dart';
import 'package:vortex_dashboard/models/ride_model.dart';
import 'package:vortex_dashboard/models/trip_settings.dart';

class StorageService {
  static StorageService? _instance;
  factory StorageService() => _instance ?? StorageService._();
  StorageService._();

  static Future<void> initialize() async {
    registerRideModelAdapter();
    await Hive.openBox<RideModel>(AppConstants.hiveBoxRides);
    await Hive.openBox(AppConstants.hiveBoxSettings);
    await Hive.openBox(AppConstants.hiveBoxTracking);
    await Hive.openBox(AppConstants.hiveBoxTrips);
    _instance = StorageService._();
  }

  Box<RideModel> get _ridesBox => Hive.box<RideModel>(AppConstants.hiveBoxRides);
  Box get _settingsBox => Hive.box(AppConstants.hiveBoxSettings);
  Box get _trackingBox => Hive.box(AppConstants.hiveBoxTracking);
  Box get _tripsBox => Hive.box(AppConstants.hiveBoxTrips);

  Future<void> saveRide(RideModel ride) async {
    await _ridesBox.put(ride.id, ride);
  }

  List<RideModel> getAllRides() {
    return _ridesBox.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  RideModel? getRide(String id) {
    return _ridesBox.get(id);
  }

  Future<void> deleteRide(String id) async {
    await _ridesBox.delete(id);
  }

  Future<void> deleteAllRides() async {
    await _ridesBox.clear();
  }

  List<RideModel> searchRides(String query) {
    final lowerQuery = query.toLowerCase();
    return _ridesBox.values.where((ride) {
      final dateStr = ride.startTime.toIso8601String().toLowerCase();
      final name = ride.name?.toLowerCase() ?? '';
      return dateStr.contains(lowerQuery) || name.contains(lowerQuery);
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<void> saveTripSettings(TripSettings settings) async {
    await _tripsBox.put('tripA', settings.distanceTripA);
    await _tripsBox.put('tripB', settings.distanceTripB);
    await _tripsBox.put('odometer', settings.odometerTotal);
  }

  TripSettings loadTripSettings() {
    return TripSettings(
      distanceTripA: _tripsBox.get('tripA', defaultValue: 0.0),
      distanceTripB: _tripsBox.get('tripB', defaultValue: 0.0),
      odometerTotal: _tripsBox.get('odometer', defaultValue: 0.0),
    );
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveBool(String key, bool value) async {
    await _settingsBox.put(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveInt(String key, int value) async {
    await _settingsBox.put(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveDouble(String key, double value) async {
    await _settingsBox.put(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveString(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveTrackingData(String key, dynamic value) async {
    await _trackingBox.put(key, value);
  }

  dynamic getTrackingData(String key, {dynamic defaultValue}) {
    return _trackingBox.get(key, defaultValue: defaultValue);
  }

  Future<void> clearTrackingData() async {
    await _trackingBox.clear();
  }

  Future<int> getRideCount() async {
    return _ridesBox.length;
  }

  Future<double> getTotalDistance() async {
    final rides = _ridesBox.values;
    double total = 0;
    for (final ride in rides) {
      total += ride.distanceKm;
    }
    return total;
  }

  Future<Map<String, dynamic>> getStats() async {
    final rides = _ridesBox.values;
    double totalDistance = 0;
    double maxSpeed = 0;
    int totalDuration = 0;
    int rideCount = rides.length;

    for (final ride in rides) {
      totalDistance += ride.distanceKm;
      if (ride.maxSpeedKmh > maxSpeed) maxSpeed = ride.maxSpeedKmh;
      totalDuration += ride.duration.inSeconds;
    }

    return {
      'rideCount': rideCount,
      'totalDistance': totalDistance,
      'maxSpeed': maxSpeed,
      'totalDuration': Duration(seconds: totalDuration),
    };
  }
}
