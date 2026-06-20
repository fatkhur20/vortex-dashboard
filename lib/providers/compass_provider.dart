import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/services/compass_service.dart';

final compassServiceProvider = Provider<CompassService>((ref) {
  final service = CompassService();
  ref.onDispose(() => service.dispose());
  return service;
});

final compassHeadingProvider = StreamNotifierProvider<CompassHeadingNotifier, double>(
  CompassHeadingNotifier.new,
);

final compassDirectionProvider = Provider<String>((ref) {
  final heading = ref.watch(compassHeadingProvider);
  final directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  final index = ((heading + 11.25) / 22.5).floor() % 16;
  return directions[index];
});

final compassCalibratedProvider = StateProvider<bool>((ref) {
  final service = ref.watch(compassServiceProvider);
  return service.isCalibrated;
});

class CompassHeadingNotifier extends StreamNotifier<double> {
  @override
  Stream<double> build() {
    final service = ref.watch(compassServiceProvider);
    service.startListening();
    return service.headingStream;
  }
}
