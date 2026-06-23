import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark;
});

final useKmhProvider = StateNotifierProvider<UnitNotifier, bool>((ref) {
  return UnitNotifier();
});

final amoledModeProvider = StateNotifierProvider<AmoledNotifier, bool>((ref) {
  return AmoledNotifier(ref);
});

final alwaysOnDisplayProvider = StateNotifierProvider<AlwaysOnNotifier, bool>((ref) {
  return AlwaysOnNotifier();
});

final backgroundTrackingProvider = StateNotifierProvider<BackgroundTrackingNotifier, bool>((ref) {
  return BackgroundTrackingNotifier();
});

class UnitNotifier extends StateNotifier<bool> {
  UnitNotifier() : super(true);

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

class AmoledNotifier extends StateNotifier<bool> {
  final Ref _ref;
  AmoledNotifier(this._ref) : super(true);

  void toggle() {
    state = !state;
    _ref.read(themeModeProvider.notifier).state = state ? ThemeMode.dark : ThemeMode.dark;
  }
}

class AlwaysOnNotifier extends StateNotifier<bool> {
  AlwaysOnNotifier() : super(false);

  void toggle() => state = !state;
}

class BackgroundTrackingNotifier extends StateNotifier<bool> {
  BackgroundTrackingNotifier() : super(false);

  void toggle() => state = !state;
}
