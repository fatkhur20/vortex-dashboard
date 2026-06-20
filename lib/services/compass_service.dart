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

  static const double _pi = pi;
  static const double _rad2deg = 180.0 / _pi;

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

    final Ax = g[0], Ay = g[1], Az = g[2];
    final normA = sqrt(Ax * Ax + Ay * Ay + Az * Az);
    if (normA < 0.1) return;

    final Ex = m[0], Ey = m[1], Ez = m[2];
    final normE = sqrt(Ex * Ex + Ey * Ey + Ez * Ez);
    if (normE < 0.1) return;

    final Hx = Ey * Az - Ez * Ay;
    final Hy = Ez * Ax - Ex * Az;
    final Hz = Ex * Ay - Ey * Ax;

    final normH = sqrt(Hx * Hx + Hy * Hy + Hz * Hz);
    if (normH < 0.1) return;

    final invH = 1.0 / normH;
    final Nx = Hx * invH;
    final Ny = Hy * invH;
    final Nz = Hz * invH;

    final invA = 1.0 / normA;
    final Mx = Ny * Az - Nz * Ay;
    final My = Nz * Ax - Nx * Az;

    final Mx2 = Ex * Mx + Ey * My + Ez * Nz;
    final My2 = Ex * (Ay * Nz - Az * Ny) + Ey * (Az * Nx - Ax * Nz) + Ez * (Ax * Ny - Ay * Nx);

    var heading = atan2(My2, Mx2) * _rad2deg;
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
