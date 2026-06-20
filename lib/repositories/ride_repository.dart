import 'package:vortex_dashboard/models/ride_model.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

class RideRepository {
  final StorageService _storage;

  RideRepository() : _storage = StorageService();

  Future<void> saveRide(RideModel ride) async {
    await _storage.saveRide(ride);
  }

  List<RideModel> getAllRides() {
    return _storage.getAllRides();
  }

  RideModel? getRide(String id) {
    return _storage.getRide(id);
  }

  Future<void> deleteRide(String id) async {
    await _storage.deleteRide(id);
  }

  Future<void> deleteAllRides() async {
    await _storage.deleteAllRides();
  }

  List<RideModel> searchRides(String query) {
    return _storage.searchRides(query);
  }

  Future<int> getRideCount() async {
    return _storage.getRideCount();
  }

  Future<double> getTotalDistance() async {
    return _storage.getTotalDistance();
  }

  Future<Map<String, dynamic>> getStats() async {
    return _storage.getStats();
  }
}
