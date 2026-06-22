import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/app_constants.dart';
import 'package:vortex_dashboard/models/partner_location.dart';
import 'package:vortex_dashboard/models/activity.dart';
import 'package:vortex_dashboard/models/invite_code.dart';
import 'package:vortex_dashboard/models/user_profile.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/activity_provider.dart';
import 'package:vortex_dashboard/services/couple_api_service.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

class CoupleTrackingService {
  static final CoupleTrackingService _instance = CoupleTrackingService._();
  factory CoupleTrackingService() => _instance;
  CoupleTrackingService._();

  final _partnerLocationController = StreamController<PartnerLocation>.broadcast();
  Stream<PartnerLocation> get partnerLocationStream => _partnerLocationController.stream;

  final _pairStatusController = StreamController<PairInfo>.broadcast();
  Stream<PairInfo> get pairStatusStream => _pairStatusController.stream;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  bool _isPaired = false;
  bool get isPaired => _isPaired;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Timer? _uploadTimer;
  Timer? _pollTimer;
  StreamSubscription? _pairSub;

  final CoupleApiService _api = CoupleApiService();
  String? _userId;

  /// Initialize: load or register user, check pair status
  Future<UserProfile> initialize({String? displayName}) async {
    final store = StorageService();
    String? deviceId = store.getString(AppConstants.storageKeyCoupleDeviceId);

    if (deviceId.isEmpty) {
      deviceId = _generateDeviceId();
      await store.saveString(AppConstants.storageKeyCoupleDeviceId, deviceId);
    }

    final savedUserId = store.getString(AppConstants.storageKeyCoupleUserId);
    if (savedUserId.isNotEmpty) {
      _currentUser = UserProfile(
        id: savedUserId, deviceId: deviceId,
        displayName: displayName, createdAt: DateTime.now(),
      );
      _userId = savedUserId;
      try {
        final status = await _api.getPairStatus(_userId!);
        _isPaired = status.paired;
        _pairStatusController.add(status);
      } catch (_) {}
      return _currentUser!;
    }

    _currentUser = await _api.registerUser(deviceId: deviceId, displayName: displayName);
    _userId = _currentUser!.id;
    await store.saveString(AppConstants.storageKeyCoupleUserId, _currentUser!.id);
    _pairStatusController.add(const PairInfo(paired: false));
    return _currentUser!;
  }

  /// Start location sync & partner polling
  void startSync(Ref ref) {
    if (_userId == null) return;
    _isConnected = true;
    _connectionController.add(true);

    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (_) => _uploadLocation(ref));
    _pollTimer = Timer.periodic(const Duration(seconds: 5), () => _pollPartner(ref));
  }

  Future<InviteCode> createInvite() async {
    if (_userId == null) throw Exception('not initialized');
    final invite = await _api.createInvite(_userId!);
    return invite;
  }

  Future<Map<String, dynamic>> joinInvite(String code, {String? displayName}) async {
    if (_userId == null) throw Exception('not initialized');
    final result = await _api.joinInvite(
      code: code, userId: _userId!, displayName: displayName,
    );
    _isPaired = true;
    final status = await _api.getPairStatus(_userId!);
    _pairStatusController.add(status);
    return result;
  }

  Future<void> disconnectPair() async {
    if (_userId == null) return;
    await _api.disconnectPair(_userId!);
    _isPaired = false;
    _pairStatusController.add(const PairInfo(paired: false));
  }

  Future<PairInfo> refreshPairStatus() async {
    if (_userId == null) return const PairInfo(paired: false);
    final status = await _api.getPairStatus(_userId!);
    _isPaired = status.paired;
    _pairStatusController.add(status);
    return status;
  }

  void _uploadLocation(Ref ref) {
    final loc = ref.read(currentLocationProvider);
    final lat = loc['lat'] ?? 0.0;
    final lng = loc['lng'] ?? 0.0;
    if (lat == 0 && lng == 0 || _userId == null) return;

    _api.uploadLocation(
      userId: _userId!,
      latitude: lat,
      longitude: lng,
      altitude: ref.read(gpsDataProvider)?.altitude ?? 0,
      speed: ref.read(currentSpeedProvider),
      heading: ref.read(compassHeadingProvider),
      battery: 85,
      activity: ref.read(currentActivityLabelProvider),
    ).catchError((_) {});
  }

  void _pollPartner(Ref ref) {
    if (_userId == null || !_isPaired) return;
    _api.getPartnerLocation(_userId!).then((partner) {
      if (partner != null) {
        _partnerLocationController.add(partner.toPartnerLocation());
        _isConnected = true;
        _connectionController.add(true);
      }
    }).catchError((_) {
      _isConnected = false;
      _connectionController.add(false);
    });
  }

  void stopSync() {
    _uploadTimer?.cancel();
    _pollTimer?.cancel();
    _uploadTimer = null;
    _pollTimer = null;
  }

  void dispose() {
    stopSync();
    _partnerLocationController.close();
    _pairStatusController.close();
    _connectionController.close();
  }

  String _generateDeviceId() {
    final rng = Random();
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final rand = rng.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return 'd$now$rand';
  }
}
