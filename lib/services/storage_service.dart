import 'package:hive/hive.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ?? StorageService._();
  factory StorageService() => _instance ?? StorageService._();
  StorageService._();

  static Future<void> initialize() async {
    await Hive.openBox('settings');
    await Hive.openBox('tracking');
    await Hive.openBox('geofences');
    _instance = StorageService._();
  }

  Box get _settingsBox => Hive.box('settings');
  Box get _trackingBox => Hive.box('tracking');

  Box? getBox(String name) => Hive.isBoxOpen(name) ? Hive.box(name) : null;

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveBool(String key, bool value) async {
    await _settingsBox.put(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveInt(String key, int value) async {
    await _settingsBox.put(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveDouble(String key, double value) async {
    await _settingsBox.put(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveString(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveTrackingData(String key, dynamic value) async {
    await _trackingBox.put(key, value);
  }

  dynamic getTrackingData(String key, {dynamic defaultValue}) {
    return _trackingBox.get(key, defaultValue: defaultValue);
  }

  Future<void> clearTrackingData() async {
    await _trackingBox.clear();
  }
}
