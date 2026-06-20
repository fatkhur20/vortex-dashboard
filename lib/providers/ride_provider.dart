import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/ride_model.dart';
import 'package:vortex_dashboard/repositories/ride_repository.dart';

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository();
});

final rideListProvider = StateNotifierProvider<RideListNotifier, List<RideModel>>((ref) {
  return RideListNotifier(ref);
});

final rideStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(rideRepositoryProvider);
  return repo.getStats();
});

class RideListNotifier extends StateNotifier<List<RideModel>> {
  final Ref _ref;

  RideListNotifier(this._ref) : super([]) {
    _loadRides();
  }

  void _loadRides() {
    final repo = _ref.read(rideRepositoryProvider);
    state = repo.getAllRides();
  }

  void refresh() {
    _loadRides();
  }

  Future<void> deleteRide(String id) async {
    final repo = _ref.read(rideRepositoryProvider);
    await repo.deleteRide(id);
    _loadRides();
  }

  Future<void> deleteAllRides() async {
    final repo = _ref.read(rideRepositoryProvider);
    await repo.deleteAllRides();
    state = [];
  }

  void search(String query) {
    if (query.isEmpty) {
      _loadRides();
      return;
    }
    final repo = _ref.read(rideRepositoryProvider);
    state = repo.searchRides(query);
  }
}
