import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CompassService {
  static final CompassService _instance = CompassService._();
  factory CompassService() => _instance;
  CompassService._();

  final _headingController = StreamController<double>.broadcast();
  Stream<double> get headingStream => _headingController.stream;

  double _currentHeading = 0;
  double get currentHeading => _currentHeading;

  bool _isCalibrated = false;
  bool get isCalibrated => _isCalibrated;

  StreamSubscription? _compassSubscription;
  StreamSubscription? _magnetometerSubscription;

  Future<void> startListening() async {
    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (event.heading != null) {
          _currentHeading = event.heading!;
          _isCalibrated = event.accuracy != null && event.accuracy! > 0;
          _headingController.add(_currentHeading);
        }
      },
      onError: (error) {
        _startMagnetometerFallback();
      },
    );
  }

  void _startMagnetometerFallback() {
    _magnetometerSubscription = magnetometerEventStream().listen(
      (MagnetometerEvent event) {
        final radians = atan2(event.y, event.x);
        var degrees = radians * 180 / pi;
        degrees = (degrees + 360) % 360;
        _currentHeading = degrees;
        _headingController.add(_currentHeading);
      },
    );
  }

  void stopListening() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _magnetometerSubscription?.cancel();
    _magnetometerSubscription = null;
  }

  String get headingString {
    final directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((_currentHeading + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  void dispose() {
    stopListening();
    _headingController.close();
  }
}
