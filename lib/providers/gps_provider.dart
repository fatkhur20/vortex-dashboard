import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/services/gps_service.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  final service = GpsService();
  ref.onDispose(() => service.dispose());
  return service;
});

final gpsDataProvider = StateNotifierProvider<GpsDataNotifier, GpsData?>((ref) {
  return GpsDataNotifier(ref);
});

class GpsDataNotifier extends StateNotifier<GpsData?> {
  StreamSubscription? _sub;
  final Ref _ref;

  GpsDataNotifier(this._ref) : super(null) {
    final service = _ref.read(gpsServiceProvider);
    try {
      service.startListening();
    } catch (_) {}
    _sub = service.gpsDataStream.listen(
      (data) { state = data; },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final currentSpeedProvider = Provider<double>((ref) {
  return ref.watch(gpsDataProvider)?.speed ?? 0;
});

final currentAltitudeProvider = Provider<double>((ref) {
  return ref.watch(gpsDataProvider)?.altitude ?? 0;
});

final currentLocationProvider = Provider<Map<String, double>>((ref) {
  final d = ref.watch(gpsDataProvider);
  return {'lat': d?.latitude ?? 0, 'lng': d?.longitude ?? 0};
});

final gpsAccuracyProvider = Provider<double>((ref) {
  return ref.watch(gpsDataProvider)?.accuracy ?? 0;
});
