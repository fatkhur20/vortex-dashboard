import 'package:vortex_dashboard/core/constants/app_constants.dart';
import 'package:vortex_dashboard/models/trip_settings.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

class SettingsRepository {
  final StorageService _storage;

  SettingsRepository() : _storage = StorageService();

  TripSettings loadSettings() {
    return TripSettings(
      useKmh: _storage.getBool(AppConstants.storageKeyUnit, defaultValue: true),
      amoledMode: _storage.getBool(AppConstants.storageKeyAmoled, defaultValue: true),
      alwaysOnDisplay: _storage.getBool(AppConstants.storageKeyAlwaysOn, defaultValue: false),
      gpsRefreshRateMs: _storage.getInt(AppConstants.storageKeyGpsRefresh, defaultValue: 1000),
      speedAlertEnabled: _storage.getBool(AppConstants.storageKeySpeedAlert, defaultValue: false),
      speedLimit: _storage.getDouble(AppConstants.storageKeySpeedLimit, defaultValue: 120),
      voiceAlertsEnabled: _storage.getBool(AppConstants.storageKeyVoiceAlerts, defaultValue: false),
      autoRideDetection: _storage.getBool(AppConstants.storageKeyAutoRide, defaultValue: false),
      crashDetection: _storage.getBool(AppConstants.storageKeyCrashDetection, defaultValue: false),
      backgroundTracking: _storage.getBool(AppConstants.storageKeyBackgroundTracking, defaultValue: false),
      emergencyContactName: _storage.getString(AppConstants.storageKeyEmergencyContact),
      emergencyContactPhone: _storage.getString(AppConstants.storageKeyEmergencyContact + '_phone'),
      distanceTripA: _storage.getDouble(AppConstants.tripAKey, defaultValue: 0),
      distanceTripB: _storage.getDouble(AppConstants.tripBKey, defaultValue: 0),
      odometerTotal: _storage.getDouble(AppConstants.odometerKey, defaultValue: 0),
    );
  }

  Future<void> saveUnitPreference(bool useKmh) async {
    await _storage.saveBool(AppConstants.storageKeyUnit, useKmh);
  }

  Future<void> saveThemeMode(bool amoled) async {
    await _storage.saveBool(AppConstants.storageKeyAmoled, amoled);
  }

  Future<void> saveAlwaysOnDisplay(bool alwaysOn) async {
    await _storage.saveBool(AppConstants.storageKeyAlwaysOn, alwaysOn);
  }

  Future<void> saveGpsRefreshRate(int ms) async {
    await _storage.saveInt(AppConstants.storageKeyGpsRefresh, ms);
  }

  Future<void> saveSpeedAlert(bool enabled, double limit) async {
    await _storage.saveBool(AppConstants.storageKeySpeedAlert, enabled);
    await _storage.saveDouble(AppConstants.storageKeySpeedLimit, limit);
  }

  Future<void> saveVoiceAlerts(bool enabled) async {
    await _storage.saveBool(AppConstants.storageKeyVoiceAlerts, enabled);
  }

  Future<void> saveAutoRideDetection(bool enabled) async {
    await _storage.saveBool(AppConstants.storageKeyAutoRide, enabled);
  }

  Future<void> saveCrashDetection(bool enabled) async {
    await _storage.saveBool(AppConstants.storageKeyCrashDetection, enabled);
  }

  Future<void> saveBackgroundTracking(bool enabled) async {
    await _storage.saveBool(AppConstants.storageKeyBackgroundTracking, enabled);
  }

  Future<void> saveEmergencyContact(String name, String phone) async {
    await _storage.saveString(AppConstants.storageKeyEmergencyContact, name);
    await _storage.saveString(AppConstants.storageKeyEmergencyContact + '_phone', phone);
  }

  Future<void> saveTripDistance(String tripKey, double distance) async {
    await _storage.saveDouble(tripKey, distance);
  }

  Future<void> resetTripA() async {
    await _storage.saveDouble(AppConstants.tripAKey, 0);
  }

  Future<void> resetTripB() async {
    await _storage.saveDouble(AppConstants.tripBKey, 0);
  }

  Future<void> exportSettings() async {
    // Export settings as JSON
    final settings = loadSettings();
    final json = settings.toJson();
    await _storage.saveString('settings_backup', json.toString());
  }

  Future<void> importSettings() async {
    final jsonStr = _storage.getString('settings_backup');
    if (jsonStr.isNotEmpty) {
      final json = Map<String, dynamic>.from(jsonStr as Map);
      final settings = TripSettings.fromJson(json);
      await saveUnitPreference(settings.useKmh);
      await saveThemeMode(settings.amoledMode);
      await saveAlwaysOnDisplay(settings.alwaysOnDisplay);
      await saveGpsRefreshRate(settings.gpsRefreshRateMs);
      await saveSpeedAlert(settings.speedAlertEnabled, settings.speedLimit);
      await saveVoiceAlerts(settings.voiceAlertsEnabled);
      await saveAutoRideDetection(settings.autoRideDetection);
      await saveCrashDetection(settings.crashDetection);
      await saveBackgroundTracking(settings.backgroundTracking);
      if (settings.emergencyContactName != null) {
        await saveEmergencyContact(
          settings.emergencyContactName!,
          settings.emergencyContactPhone ?? '',
        );
      }
    }
  }
}
