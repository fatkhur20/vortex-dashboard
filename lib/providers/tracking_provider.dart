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

final trackingIsActiveProvider = Provider<bool>((ref) {
  return ref.watch(trackingStateProvider).isTracking;
});

class TrackingState {
  final bool isTracking;
  final RideModel? currentRide;
  final double maxSpeed;
  final double avgSpeed;
  final double maxAltitude;
  final double totalDistance;
  final List<dynamic> trackPoints;
  final List<RideModel> rideHistory;

  TrackingState({
    this.isTracking = false,
    this.currentRide,
    this.maxSpeed = 0,
    this.avgSpeed = 0,
    this.maxAltitude = 0,
    this.totalDistance = 0,
    this.trackPoints = const [],
    this.rideHistory = const [],
  });

  TrackingState copyWith({
    bool? isTracking,
    RideModel? currentRide,
    double? maxSpeed,
    double? avgSpeed,
    double? maxAltitude,
    double? totalDistance,
    List<dynamic>? trackPoints,
    List<RideModel>? rideHistory,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      currentRide: currentRide ?? this.currentRide,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      totalDistance: totalDistance ?? this.totalDistance,
      trackPoints: trackPoints ?? this.trackPoints,
      rideHistory: rideHistory ?? this.rideHistory,
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
        trackPoints: List.from(service.trackPoints),
      );
    });
  }

  Future<RideModel?> stopTracking() async {
    final service = _ref.read(trackingServiceProvider);
    final ride = await service.stopTracking();

    state = TrackingState();

    return ride;
  }

  void loadHistory() {
    final repo = _ref.read(trackingServiceProvider);
  }
}
