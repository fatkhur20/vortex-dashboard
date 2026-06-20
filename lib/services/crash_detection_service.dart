import 'dart:math';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class CrashDetectionService {
  static final CrashDetectionService _instance = CrashDetectionService._();
  factory CrashDetectionService() => _instance;
  CrashDetectionService._();

  bool _isMonitoring = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  final _crashController = StreamController<bool>.broadcast();
  Stream<bool> get crashStream => _crashController.stream;

  bool _crashDetected = false;
  bool get crashDetected => _crashDetected;

  double _lastAcceleration = 0;
  int _highGCount = 0;
  static const double _crashThreshold = 40.0;
  static const int _requiredHighGCount = 5;
  double _currentAcceleration = 0;

  double get currentAcceleration => _currentAcceleration;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _crashDetected = false;

    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(
      (AccelerometerEvent event) {
        _currentAcceleration = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        final delta = (_currentAcceleration - _lastAcceleration).abs();
        _lastAcceleration = _currentAcceleration;

        if (delta > _crashThreshold) {
          _highGCount++;
          if (_highGCount >= _requiredHighGCount && !_crashDetected) {
            _crashDetected = true;
            _crashController.add(true);
          }
        } else {
          _highGCount = (_highGCount - 1).clamp(0, _requiredHighGCount);
        }
      },
    );
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isMonitoring = false;
    _crashDetected = false;
    _highGCount = 0;
  }

  void resetCrashDetection() {
    _crashDetected = false;
    _highGCount = 0;
  }

  void dispose() {
    stopMonitoring();
    _crashController.close();
  }
}
