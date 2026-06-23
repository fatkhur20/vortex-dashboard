import 'dart:async';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/group_info.dart';
import 'package:vortex_dashboard/models/member_info.dart';
import 'package:vortex_dashboard/models/user_profile.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/activity_provider.dart';
import 'package:vortex_dashboard/services/life_tracker_api_service.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._();
  factory TrackingService() => _instance;
  TrackingService._();

  final LifeTrackerApiService _api = LifeTrackerApiService();
  final _membersController = StreamController<List<MemberInfo>>.broadcast();
  final _groupsController = StreamController<List<GroupInfo>>.broadcast();
  final _activeGroupController = StreamController<GroupInfo?>.broadcast();

  Stream<List<MemberInfo>> get membersStream => _membersController.stream;
  Stream<List<GroupInfo>> get groupsStream => _groupsController.stream;
  Stream<GroupInfo?> get activeGroupStream => _activeGroupController.stream;

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  String? _activeGroupId;
  String? get activeGroupId => _activeGroupId;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final Battery _battery = Battery();
  double _lastBatteryLevel = 100;
  Timer? _uploadTimer;
  Timer? _pollTimer;

  Future<UserProfile> initialize({String? displayName}) async {
    final store = StorageService();
    String? deviceId = store.getString('device_id');
    if (deviceId.isEmpty) {
      deviceId = 'd${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}${Random().nextInt(0xFFFFFF).toRadixString(16)}';
      await store.saveString('device_id', deviceId);
    }

    final savedUserId = store.getString('user_id');
    if (savedUserId.isNotEmpty) {
      try {
        final me = await _api.getMe(savedUserId);
        _currentUser = me;
        _isInitialized = true;
        if (displayName != null && displayName != me.displayName) {
          await _api.updateProfile(me.id, displayName: displayName);
          _currentUser = me.copyWith(displayName: displayName);
        }
        return _currentUser!;
      } catch (_) {
        // Saved ID invalid, re-register
      }
    }

    final result = await _api.registerUser(deviceId: deviceId, displayName: displayName);
    _currentUser = UserProfile(
      id: result['user_id'] as String, deviceId: deviceId,
      displayName: displayName, createdAt: DateTime.now(),
    );
    await store.saveString('user_id', _currentUser!.id);
    _isInitialized = true;

    // Auto-select personal group
    _activeGroupId = result['group_id'] as String?;
    return _currentUser!;
  }

  Future<String> getOrCreatePersonalGroup() async {
    final groups = await _api.getGroups(_currentUser!.id);
    final personal = groups.where((g) => g.memberCount == 1 && g.isOwner).toList();
    if (personal.isNotEmpty) {
      _activeGroupId = personal.first.id;
      return personal.first.id;
    }
    // Create one
    final g = await _api.createGroup(_currentUser!.id, 'My Space');
    _activeGroupId = g.id;
    return g.id;
  }

  Future<GroupInfo> createGroup(String name) async {
    final g = await _api.createGroup(_currentUser!.id, name);
    await refreshGroups();
    return g;
  }

  Future<void> joinGroup(String code) async {
    final result = await _api.joinInvite(code, _currentUser!.id, displayName: _currentUser?.displayName);
    await refreshGroups();
    _activeGroupId = result['group_id'] as String;
  }

  Future<Map<String, dynamic>> getInviteInfo(String code) async {
    return _api.getInviteInfo(code);
  }

  Future<Map<String, dynamic>> createInvite(String groupId) async {
    return _api.createInvite(groupId, _currentUser!.id);
  }

  Future<void> leaveGroup(String groupId) async {
    await _api.leaveGroup(groupId, _currentUser!.id);
    if (_activeGroupId == groupId) _activeGroupId = null;
    await refreshGroups();
  }

  Future<void> refreshGroups() async {
    if (_currentUser == null) return;
    final groups = await _api.getGroups(_currentUser!.id);
    _groupsController.add(groups);
    if (_activeGroupId == null && groups.isNotEmpty) {
      _activeGroupId = groups.first.id;
    }
  }

  Future<void> switchGroup(String groupId) async {
    _activeGroupId = groupId;
    await refreshMembers();
    _activeGroupController.add(null); // trigger reload
  }

  Future<void> refreshMembers() async {
    if (_activeGroupId == null) return;
    final members = await _api.getMembers(_activeGroupId!);
    _membersController.add(members);
  }

  void startSync(dynamic ref, {required String groupId}) {
    _activeGroupId = groupId;
    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (_) => _uploadLocation(ref));
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollMembers(ref));
    refreshGroups();
    refreshMembers();
  }

  Future<void> _uploadLocation(dynamic ref) async {
    if (_activeGroupId == null || _currentUser == null) return;
    final loc = ref.read(currentLocationProvider);
    final lat = loc['lat'] ?? 0.0;
    final lng = loc['lng'] ?? 0.0;
    if (lat == 0 && lng == 0) return;

    try {
      _lastBatteryLevel = (await _battery.batteryLevel).toDouble();
    } catch (_) {}

    _api.uploadLocation(
      userId: _currentUser!.id, groupId: _activeGroupId!,
      latitude: lat, longitude: lng,
      altitude: ref.read(gpsDataProvider)?.altitude ?? 0,
      speed: ref.read(currentSpeedProvider),
      heading: ref.read(compassHeadingProvider),
      battery: _lastBatteryLevel,
      activity: ref.read(currentActivityLabelProvider),
    ).catchError((_) {});
  }

  void _pollMembers(dynamic ref) {
    if (_activeGroupId == null) return;
    _api.getGroupLocations(_activeGroupId!).then((members) {
      _membersController.add(members);
    }).catchError((_) {});
  }

  void stopSync() {
    _uploadTimer?.cancel();
    _pollTimer?.cancel();
    _uploadTimer = null;
    _pollTimer = null;
  }

  void dispose() {
    stopSync();
    _membersController.close();
    _groupsController.close();
    _activeGroupController.close();
  }
}
