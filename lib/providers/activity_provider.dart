import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/activity.dart';
import 'package:vortex_dashboard/services/activity_service.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';

final activityServiceProvider = Provider<ActivityService>((ref) {
  final service = ActivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final currentActivityProvider = StreamProvider<ActivityData>((ref) {
  final service = ref.watch(activityServiceProvider);
  final speed = ref.watch(currentSpeedProvider);

  service.updateSpeed(speed);

  return service.activityStream;
});

final currentActivityLabelProvider = Provider<String>((ref) {
  final activityAsync = ref.watch(currentActivityProvider);
  return activityAsync.when(
    data: (a) => a.activity.label,
    loading: () => '...',
    error: (_, __) => 'Unknown',
  );
});

final currentActivityIconProvider = Provider<String>((ref) {
  final activityAsync = ref.watch(currentActivityProvider);
  return activityAsync.when(
    data: (a) => a.activity.icon,
    loading: () => '❓',
    error: (_, __) => '❓',
  );
});

final isMovingProvider = Provider<bool>((ref) {
  final activityAsync = ref.watch(currentActivityProvider);
  return activityAsync.when(
    data: (a) => a.activity != UserActivity.stationary && a.activity != UserActivity.unknown,
    loading: () => false,
    error: (_, __) => false,
  );
});
