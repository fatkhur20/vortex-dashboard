import 'package:flutter_riverpod/flutter_riverpod.dart';

final altimeterStateProvider =
    StateNotifierProvider<AltimeterStateNotifier, AltimeterData>((ref) {
  return AltimeterStateNotifier();
});

class AltimeterData {
  final double currentAltitude;
  final double maxAltitude;
  final double minAltitude;
  final double ascentRate;

  AltimeterData({
    this.currentAltitude = 0,
    this.maxAltitude = 0,
    this.minAltitude = 0,
    this.ascentRate = 0,
  });

  AltimeterData copyWith({
    double? currentAltitude,
    double? maxAltitude,
    double? minAltitude,
    double? ascentRate,
  }) {
    return AltimeterData(
      currentAltitude: currentAltitude ?? this.currentAltitude,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      minAltitude: minAltitude ?? this.minAltitude,
      ascentRate: ascentRate ?? this.ascentRate,
    );
  }
}

class AltimeterStateNotifier extends StateNotifier<AltimeterData> {
  AltimeterStateNotifier() : super(AltimeterData());

  void updateAltitude(double altitude) {
    state = state.copyWith(
      currentAltitude: altitude,
      maxAltitude: altitude > state.maxAltitude ? altitude : state.maxAltitude,
      minAltitude: altitude < state.minAltitude || state.minAltitude == 0
          ? altitude
          : state.minAltitude,
    );
  }

  void reset() {
    state = AltimeterData();
  }
}
