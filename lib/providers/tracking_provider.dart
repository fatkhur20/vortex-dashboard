import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/ride_model.dart';
import 'package:vortex_dashboard/services/location_tracking_service.dart';

final trackingServiceProvider = Provider<LocationTrackingService>((ref) {
  final service = LocationTrackingService();
  ref.onDispose(() => service.dispose());
  return service;
});

final trackingStateProvider =
    StateNotifierProvider<TrackingStateNotifier, TrackingState>((ref) {
  return TrackingStateNotifier(ref);
});

class TrackingState {
  final bool isTracking;
  final RideModel? currentRide;
  final double maxSpeed;
  final double maxAltitude;
  final double totalDistance;

  TrackingState({
    this.isTracking = false,
    this.currentRide,
    this.maxSpeed = 0,
    this.maxAltitude = 0,
    this.totalDistance = 0,
  });

  TrackingState copyWith({
    bool? isTracking,
    RideModel? currentRide,
    double? maxSpeed,
    double? maxAltitude,
    double? totalDistance,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      currentRide: currentRide ?? this.currentRide,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }
}

class TrackingStateNotifier extends StateNotifier<TrackingState> {
  final Ref _ref;

  TrackingStateNotifier(this._ref) : super(TrackingState());

  Future<void> startTracking() async {
    final service = _ref.read(trackingServiceProvider);
    await service.startTracking();

    state = state.copyWith(isTracking: true);

    service.trackingStream.listen((ride) {
      state = state.copyWith(
        currentRide: ride,
        maxSpeed: service.maxSpeed,
        maxAltitude: service.maxAltitude,
        totalDistance: service.totalDistance,
      );
    });
  }

  Future<RideModel?> stopTracking() async {
    final service = _ref.read(trackingServiceProvider);
    final ride = await service.stopTracking();

    state = TrackingState();

    return ride;
  }
}
