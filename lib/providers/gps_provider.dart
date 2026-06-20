import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/services/gps_service.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  final service = GpsService();
  ref.onDispose(() => service.dispose());
  return service;
});

final gpsDataProvider = StreamNotifierProvider<GpsDataNotifier, GpsData>(
  GpsDataNotifier.new,
);

final gpsStatusProvider = Provider<GpsStatus>((ref) {
  final service = ref.watch(gpsServiceProvider);
  final lastData = service.lastGpsData;
  return GpsStatus(
    isAvailable: service.isListening,
    lastData: lastData,
  );
});

class GpsStatus {
  final bool isAvailable;
  final GpsData? lastData;

  GpsStatus({this.isAvailable = false, this.lastData});
}

class GpsDataNotifier extends StreamNotifier<GpsData> {
  @override
  Stream<GpsData> build() {
    final service = ref.watch(gpsServiceProvider);
    service.startListening();
    return service.gpsDataStream;
  }
}

final currentSpeedProvider = Provider<double>((ref) {
  final gpsData = ref.watch(gpsDataProvider);
  return gpsData.speed;
});

final currentAltitudeProvider = Provider<double>((ref) {
  final gpsData = ref.watch(gpsDataProvider);
  return gpsData.altitude;
});

final currentLocationProvider = Provider<Map<String, double>>((ref) {
  final gpsData = ref.watch(gpsDataProvider);
  return {
    'lat': gpsData.latitude,
    'lng': gpsData.longitude,
  };
});

final gpsAccuracyProvider = Provider<double>((ref) {
  final gpsData = ref.watch(gpsDataProvider);
  return gpsData.accuracy;
});
