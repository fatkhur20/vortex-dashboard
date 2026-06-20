import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark;
});

final useKmhProvider = StateNotifierProvider<UnitNotifier, bool>((ref) {
  return UnitNotifier(ref);
});

final amoledModeProvider = StateNotifierProvider<AmoledNotifier, bool>((ref) {
  return AmoledNotifier(ref);
});

final alwaysOnDisplayProvider = StateNotifierProvider<AlwaysOnNotifier, bool>((ref) {
  return AlwaysOnNotifier(ref);
});

final gpsRefreshRateProvider = StateNotifierProvider<GpsRefreshNotifier, int>((ref) {
  return GpsRefreshNotifier(ref);
});

final speedAlertProvider = StateNotifierProvider<SpeedAlertNotifier, SpeedAlertState>((ref) {
  return SpeedAlertNotifier(ref);
});

final voiceAlertsProvider = StateNotifierProvider<VoiceAlertsNotifier, bool>((ref) {
  return VoiceAlertsNotifier(ref);
});

final autoRideDetectionProvider = StateNotifierProvider<AutoRideNotifier, bool>((ref) {
  return AutoRideNotifier(ref);
});

final crashDetectionProvider = StateNotifierProvider<CrashDetectionNotifier, bool>((ref) {
  return CrashDetectionNotifier(ref);
});

final backgroundTrackingProvider = StateNotifierProvider<BackgroundTrackingNotifier, bool>((ref) {
  return BackgroundTrackingNotifier(ref);
});

class SpeedAlertState {
  final bool enabled;
  final double limit;

  SpeedAlertState({this.enabled = false, this.limit = 120});

  SpeedAlertState copyWith({bool? enabled, double? limit}) {
    return SpeedAlertState(
      enabled: enabled ?? this.enabled,
      limit: limit ?? this.limit,
    );
  }
}

class UnitNotifier extends StateNotifier<bool> {
  final Ref _ref;
  UnitNotifier(this._ref) : super(true);

  void toggle() {
    state = !state;
    _ref.read(settingsRepositoryProvider).saveUnitPreference(state);
  }

  void set(bool value) {
    state = value;
    _ref.read(settingsRepositoryProvider).saveUnitPreference(value);
  }
}

class AmoledNotifier extends StateNotifier<bool> {
  final Ref _ref;
  AmoledNotifier(this._ref) : super(true);

  void toggle() {
    state = !state;
    _ref.read(settingsRepositoryProvider).saveThemeMode(state);
    _ref.read(themeModeProvider.notifier).state =
        state ? ThemeMode.dark : ThemeMode.dark;
  }

  void set(bool value) {
    state = value;
    _ref.read(settingsRepositoryProvider).saveThemeMode(value);
  }
}

class AlwaysOnNotifier extends StateNotifier<bool> {
  final Ref _ref;
  AlwaysOnNotifier(this._ref) : super(false);

  void toggle() {
    state = !state;
    _ref.read(settingsRepositoryProvider).saveAlwaysOnDisplay(state);
  }
}

class GpsRefreshNotifier extends StateNotifier<int> {
  final Ref _ref;
  GpsRefreshNotifier(this._ref) : super(1000);

  void set(int ms) {
    state = ms;
    _ref.read(settingsRepositoryProvider).saveGpsRefreshRate(ms);
  }
}

class SpeedAlertNotifier extends StateNotifier<SpeedAlertState> {
  final Ref _ref;
  SpeedAlertNotifier(this._ref) : super(SpeedAlertState());

  void toggle() {
    state = state.copyWith(enabled: !state.enabled);
    _ref.read(settingsRepositoryProvider)
        .saveSpeedAlert(state.enabled, state.limit);
  }

  void setLimit(double limit) {
    state = state.copyWith(limit: limit);
    _ref.read(settingsRepositoryProvider)
        .saveSpeedAlert(state.enabled, limit);
  }
}

class VoiceAlertsNotifier extends StateNotifier<bool> {
  final Ref _ref;
  VoiceAlertsNotifier(this._ref) : super(false);

  void toggle() {
    state = !state;
    _ref.read(settingsRepositoryProvider).saveVoiceAlerts(state);
  }
}

class AutoRideNotifier extends StateNotifier<bool> {
  final Ref _ref;
  AutoRideNotifier(this._ref) : super(false);

  void toggle() {
    state = !state;
    _ref.read(settingsRepositoryProvider).saveAutoRideDetection(state);
  }
}

class CrashDetectionNotifier extends StateNotifier<bool> {
  final Ref _ref;
  CrashDetectionNotifier(this._ref) : super(false);

  void toggle() {
    state = !state;
    _ref.read(settingsRepositoryProvider).saveCrashDetection(state);
  }
}

class BackgroundTrackingNotifier extends StateNotifier<bool> {
  final Ref _ref;
  BackgroundTrackingNotifier(this._ref) : super(false);

  void toggle() {
    state = !state;
    _ref.read(settingsRepositoryProvider).saveBackgroundTracking(state);
  }
}
