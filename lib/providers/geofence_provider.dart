import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/geofence.dart';
import 'package:vortex_dashboard/services/geofence_service.dart';

final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  final service = GeofenceService();
  ref.onDispose(() => service.dispose());
  return service;
});

final geofenceListProvider = StateNotifierProvider<GeofenceListNotifier, List<Geofence>>((ref) {
  return GeofenceListNotifier(ref);
});

class GeofenceListNotifier extends StateNotifier<List<Geofence>> {
  final Ref _ref;

  GeofenceListNotifier(this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final service = _ref.read(geofenceServiceProvider);
    await service.loadGeofences();
    state = service.geofences;
  }

  Future<void> add(Geofence geofence) async {
    await _ref.read(geofenceServiceProvider).addGeofence(geofence);
    state = _ref.read(geofenceServiceProvider).geofences;
  }

  Future<void> update(Geofence geofence) async {
    await _ref.read(geofenceServiceProvider).updateGeofence(geofence);
    state = _ref.read(geofenceServiceProvider).geofences;
  }

  Future<void> delete(String id) async {
    await _ref.read(geofenceServiceProvider).deleteGeofence(id);
    state = _ref.read(geofenceServiceProvider).geofences;
  }
}

final geofenceEventsProvider = StreamProvider<GeofenceEvent>((ref) {
  return _ref.read(geofenceServiceProvider).eventStream;
});

final geofenceCheckProvider = Provider<void>((ref) {
  ref.listen(currentLocationProvider, (prev, next) {
    ref.read(geofenceServiceProvider).checkGeofences(next['lat']!, next['lng']!);
  });
  return;
});
