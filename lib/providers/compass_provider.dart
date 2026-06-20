import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/services/compass_service.dart';

final compassServiceProvider = Provider<CompassService>((ref) {
  final service = CompassService();
  ref.onDispose(() => service.dispose());
  return service;
});

final compassHeadingProvider = StateNotifierProvider<CompassHeadingNotifier, double>((ref) {
  return CompassHeadingNotifier(ref);
});

class CompassHeadingNotifier extends StateNotifier<double> {
  StreamSubscription? _sub;
  final Ref _ref;

  CompassHeadingNotifier(this._ref) : super(0) {
    final service = _ref.read(compassServiceProvider);
    try {
      service.startListening();
    } catch (_) {}
    _sub = service.headingStream.listen(
      (h) { state = h; },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final compassDirectionProvider = Provider<String>((ref) {
  final heading = ref.watch(compassHeadingProvider);
  final directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  final index = ((heading + 11.25) / 22.5).floor() % 16;
  return directions[index];
});

final compassCalibratedProvider = Provider<bool>((ref) {
  return ref.watch(compassServiceProvider).isCalibrated;
});
