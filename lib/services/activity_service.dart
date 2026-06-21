import 'dart:async';
import 'package:vortex_dashboard/models/activity.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._();
  factory ActivityService() => _instance;
  ActivityService._();

  final _activityController = StreamController<ActivityData>.broadcast();
  Stream<ActivityData> get activityStream => _activityController.stream;

  ActivityData _currentActivity = ActivityData();
  ActivityData get currentActivity => _currentActivity;

  double _lastSpeed = 0;
  DateTime _lastUpdate = DateTime.now();
  int _stationaryCount = 0;

  void updateSpeed(double speedKmh) {
    final now = DateTime.now();
    final dt = now.difference(_lastUpdate).inMilliseconds / 1000;

    _lastSpeed = speedKmh;
    _lastUpdate = now;

    final detected = ActivityData.detectFromSpeed(speedKmh);
    final confidence = ActivityData.confidenceFromSpeed(speedKmh);

    if (detected == UserActivity.stationary) {
      _stationaryCount++;
    } else {
      _stationaryCount = 0;
    }

    if (_stationaryCount > 3) {
      _currentActivity = ActivityData(
        activity: UserActivity.stationary,
        confidence: 0.95,
        speed: speedKmh,
        timestamp: now,
      );
    } else if (_currentActivity.activity != detected || dt > 10) {
      _currentActivity = ActivityData(
        activity: detected,
        confidence: confidence,
        speed: speedKmh,
        timestamp: now,
      );
    }

    _activityController.add(_currentActivity);
  }

  void reset() {
    _currentActivity = ActivityData();
    _lastSpeed = 0;
    _stationaryCount = 0;
  }

  void dispose() {
    _activityController.close();
  }
}
