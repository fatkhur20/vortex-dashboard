import 'package:vortex_dashboard/services/gps_service.dart';
import 'package:vortex_dashboard/core/constants/app_constants.dart';

class SpeedAlertService {
  static final SpeedAlertService _instance = SpeedAlertService._();
  factory SpeedAlertService() => _instance;
  SpeedAlertService._();

  bool _isEnabled = false;
  double _speedLimit = 120;
  bool _overspeedActive = false;
  bool _voiceAlertsEnabled = false;

  bool get isEnabled => _isEnabled;
  double get speedLimit => _speedLimit;
  bool get overspeedActive => _overspeedActive;
  bool get voiceAlertsEnabled => _voiceAlertsEnabled;

  final _speedAlertController = _SpeedAlertController();

  _SpeedAlertController get controller => _speedAlertController;

  void configure({
    required bool enabled,
    required double limit,
    required bool voiceAlerts,
  }) {
    _isEnabled = enabled;
    _speedLimit = limit;
    _voiceAlertsEnabled = voiceAlerts;
  }

  void checkSpeed(double currentSpeed) {
    if (!_isEnabled) return;

    if (currentSpeed >= _speedLimit && !_overspeedActive) {
      _overspeedActive = true;
      _speedAlertController.addWarning('Speed limit exceeded: ${currentSpeed.toStringAsFixed(0)} km/h');
    } else if (currentSpeed < _speedLimit - 5 && _overspeedActive) {
      _overspeedActive = false;
      _speedAlertController.addClear('Speed returned to normal');
    }

    if (currentSpeed >= AppConstants.speedCriticalThreshold) {
      _speedAlertController.addCritical(
        'CRITICAL: ${currentSpeed.toStringAsFixed(0)} km/h! Slow down!',
      );
    }
  }

  void reset() {
    _overspeedActive = false;
  }

  void dispose() {
    _speedAlertController.dispose();
  }
}

class _SpeedAlertController {
  final _warningController = StreamController<String>.broadcast();
  final _criticalController = StreamController<String>.broadcast();
  final _clearController = StreamController<String>.broadcast();

  Stream<String> get warningStream => _warningController.stream;
  Stream<String> get criticalStream => _criticalController.stream;
  Stream<String> get clearStream => _clearController.stream;

  void addWarning(String message) {
    _warningController.add(message);
  }

  void addCritical(String message) {
    _criticalController.add(message);
  }

  void addClear(String message) {
    _clearController.add(message);
  }

  void dispose() {
    _warningController.close();
    _criticalController.close();
    _clearController.close();
  }
}
