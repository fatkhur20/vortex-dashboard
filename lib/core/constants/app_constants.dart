class AppConstants {
  static const String appName = 'Vortex Dashboard';
  static const String appVersion = '1.0.0';

  static const double defaultGpsUpdateInterval = 1000;
  static const double fastGpsUpdateInterval = 500;
  static const double maxSpeedKmh = 320.0;
  static const double maxSpeedMph = 200.0;

  static const double speedWarningThreshold = 120.0;
  static const double speedCriticalThreshold = 160.0;

  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxRides = 'rides';
  static const String hiveBoxTracking = 'tracking';
  static const String hiveBoxTrips = 'trips';

  static const String storageKeyUnit = 'speed_unit';
  static const String storageKeyTheme = 'theme_mode';
  static const String storageKeyAmoled = 'amoled_mode';
  static const String storageKeyAlwaysOn = 'always_on';
  static const String storageKeyGpsRefresh = 'gps_refresh_rate';
  static const String storageKeySpeedAlert = 'speed_alert';
  static const String storageKeySpeedLimit = 'speed_limit';
  static const String storageKeyVoiceAlerts = 'voice_alerts';
  static const String storageKeyAutoRide = 'auto_ride_detection';
  static const String storageKeyCrashDetection = 'crash_detection';
  static const String storageKeyEmergencyContact = 'emergency_contact';
  static const String storageKeyBackgroundTracking = 'background_tracking';

  static const String tripAKey = 'trip_a_distance';
  static const String tripBKey = 'trip_b_distance';
  static const String odometerKey = 'odometer_total';

  static const String gpxHeader = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="VortexDashboard"
  xmlns="http://www.topografix.com/GPX/1/1">
  <trk>
    <name>Vortex Dashboard Ride</name>
    <trkseg>''';
  static const String gpxFooter = '''    </trkseg>
  </trk>
</gpx>''';

  static const double pi = 3.1415926535897932;
  static const double earthRadiusKm = 6371.0;
}
