class TripSettings {
  double distanceTripA;
  double distanceTripB;
  double odometerTotal;
  bool useKmh;
  bool amoledMode;
  bool alwaysOnDisplay;
  int gpsRefreshRateMs;
  bool speedAlertEnabled;
  double speedLimit;
  bool voiceAlertsEnabled;
  bool autoRideDetection;
  bool crashDetection;
  bool backgroundTracking;
  String? emergencyContactName;
  String? emergencyContactPhone;

  TripSettings({
    this.distanceTripA = 0,
    this.distanceTripB = 0,
    this.odometerTotal = 0,
    this.useKmh = true,
    this.amoledMode = true,
    this.alwaysOnDisplay = false,
    this.gpsRefreshRateMs = 1000,
    this.speedAlertEnabled = false,
    this.speedLimit = 120.0,
    this.voiceAlertsEnabled = false,
    this.autoRideDetection = false,
    this.crashDetection = false,
    this.backgroundTracking = false,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'distanceTripA': distanceTripA,
      'distanceTripB': distanceTripB,
      'odometerTotal': odometerTotal,
      'useKmh': useKmh,
      'amoledMode': amoledMode,
      'alwaysOnDisplay': alwaysOnDisplay,
      'gpsRefreshRateMs': gpsRefreshRateMs,
      'speedAlertEnabled': speedAlertEnabled,
      'speedLimit': speedLimit,
      'voiceAlertsEnabled': voiceAlertsEnabled,
      'autoRideDetection': autoRideDetection,
      'crashDetection': crashDetection,
      'backgroundTracking': backgroundTracking,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  factory TripSettings.fromJson(Map<String, dynamic> json) {
    return TripSettings(
      distanceTripA: (json['distanceTripA'] as num?)?.toDouble() ?? 0,
      distanceTripB: (json['distanceTripB'] as num?)?.toDouble() ?? 0,
      odometerTotal: (json['odometerTotal'] as num?)?.toDouble() ?? 0,
      useKmh: json['useKmh'] as bool? ?? true,
      amoledMode: json['amoledMode'] as bool? ?? true,
      alwaysOnDisplay: json['alwaysOnDisplay'] as bool? ?? false,
      gpsRefreshRateMs: json['gpsRefreshRateMs'] as int? ?? 1000,
      speedAlertEnabled: json['speedAlertEnabled'] as bool? ?? false,
      speedLimit: (json['speedLimit'] as num?)?.toDouble() ?? 120,
      voiceAlertsEnabled: json['voiceAlertsEnabled'] as bool? ?? false,
      autoRideDetection: json['autoRideDetection'] as bool? ?? false,
      crashDetection: json['crashDetection'] as bool? ?? false,
      backgroundTracking: json['backgroundTracking'] as bool? ?? false,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
    );
  }
}
