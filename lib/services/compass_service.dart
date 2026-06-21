import 'dart:async';
import 'dart:math';
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

  StreamSubscription? _magnetometerSubscription;
  StreamSubscription? _accelerometerSubscription;

  double _lastHeading = 0;
  static const double _smoothFactor = 0.3;

  static const double _rad2deg = 180.0 / pi;

  Future<void> startListening() async {
    try {
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(
        (AccelerometerEvent event) {
          _lastGravity = [event.x, event.y, event.z];
        },
        onError: (e) {},
      );
    } catch (_) {}

    try {
      _magnetometerSubscription = magnetometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(
        (MagnetometerEvent event) {
          _lastMagnetic = [event.x, event.y, event.z];
          _computeHeading();
        },
        onError: (e) {},
      );
    } catch (_) {}
  }

  List<double> _lastGravity = [0, 0, 9.8];
  List<double> _lastMagnetic = [0, 0, 0];

  void _computeHeading() {
    final g = _lastGravity;
    final m = _lastMagnetic;

    final normG = sqrt(g[0] * g[0] + g[1] * g[1] + g[2] * g[2]);
    if (normG < 0.1) return;

    final normM = sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]);
    if (normM < 0.1) return;

    final ax = g[0] / normG, ay = g[1] / normG, az = g[2] / normG;
    final ex = m[0] / normM, ey = m[1] / normM, ez = m[2] / normM;

    final Hx = ey * az - ez * ay;
    final Hy = ez * ax - ex * az;
    final Hz = ex * ay - ey * ax;

    final normH = sqrt(Hx * Hx + Hy * Hy + Hz * Hz);
    if (normH < 0.1) return;

    final nx = Hx / normH, ny = Hy / normH, nz = Hz / normH;

    final Mx = ay * nz - az * ny;
    final My = az * nx - ax * nz;

    var heading = atan2(ny, My) * _rad2deg;
    heading = (heading + 360) % 360;

    _currentHeading = _smoothFactor * heading + (1 - _smoothFactor) * _lastHeading;
    _lastHeading = _currentHeading;
    _isCalibrated = true;

    _headingController.add(_currentHeading);
  }

  void stopListening() {
    _magnetometerSubscription?.cancel();
    _magnetometerSubscription = null;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
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
