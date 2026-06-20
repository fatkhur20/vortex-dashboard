import 'dart:convert';
import 'package:vortex_dashboard/models/ride_model.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

class TrackingRepository {
  final StorageService _storage;

  TrackingRepository() : _storage = StorageService();

  Future<void> saveActiveTracking(Map<String, dynamic> state) async {
    await _storage.saveTrackingData('active_tracking', jsonEncode(state));
  }

  Map<String, dynamic>? loadActiveTracking() {
    final data = _storage.getTrackingData('active_tracking');
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  Future<void> clearActiveTracking() async {
    await _storage.clearTrackingData();
  }

  Future<bool> hasActiveTracking() async {
    return _storage.getTrackingData('active_tracking') != null;
  }

  Future<void> exportRideAsGpx(RideModel ride, String filePath) async {
    final gpx = ride.toGpx();
    // In a real app, write to file
  }

  Future<void> exportRideAsCsv(RideModel ride, String filePath) async {
    final csv = ride.toCsv();
    // In a real app, write to file
  }
}
