import 'dart:math';
import 'package:vortex_dashboard/core/constants/app_constants.dart';

class Helpers {
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return AppConstants.earthRadiusKm * c;
  }

  static double _toRadians(double degree) {
    return degree * AppConstants.pi / 180;
  }

  static double kmhToMph(double kmh) {
    return kmh * 0.621371;
  }

  static double mphToKmh(double mph) {
    return mph / 0.621371;
  }

  static double calculateAverageSpeed(double distanceKm, Duration duration) {
    if (duration.inSeconds == 0) return 0;
    final hours = duration.inSeconds / 3600;
    return distanceKm / hours;
  }

  static double calculatePace(double speedKmh) {
    if (speedKmh <= 0) return 0;
    return 60 / speedKmh;
  }

  static String formatSpeed(double speed, bool isKmh) {
    if (isKmh) {
      return speed.toStringAsFixed(1);
    }
    return kmhToMph(speed).toStringAsFixed(1);
  }

  static String formatDistance(double km, bool isMetric) {
    if (isMetric) {
      if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
      return '${km.toStringAsFixed(2)} km';
    }
    final miles = km * 0.621371;
    if (miles < 1) return '${(miles * 5280).toStringAsFixed(0)} ft';
    return '${miles.toStringAsFixed(2)} mi';
  }
}
