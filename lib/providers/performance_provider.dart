import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';

class PerformanceMetrics {
  final double currentSpeed;
  final double maxSpeed;
  final double averageSpeed;
  final Duration rideDuration;
  final double? zeroToSixtyTime;
  final double? zeroToHundredTime;
  final double? quarterMileTime;

  PerformanceMetrics({
    this.currentSpeed = 0,
    this.maxSpeed = 0,
    this.averageSpeed = 0,
    this.rideDuration = Duration.zero,
    this.zeroToSixtyTime,
    this.zeroToHundredTime,
    this.quarterMileTime,
  });

  PerformanceMetrics copyWith({
    double? currentSpeed,
    double? maxSpeed,
    double? averageSpeed,
    Duration? rideDuration,
    double? zeroToSixtyTime,
    double? zeroToHundredTime,
    double? quarterMileTime,
  }) {
    return PerformanceMetrics(
      currentSpeed: currentSpeed ?? this.currentSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      rideDuration: rideDuration ?? this.rideDuration,
      zeroToSixtyTime: zeroToSixtyTime ?? this.zeroToSixtyTime,
      zeroToHundredTime: zeroToHundredTime ?? this.zeroToHundredTime,
      quarterMileTime: quarterMileTime ?? this.quarterMileTime,
    );
  }
}

final performanceProvider =
    StateNotifierProvider<PerformanceNotifier, PerformanceMetrics>((ref) {
  return PerformanceNotifier(ref);
});

class PerformanceNotifier extends StateNotifier<PerformanceMetrics> {
  final Ref _ref;
  StreamSubscription? _speedSubscription;
  DateTime? _rideStartTime;
  DateTime? _zeroToSixtyStart;
  DateTime? _zeroToHundredStart;
  DateTime? _quarterMileStart;
  bool _zeroToSixtyRecorded = false;
  bool _zeroToHundredRecorded = false;
  bool _quarterMileRecorded = false;
  double _quarterMileDistance = 0;
  double _lastSpeed = 0;
  final List<double> _speedSamples = [];

  PerformanceNotifier(this._ref) : super(PerformanceMetrics());

  void startPerformanceMonitoring() {
    _rideStartTime = DateTime.now();
    _zeroToSixtyRecorded = false;
    _zeroToHundredRecorded = false;
    _quarterMileRecorded = false;
    _quarterMileDistance = 0;
    _speedSamples.clear();

    _speedSubscription = _ref.read(gpsDataProvider).listen((gpsData) {
      final speed = gpsData.speed;
      final now = DateTime.now();

      _speedSamples.add(speed);
      if (_speedSamples.length > 100) _speedSamples.removeAt(0);

      final avgSpeed = _speedSamples.isEmpty
          ? 0.0
          : _speedSamples.reduce((a, b) => a + b) / _speedSamples.length;

      final duration = _rideStartTime != null
          ? now.difference(_rideStartTime!)
          : Duration.zero;

      final maxSpeed = state.maxSpeed > speed ? state.maxSpeed : speed;

      // 0-60 timer
      if (!_zeroToSixtyRecorded && _lastSpeed < 60 && speed >= 60) {
        if (_zeroToSixtyStart != null) {
          final time = now.difference(_zeroToSixtyStart!).inMilliseconds / 1000.0;
          state = state.copyWith(zeroToSixtyTime: time);
          _zeroToSixtyRecorded = true;
        }
      }
      if (!_zeroToSixtyRecorded && _lastSpeed < 5 && speed >= 5) {
        _zeroToSixtyStart = now;
      }

      // 0-100 timer
      if (!_zeroToHundredRecorded && _lastSpeed < 100 && speed >= 100) {
        if (_zeroToHundredStart != null) {
          final time = now.difference(_zeroToHundredStart!).inMilliseconds / 1000.0;
          state = state.copyWith(zeroToHundredTime: time);
          _zeroToHundredRecorded = true;
        }
      }
      if (!_zeroToHundredRecorded && _lastSpeed < 5 && speed >= 5) {
        _zeroToHundredStart = now;
      }

      // Quarter mile (402 meters) timer
      if (!_quarterMileRecorded) {
        if (speed > 0) {
          if (_quarterMileStart == null) _quarterMileStart = now;
          _quarterMileDistance += speed * (1 / 3600); // approximate
          if (_quarterMileDistance >= 0.402) {
            final time = now.difference(_quarterMileStart!).inMilliseconds / 1000.0;
            state = state.copyWith(quarterMileTime: time);
            _quarterMileRecorded = true;
          }
        }
      }

      _lastSpeed = speed;

      state = PerformanceMetrics(
        currentSpeed: speed,
        maxSpeed: maxSpeed,
        averageSpeed: avgSpeed,
        rideDuration: duration,
        zeroToSixtyTime: state.zeroToSixtyTime,
        zeroToHundredTime: state.zeroToHundredTime,
        quarterMileTime: state.quarterMileTime,
      );
    });
  }

  void stopPerformanceMonitoring() {
    _speedSubscription?.cancel();
    _speedSubscription = null;
  }

  void reset() {
    state = PerformanceMetrics();
    _zeroToSixtyRecorded = false;
    _zeroToHundredRecorded = false;
    _quarterMileRecorded = false;
    _quarterMileDistance = 0;
    _lastSpeed = 0;
    _speedSamples.clear();
  }

  @override
  void dispose() {
    _speedSubscription?.cancel();
    super.dispose();
  }
}
