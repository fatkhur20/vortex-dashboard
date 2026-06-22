import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/partner_location.dart';
import 'package:vortex_dashboard/models/invite_code.dart';
import 'package:vortex_dashboard/models/user_profile.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/activity_provider.dart';
import 'package:vortex_dashboard/services/couple_tracking_service.dart';

final coupleTrackingServiceProvider = Provider<CoupleTrackingService>((ref) {
  final service = CoupleTrackingService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Current user profile (auto-registered)
final currentUserProvider = StateProvider<UserProfile?>((_) => null);

/// Whether user is initialized (registered + ID stored)
final userInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(coupleTrackingServiceProvider);
  final user = await service.initialize();
  ref.read(currentUserProvider.notifier).state = user;
  return user.id.isNotEmpty;
});

/// Pair status (paired or not)
final pairStatusProvider = StreamProvider<PairInfo>((ref) {
  final service = ref.watch(coupleTrackingServiceProvider);
  return service.pairStatusStream;
});

/// Whether user has a partner
final isPairedProvider = Provider<bool>((ref) {
  return ref.watch(coupleTrackingServiceProvider).isPaired;
});

/// Current user ID (convenience)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.read(coupleTrackingServiceProvider).currentUser?.id;
});

/// Partner location stream
final partnerLocationProvider = StreamProvider<PartnerLocation?>((ref) {
  final service = ref.watch(coupleTrackingServiceProvider);
  return service.partnerLocationStream.map((e) => e);
});

/// Stream for creating invite
final inviteCodeProvider = FutureProvider.family<InviteCode, void>((ref, _) async {
  final service = ref.read(coupleTrackingServiceProvider);
  return service.createInvite();
});

/// Partner distance
final coupleDistanceProvider = Provider<String>((ref) {
  final partnerAsync = ref.watch(partnerLocationProvider);
  final userLoc = ref.watch(currentLocationProvider);
  return partnerAsync.when(
    data: (partner) {
      if (partner == null) return '--';
      final d = _haversine(
        userLoc['lat']!, userLoc['lng']!,
        partner.latitude, partner.longitude,
      );
      if (d < 1) return '${(d * 1000).toStringAsFixed(0)}m';
      return '${d.toStringAsFixed(1)}km';
    },
    loading: () => '--',
    error: (_, __) => '--',
  );
});

/// Partner online status
final partnerOnlineProvider = Provider<bool>((ref) {
  final partnerAsync = ref.watch(partnerLocationProvider);
  return partnerAsync.when(
    data: (p) => p?.isOnline ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Partner display name
final partnerNameProvider = Provider<String>((ref) {
  final pairAsync = ref.watch(pairStatusProvider);
  return pairAsync.when(
    data: (p) => p.partner?.displayName ?? 'Partner',
    loading: () => '--',
    error: (_, __) => '--',
  );
});

/// Partner battery level
final partnerBatteryProvider = Provider<double?>((ref) {
  final partnerAsync = ref.watch(partnerLocationProvider);
  return partnerAsync.when(
    data: (p) => p?.batteryLevel,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Partner activity label
final partnerActivityProvider = Provider<String>((ref) {
  final partnerAsync = ref.watch(partnerLocationProvider);
  return partnerAsync.when(
    data: (p) => p?.activity ?? '--',
    loading: () => '--',
    error: (_, __) => '--',
  );
});

/// Partner ETA
final coupleEtaProvider = Provider<String>((ref) {
  final partnerAsync = ref.watch(partnerLocationProvider);
  final speed = ref.watch(currentSpeedProvider);
  return partnerAsync.when(
    data: (partner) {
      if (partner == null || speed < 1) return '--';
      final userLoc = ref.read(currentLocationProvider);
      final d = _haversine(userLoc['lat']!, userLoc['lng']!, partner.latitude, partner.longitude);
      final hours = d / speed;
      if (hours * 60 < 1) return '<1 min';
      if (hours < 1) return '${(hours * 60).ceil()} min';
      return '${hours.toStringAsFixed(1)} h';
    },
    loading: () => '--',
    error: (_, __) => '--',
  );
});

/// Connection status string
final partnerConnectionStatusProvider = Provider<String>((ref) {
  final connected = ref.watch(coupleTrackingServiceProvider).isConnected;
  final paired = ref.watch(isPairedProvider);
  if (!paired) return 'Not paired';
  return connected ? 'Connected' : 'Offline';
});

/// Pair action provider (create invite / join / disconnect)
final pairActionProvider = Provider<PairActions>((ref) {
  final service = ref.read(coupleTrackingServiceProvider);
  return PairActions(service);
});

class PairActions {
  final CoupleTrackingService _service;
  PairActions(this._service);

  Future<InviteCode> createInvite() => _service.createInvite();
  Future<Map<String, dynamic>> joinInvite(String code, {String? name}) =>
    _service.joinInvite(code, displayName: name);
  Future<void> disconnect() => _service.disconnectPair();
  Future<PairInfo> refresh() => _service.refreshPairStatus();
}

// ── Haversine ──

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = _sin2(dLat / 2) + _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLon / 2);
  return r * 2 * _asin(_sqrt(a));
}

double _rad(double d) => d * 3.141592653589793 / 180;
double _sin2(double x) { final s = _sin(x); return s * s; }
double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
double _asin(double x) => x + x * x * x / 6 + x * x * x * x * x * 3 / 40;
double _sqrt(double x) => x < 0 ? 0 : x > 1 ? 1 : x == 0 ? 0 : _sqrtNewton(x, x);
double _sqrtNewton(double x, double g) => (g * g - x).abs() < 1e-10 ? g : _sqrtNewton(x, (g + x / g) / 2);
