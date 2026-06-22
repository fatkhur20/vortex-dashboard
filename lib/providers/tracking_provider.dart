import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/group_info.dart';
import 'package:vortex_dashboard/models/member_info.dart';
import 'package:vortex_dashboard/models/user_profile.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/services/tracking_service.dart';
import 'package:vortex_dashboard/services/life_tracker_api_service.dart';

final trackingServiceProvider = Provider<TrackingService>((ref) {
  final svc = TrackingService();
  ref.onDispose(() => svc.dispose());
  return svc;
});

final apiServiceProvider = Provider<LifeTrackerApiService>((_) => LifeTrackerApiService());

final userInitializedProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(trackingServiceProvider);
  await svc.initialize();
  return true;
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.read(trackingServiceProvider).currentUser;
});

final userIdProvider = Provider<String?>((ref) {
  return ref.read(trackingServiceProvider).currentUser?.id;
});

final isInitializedProvider = Provider<bool>((ref) {
  return ref.read(trackingServiceProvider).isInitialized;
});

// ── Groups ──

final groupsProvider = StreamProvider<List<GroupInfo>>((ref) {
  return ref.watch(trackingServiceProvider).groupsStream;
});

final activeGroupIdProvider = StateProvider<String?>((ref) {
  return ref.read(trackingServiceProvider).activeGroupId;
});

final activeGroupProvider = Provider<GroupInfo?>((ref) {
  final groupsAsync = ref.watch(groupsProvider);
  final activeId = ref.watch(activeGroupIdProvider);
  return groupsAsync.whenOrNull(data: (groups) {
    if (activeId == null) return groups.isNotEmpty ? groups.first : null;
    return groups.where((g) => g.id == activeId).firstOrNull;
  });
});

// ── Members ──

final membersProvider = StreamProvider<List<MemberInfo>>((ref) {
  return ref.watch(trackingServiceProvider).membersStream;
});

final activeGroupMembersProvider = Provider<List<MemberInfo>>((ref) {
  final membersAsync = ref.watch(membersProvider);
  return membersAsync.whenOrNull(data: (m) => m) ?? [];
});

final myMemberInfoProvider = Provider<MemberInfo?>((ref) {
  final members = ref.watch(activeGroupMembersProvider);
  final uid = ref.watch(userIdProvider);
  if (uid == null) return null;
  try {
    return members.firstWhere((m) => m.id == uid);
  } catch (_) {
    return null;
  }
});

final otherMembersProvider = Provider<List<MemberInfo>>((ref) {
  final members = ref.watch(activeGroupMembersProvider);
  final uid = ref.watch(userIdProvider);
  return members.where((m) => m.id != uid).toList();
});

// ── Location (from current user) ──

final currentMemberLatLngProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(currentLocationProvider);
});

// ── Connection Status ──

final connectionStatusProvider = Provider<String>((ref) {
  final members = ref.watch(activeGroupMembersProvider);
  final uid = ref.watch(userIdProvider);
  if (uid == null) return 'Initializing';
  try {
    final me = members.firstWhere((m) => m.id == uid);
    if (me.presence == 'online') return 'Connected';
    if (me.presence == 'away') return 'Away';
    return 'Offline';
  } catch (_) {
    return 'Connecting';
  }
});

// ── Group Actions ──

final groupActionsProvider = Provider<GroupActions>((ref) {
  return GroupActions(ref.read(trackingServiceProvider));
});

class GroupActions {
  final TrackingService _svc;
  GroupActions(this._svc);

  Future<GroupInfo> create(String name) => _svc.createGroup(name);
  Future<void> join(String code) => _svc.joinGroup(code);
  Future<void> leave(String groupId) => _svc.leaveGroup(groupId);
  Future<Map<String, dynamic>> createInvite(String groupId) => _svc.createInvite(groupId);
  Future<Map<String, dynamic>> getInviteInfo(String code) => _svc.getInviteInfo(code);
  Future<void> switchGroup(String groupId) => _svc.switchGroup(groupId);
  Future<void> refresh() => _svc.refreshGroups();
}
