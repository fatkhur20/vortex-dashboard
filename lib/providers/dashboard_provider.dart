import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/services/storage_service.dart';
import 'package:vortex_dashboard/core/constants/app_constants.dart';

final dashboardDataProvider = Provider<DashboardData>((ref) {
  final gpsData = ref.watch(gpsDataProvider);
  final storage = StorageService();

  return DashboardData(
    currentSpeed: gpsData?.speed ?? 0,
    latitude: gpsData?.latitude ?? 0,
    longitude: gpsData?.longitude ?? 0,
    altitude: gpsData?.altitude ?? 0,
    heading: gpsData?.heading ?? 0,
    accuracy: gpsData?.accuracy ?? 0,
    tripADistance: storage.getDouble(AppConstants.tripAKey, defaultValue: 0),
    tripBDistance: storage.getDouble(AppConstants.tripBKey, defaultValue: 0),
    odometerTotal: storage.getDouble(AppConstants.odometerKey, defaultValue: 0),
  );
});

class DashboardData {
  final double currentSpeed;
  final double latitude;
  final double longitude;
  final double altitude;
  final double heading;
  final double accuracy;
  final double tripADistance;
  final double tripBDistance;
  final double odometerTotal;

  DashboardData({
    this.currentSpeed = 0,
    this.latitude = 0,
    this.longitude = 0,
    this.altitude = 0,
    this.heading = 0,
    this.accuracy = 0,
    this.tripADistance = 0,
    this.tripBDistance = 0,
    this.odometerTotal = 0,
  });
}
