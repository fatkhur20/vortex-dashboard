import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/services/gps_service.dart';
import 'package:vortex_dashboard/services/storage_service.dart';
import 'package:vortex_dashboard/core/constants/app_constants.dart';
import 'package:vortex_dashboard/core/utils/helpers.dart';

final dashboardDataProvider = Provider<DashboardData>((ref) {
  final gpsService = GpsService();
  final lastData = gpsService.lastGpsData;
  final storage = StorageService();

  return DashboardData(
    currentSpeed: lastData?.speed ?? 0,
    latitude: lastData?.latitude ?? 0,
    longitude: lastData?.longitude ?? 0,
    altitude: lastData?.altitude ?? 0,
    heading: lastData?.heading ?? 0,
    accuracy: lastData?.accuracy ?? 0,
    satelliteCount: lastData?.satelliteCount,
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
  final int? satelliteCount;
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
    this.satelliteCount,
    this.tripADistance = 0,
    this.tripBDistance = 0,
    this.odometerTotal = 0,
  });
}

final speedColorProvider = Provider<String>((ref) {
  final speed = ref.watch(dashboardDataProvider).currentSpeed;
  return speed.speedColorHex;
});
