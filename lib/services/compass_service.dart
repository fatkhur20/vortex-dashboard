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

  List<double> _gravity = [0, 0, 0];
  List<double> _geomagnetic = [0, 0, 0];

  Future<void> startListening() async {
    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          _gravity = [event.x, event.y, event.z];
          _computeHeading();
        },
        onError: (_) {},
      );
    } catch (_) {}

    try {
      _magnetometerSubscription = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          _geomagnetic = [event.x, event.y, event.z];
          _computeHeading();
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _computeHeading() {
    final gx = _gravity[0], gy = _gravity[1], gz = _gravity[2];
    final mx = _geomagnetic[0], my = _geomagnetic[1], mz = _geomagnetic[2];

    final norm = sqrt(gx * gx + gy * gy + gz * gz);
    if (norm == 0) return;
    final ax = gx / norm, ay = gy / norm, az = gz / norm;

    final ex = my * az - mz * ay;
    final ey = mz * ax - mx * az;
    final ez = mx * ay - my * ax;

    final eNorm = sqrt(ex * ex + ey * ey + ez * ez);
    if (eNorm == 0) return;
    final nx = ex / eNorm, ny = ey / eNorm, nz = ez / eNorm;

    final mx2 = mx * nx + my * ny + mz * nz;
    final my2 = mx * (ay * nz - az * ny) + my * (az * nx - ax * nz) + mz * (ax * ny - ay * nx);

    var heading = atan2(my2, mx2) * 180 / pi;
    heading = (heading + 360) % 360;

    _currentHeading = heading;
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
