import 'dart:async';
import 'package:vortex_dashboard/models/geofence.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._();
  factory GeofenceService() => _instance;
  GeofenceService._();

  final _eventController = StreamController<GeofenceEvent>.broadcast();
  Stream<GeofenceEvent> get eventStream => _eventController.stream;

  List<Geofence> _geofences = [];
  List<Geofence> get geofences => List.unmodifiable(_geofences);

  final Map<String, bool> _insideState = {};

  Future<void> loadGeofences() async {
    final storage = StorageService.instance;
    final data = storage.getBox('geofences');
    if (data != null && data.isNotEmpty) {
      _geofences = data.values.map((e) => Geofence.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<void> addGeofence(Geofence geofence) async {
    _geofences.add(geofence);
    await _persist();
  }

  Future<void> updateGeofence(Geofence geofence) async {
    final idx = _geofences.indexWhere((g) => g.id == geofence.id);
    if (idx >= 0) {
      _geofences[idx] = geofence;
      await _persist();
    }
  }

  Future<void> deleteGeofence(String id) async {
    _geofences.removeWhere((g) => g.id == id);
    _insideState.remove(id);
    await _persist();
  }

  void checkGeofences(double lat, double lng) {
    for (final fence in _geofences.where((g) => g.enabled)) {
      final inside = fence.isInside(lat, lng);
      final wasInside = _insideState[fence.id] ?? false;

      if (inside && !wasInside && fence.notifyOnEntry) {
        _eventController.add(GeofenceEvent(
          geofenceId: fence.id, geofenceName: fence.name,
          isEntry: true,
        ));
      } else if (!inside && wasInside && fence.notifyOnExit) {
        _eventController.add(GeofenceEvent(
          geofenceId: fence.id, geofenceName: fence.name,
          isEntry: false,
        ));
      }
      _insideState[fence.id] = inside;
    }
  }

  Future<void> _persist() async {
    final storage = StorageService.instance;
    final box = storage.getBox('geofences');
    if (box != null) {
      await box.clear();
      for (final g in _geofences) {
        await box.put(g.id, g.toJson());
      }
    }
  }

  void dispose() {
    _eventController.close();
  }
}
