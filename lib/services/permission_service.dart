import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestBackgroundLocationPermission() async {
    var status = await Permission.locationAlways.status;
    if (!status.isGranted) {
      status = await Permission.locationAlways.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestSensorPermission() async {
    var status = await Permission.sensors.status;
    if (!status.isGranted) {
      status = await Permission.sensors.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestActivityRecognition() async {
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestAllPermissions() async {
    await requestLocationPermission();
    await requestNotificationPermission();
    await requestSensorPermission();
    await requestStoragePermission();

    return true;
  }

  static Future<bool> isLocationEnabled() async {
    return await Permission.location.isGranted;
  }

  static Future<bool> isBackgroundLocationEnabled() async {
    return await Permission.locationAlways.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
