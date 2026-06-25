import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/services/storage_service.dart';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/models/geofence.dart';
import 'package:vortex_dashboard/models/member_info.dart';
import 'package:vortex_dashboard/models/activity.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/providers/activity_provider.dart';
import 'package:vortex_dashboard/providers/geofence_provider.dart';
import 'package:vortex_dashboard/services/geofence_service.dart';
import 'package:vortex_dashboard/services/notification_service.dart';
import 'package:vortex_dashboard/widgets/map/map_enums.dart';
import 'package:vortex_dashboard/widgets/map/geofence_overlay.dart';
import 'package:vortex_dashboard/widgets/map/map_button.dart';
import 'package:vortex_dashboard/widgets/map/user_marker.dart';
import 'package:vortex_dashboard/widgets/map/member_marker.dart';
import 'package:vortex_dashboard/widgets/map/member_card.dart';
import 'package:vortex_dashboard/widgets/map/style_sheet.dart';
import 'package:vortex_dashboard/widgets/map/status_bar.dart';
import 'package:vortex_dashboard/widgets/map/bottom_info_bar.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool isEmbeddedInShell;
  const MapScreen({super.key, this.isEmbeddedInShell = false});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapController;
  bool _mapReady = false;
  bool _mapError = false;
  String _mapErrorMessage = '';
  Timer? _mapReadyTimeout;

  MapStyleLabel _mapStyle = MapStyleLabel.satelliteHybrid;

  MapCameraMode _cameraMode = MapCameraMode.initial;

  double? _userScreenX;
  double? _userScreenY;
  final Map<String, Map<String, double>> _memberScreenPos = {};
  Timer? _screenPosTimer;

  double _currentZoom = 18.0;
  double _currentBearing = 0.0;
  double _currentPitch = 0.0;

  static const double _minZoom = 3.0;
  static const double _maxZoom = 22.0;
  static const double _defaultLat = -6.2088;
  static const double _defaultLng = 106.8456;

  bool _programmaticMove = false;
  bool _showMembers = true;

  Timer? _geofenceTimer;

  List<GeofenceRenderData> _geofenceRenderData = [];
  String? _activeGeofenceId;
  String? _activeGeofenceLabel;
  StreamSubscription<GeofenceEvent>? _geofenceEventSub;
  String? _userPhotoPath;
  String? _selectedMemberId;
  final Map<String, Offset> _prevMemberPositions = {};
  final Set<String> _expandedClusters = {};
  double _arrowTurns = 0;
  double _lastArrowHeading = -1;

  @override
  void initState() {
    super.initState();
    _loadSavedStyle();
    _userPhotoPath = StorageService.instance.getString('user_photo_path');
    if (_userPhotoPath!.isEmpty) _userPhotoPath = null;
    _geofenceEventSub = GeofenceService().eventStream.listen(_onGeofenceEvent);
    _mapReadyTimeout = Timer(const Duration(seconds: 20), () {
      if (!_mapReady && mounted) {
        setState(() {
          _mapError = true;
          _mapErrorMessage = 'Map initialization timeout';
        });
      }
    });
    _geofenceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_mapReady && _mapController != null && mounted) {
        _updateGeofenceScreenData();
      }
    });
  }

  Future<void> _loadSavedStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('mapStyle') ?? 'satelliteHybrid';
    final style = MapStyleLabel.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => MapStyleLabel.satelliteHybrid,
    );
    if (mounted) setState(() => _mapStyle = style);
  }

  Future<void> _saveStyle(MapStyleLabel style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mapStyle', style.name);
  }

  void _onGeofenceEvent(GeofenceEvent event) {
    if (event.isEntry) {
      notificationService.addArrival('You', event.geofenceName);
    } else {
      notificationService.addDeparture('You', event.geofenceName);
    }
  }

  @override
  void dispose() {
    _screenPosTimer?.cancel();
    _mapReadyTimeout?.cancel();
    _geofenceTimer?.cancel();
    _geofenceEventSub?.cancel();
    super.dispose();
  }

  double _computeHeading(GpsData? gpsData, double compassHeading) {
    final speed = gpsData?.speed ?? 0;
    final gpsH = gpsData?.heading ?? -1;
    if (speed > 5 && gpsH >= 0) return gpsH;
    return compassHeading;
  }

  void _onCameraChanged(CameraChangedEventData data) {
    if (_cameraMode == MapCameraMode.focus && !_programmaticMove && mounted) {
      setState(() => _selectedMemberId = null);
      _cameraMode = MapCameraMode.overview;
      _showOverview();
    }
  }

  void _onScroll(_) {
    if (_selectedMemberId != null && mounted) {
      setState(() => _selectedMemberId = null);
      _showOverview();
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapReadyTimeout?.cancel();
    _mapController = mapboxMap;
    mapboxMap.setBounds(CameraBoundsOptions(minZoom: _minZoom, maxZoom: _maxZoom));
    setState(() => _mapReady = true);
    _startScreenPosUpdates();
  }

  void _showOverview() {
    if (!_mapReady || _mapController == null) return;
    final members = ref.read(activeGroupMembersProvider);
    final loc = ref.read(currentLocationProvider);
    if (loc['lat'] == 0 && members.isEmpty) return;

    double minLat, maxLat, minLng, maxLng;
    if (members.isNotEmpty && loc['lat'] != 0) {
      minLat = loc['lat']!;
      maxLat = loc['lat']!;
      minLng = loc['lng']!;
      maxLng = loc['lng']!;
      for (final m in members) {
        if (m.latitude == null || m.longitude == null) continue;
        if (m.latitude == 0 && m.longitude == 0) continue;
        minLat = min(minLat, m.latitude!);
        maxLat = max(maxLat, m.latitude!);
        minLng = min(minLng, m.longitude!);
        maxLng = max(maxLng, m.longitude!);
      }
    } else if (members.isNotEmpty) {
      final lat = members.first.latitude ?? 0.0;
      final lng = members.first.longitude ?? 0.0;
      minLat = lat - 0.01;
      maxLat = lat + 0.01;
      minLng = lng - 0.01;
      maxLng = lng + 0.01;
    } else {
      minLat = loc['lat']! - 0.01;
      maxLat = loc['lat']! + 0.01;
      minLng = loc['lng']! - 0.01;
      maxLng = loc['lng']! + 0.01;
    }

    final pad = 0.5;
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final latDiff = (maxLat - minLat) + pad * 2;
    final lngDiff = (maxLng - minLng) + pad * 2;
    final maxDiff = max(latDiff, lngDiff);

    double zoom;
    if (maxDiff > 20) {
      zoom = 4;
    } else if (maxDiff > 10) {
      zoom = 5;
    } else if (maxDiff > 5) {
      zoom = 6;
    } else if (maxDiff > 2) {
      zoom = 7;
    } else if (maxDiff > 1) {
      zoom = 8;
    } else if (maxDiff > 0.5) {
      zoom = 9;
    } else if (maxDiff > 0.2) {
      zoom = 10;
    } else if (maxDiff > 0.1) {
      zoom = 11;
    } else if (maxDiff > 0.05) {
      zoom = 12;
    } else {
      zoom = 13;
    }

    _programmaticMove = true;
    _mapController!
        .flyTo(
          CameraOptions(
            center: Point(coordinates: Position(centerLng, centerLat)),
            zoom: zoom.clamp(_minZoom, _maxZoom),
            bearing: 0,
            pitch: 0,
          ),
          MapAnimationOptions(duration: 1000),
        )
        .then((_) => _programmaticMove = false)
        .catchError((_) => _programmaticMove = false);
    _cameraMode = MapCameraMode.overview;
  }

  void _focusOnMember(double lat, double lng) {
    if (!_mapReady || _mapController == null) return;
    _cameraMode = MapCameraMode.focus;
    _programmaticMove = true;
    _mapController!
        .flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lng, lat)),
            zoom: _maxZoom,
            bearing: 0,
            pitch: 0,
          ),
          MapAnimationOptions(duration: 600),
        )
        .then((_) => _programmaticMove = false)
        .catchError((_) => _programmaticMove = false);
  }

  void _updateGeofenceScreenData() async {
    if (_mapController == null || !mounted) return;
    final geofences = ref.read(geofenceListProvider);
    final loc = ref.read(currentLocationProvider);
    if (geofences.isEmpty) {
      if (mounted && _geofenceRenderData.isNotEmpty) {
        setState(() => _geofenceRenderData = []);
      }
      return;
    }
    try {
      final data = <GeofenceRenderData>[];
      String? insideId;
      String? insideLabel;
      for (final gf in geofences) {
        if (!gf.enabled) continue;
        try {
          final center = await _mapController!.pixelForCoordinate(
            Point(coordinates: Position(gf.longitude, gf.latitude)),
          );
          final cosLat = cos(gf.latitude * pi / 180);
          final metersPerPixel = cosLat * 40075016.686 / (256 * pow(2, _currentZoom));
          final radius = gf.radiusMeters / metersPerPixel;
          data.add(GeofenceRenderData(
            screenCenter: Offset(center.x, center.y),
            screenRadius: radius,
            color: gf.typeColor,
            name: gf.name,
          ));
          if (gf.isInside(loc['lat'] ?? 0, loc['lng'] ?? 0)) {
            insideId = gf.id;
            insideLabel = gf.name;
          }
        } catch (_) {}
      }
      if (loc['lat'] != 0 && loc['lng'] != 0) {
        GeofenceService().checkGeofences(loc['lat']!, loc['lng']!);
      }
      if (mounted) {
        setState(() {
          _geofenceRenderData = data;
          _activeGeofenceId = insideId;
          _activeGeofenceLabel = insideLabel;
        });
      }
    } catch (_) {}
  }

  void _startScreenPosUpdates() {
    _screenPosTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_mapReady || _mapController == null || !mounted) return;
      final loc = ref.read(currentLocationProvider);
      if (loc['lat'] == 0 && loc['lng'] == 0) return;
      try {
        final screen = await _mapController!.pixelForCoordinate(
          Point(coordinates: Position(loc['lng']!, loc['lat']!)),
        );
        final cam = await _mapController!.getCameraState();

        if (mounted) {
          setState(() {
            _userScreenX = screen.x;
            _userScreenY = screen.y;
            _currentZoom = cam.zoom;
            _currentBearing = cam.bearing;
            _currentPitch = cam.pitch;
          });
        }

        if (_cameraMode == MapCameraMode.initial && _mapReady) {
          _showOverview();
        }

        final members = ref.read(activeGroupMembersProvider);
        if (_showMembers) {
          final newPos = <String, Map<String, double>>{};
          for (final m in members) {
            if (m.latitude == null || m.longitude == null) continue;
            if (m.latitude == 0 && m.longitude == 0) continue;
            try {
              final screen = await _mapController!.pixelForCoordinate(
                Point(coordinates: Position(m.longitude!, m.latitude!)),
              );
              newPos[m.id] = {'x': screen.x, 'y': screen.y};
            } catch (_) {}
          }
          if (mounted) setState(() => _memberScreenPos..clear()..addAll(newPos));
        }
      } catch (_) {}
    });
  }

  void _showStyleSheet() {
    MapStyleSheet.show(context,
      currentStyle: _mapStyle,
      onStyleChanged: (style) {
        setState(() => _mapStyle = style);
        _saveStyle(style);
        _changeStyle(style);
      },
    );
  }

  void _showMemberProfile(MemberInfo member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemberProfileSheet(member: member, onLocate: () {
        Navigator.pop(context);
        setState(() => _selectedMemberId = member.id);
        _focusOnMember(member.latitude ?? 0, member.longitude ?? 0);
      }),
    );
  }

  void _changeStyle(MapStyleLabel style) async {
    setState(() => _mapStyle = style);
    if (_mapController != null) {
      try {
        await _mapController!.loadStyleURI(style.uri);
      } catch (_) {}
    }
  }

  void _showGroupOverview() {
    setState(() => _selectedMemberId = null);
    _showOverview();
  }

  String _getActivityEmoji(dynamic activity) {
    if (activity == null) return '\u{1F4CD}';
    final String label;
    if (activity is String) {
      label = activity;
    } else if (activity is MemberInfo) {
      label = activity.activity;
    } else {
      try { label = activity.activityLabel; } catch (_) { return '\u{1F4CD}'; }
    }
    if (label == 'Walking') return '\u{1F6B6}';
    if (label == 'Running') return '\u{1F3C3}';
    if (label == 'Cycling') return '\u{1F6B4}';
    if (label == 'Driving') return '\u{1F697}';
    if (label == 'Stationary') return '\u{1F9CD}';
    return '\u{1F4CD}';
  }

  Color _speedColor(double speed) {
    if (speed < 1) return Colors.white;
    if (speed < 40) return ThemeConstants.successColor;
    if (speed < 80) return ThemeConstants.warningColor;
    return const Color(0xFFFF1744);
  }

  String _headingDir(double heading) {
    final dirs = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    return dirs[((heading + 11.25) / 22.5).floor() % 16];
  }

  List<Widget> _buildMemberMarkers() {
    if (!_mapReady || !_showMembers) return [];
    final myId = ref.read(userIdProvider);
    final allMembers = ref.read(activeGroupMembersProvider);
    final members = <String, MemberInfo>{};
    for (final m in allMembers) {
      if (m.id == myId) continue;
      if (_memberScreenPos.containsKey(m.id)) {
        members[m.id] = m;
      }
    }
    if (members.isEmpty) return [];

    final widgets = <Widget>[];

    final clusters = <String, List<MapEntry<String, MemberInfo>>>{};
    final processed = <String>{};

    for (final m in members.entries) {
      if (processed.contains(m.key)) continue;
      final cluster = <MapEntry<String, MemberInfo>>[MapEntry(m.key, m.value)];
      processed.add(m.key);

      for (final n in members.entries) {
        if (processed.contains(n.key)) continue;
        final dist = _haversine(
          m.value.latitude ?? 0, m.value.longitude ?? 0,
          n.value.latitude ?? 0, n.value.longitude ?? 0,
        );
        if (dist < 0.01) {
          cluster.add(MapEntry(n.key, n.value));
          processed.add(n.key);
        }
      }

      final key = cluster.map((e) => e.key).join(',');
      clusters[key] = cluster;
    }

    for (final cluster in clusters.values) {
      final count = cluster.length;
      final isCluster = count > 1 && !_expandedClusters.contains(cluster.first.key);

      if (isCluster) {
        double cx = 0, cy = 0;
        int valid = 0;
        for (final entry in cluster) {
          final pos = _memberScreenPos[entry.key];
          if (pos != null) {
            cx += pos['x']!;
            cy += pos['y']!;
            valid++;
          }
        }
        if (valid == 0) continue;
        cx /= valid;
        cy /= valid;

        widgets.add(
          Positioned(
            key: ValueKey('cluster_${cluster.first.key}'),
            left: cx - 28, top: cy - 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  for (final e in cluster) {
                    _expandedClusters.add(e.key);
                  }
                });
              },
              child: MemberClusterBadge(count: count),
            ),
          ),
        );
      } else {
        for (var i = 0; i < count; i++) {
          final entry = cluster[i];
          final pos = _memberScreenPos[entry.key];
          if (pos == null) continue;
          final member = entry.value;

          double ox = 0, oy = 0;
          if (count > 1) {
            final angle = (360 / count * i) * (3.14159 / 180);
            ox = (count > 2 ? 40 : 32) * cos(angle);
            oy = (count > 2 ? 40 : 32) * sin(angle);
          }

          final x = pos['x']! + ox;
          final y = pos['y']! + oy;
          final prev = _prevMemberPositions[entry.key];
          _prevMemberPositions[entry.key] = Offset(x, y);

          final showSpeed = _selectedMemberId == member.id;
          final heading = member.speed > 5 ? (member.heading ?? 0.0) : 0.0;

          widgets.add(
            AnimatedPositioned(
              key: ValueKey('m_${member.id}'),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: x - 22, top: y - 22,
              child: MemberMapMarker(
                memberId: member.id,
                memberName: member.displayName,
                photoUrl: member.avatarUrl,
                isOnline: member.presence == 'online',
                heading: heading,
                onTap: () {
                  if (_selectedMemberId == member.id) {
                    setState(() => _selectedMemberId = null);
                    _showOverview();
                  } else {
                    setState(() => _selectedMemberId = member.id);
                    _focusOnMember(member.latitude ?? 0, member.longitude ?? 0);
                    _showMemberProfile(member);
                  }
                },
              ),
            ),
          );

          final isSelected = _selectedMemberId == member.id;
          if (isSelected) {
            widgets.add(
              AnimatedPositioned(
                key: ValueKey('mn_${member.id}'),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: x - 30, top: y + 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MemberNameLabel(name: member.displayName),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: member.presence == 'online'
                            ? const Color(0xFF00E676).withAlpha(160)
                            : member.presence == 'away'
                                ? const Color(0xFFFFC107).withAlpha(160)
                                : Colors.red.withAlpha(160),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        member.speed > 0
                            ? '${member.speed.toStringAsFixed(0)} km/h'
                            : member.activity,
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    }

    return widgets;
  }

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

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    final gpsData = ref.watch(gpsDataProvider);
    final compassHeading = ref.watch(compassHeadingProvider);
    final heading = _computeHeading(gpsData, compassHeading);
    final speed = gpsData?.speed ?? 0;
    final gpsH = gpsData?.heading ?? -1;
    final activity = ref.watch(currentActivityProvider).valueOrNull;
    final members = ref.watch(activeGroupMembersProvider);
    final otherMembers = ref.watch(otherMembersProvider);
    final uid = ref.watch(userIdProvider);
    final me = uid != null ? members.where((m) => m.id == uid).firstOrNull : null;
    final activityLabel = activity?.activityLabel ?? 'Stationary';
    final activityEmoji = _getActivityEmoji(activity);
    final lastUpdate = gpsData?.timestamp;
    final lastUpdateAgo = lastUpdate != null ? '${DateTime.now().difference(lastUpdate).inSeconds}s' : '--';

    if (heading != _lastArrowHeading) {
      _lastArrowHeading = heading;
      final target = heading / 360.0;
      double diff = target - _arrowTurns;
      if (diff > 0.5) diff -= 1.0;
      if (diff < -0.5) diff += 1.0;
      _arrowTurns += diff;
    }

    return PopScope(
      canPop: _selectedMemberId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (_selectedMemberId != null && !didPop) {
          setState(() => _selectedMemberId = null);
          _showOverview();
        }
      },
      child: widget.isEmbeddedInShell
          ? _buildMapContent(context, heading, gpsData, speed, gpsH, activity, members, otherMembers, uid, me, activityLabel, activityEmoji, lastUpdateAgo)
          : Scaffold(
              backgroundColor: Colors.black,
              extendBodyBehindAppBar: true,
              body: _buildMapContent(context, heading, gpsData, speed, gpsH, activity, members, otherMembers, uid, me, activityLabel, activityEmoji, lastUpdateAgo),
            ),
    );
  }

  Widget _buildMapContent(BuildContext context, double heading, GpsData? gpsData, double speed, double gpsH, ActivityData? activity, List<MemberInfo> members, List<MemberInfo> otherMembers, String? uid, MemberInfo? me, String activityLabel, String activityEmoji, String lastUpdateAgo) {
    final screenPad = MediaQuery.of(context).padding;
    return Stack(
      children: [
            MapWidget(
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(_defaultLng, _defaultLat)),
                zoom: 18,
              ),
              mapOptions: MapOptions(
                pixelRatio: 1.0,
                constrainMode: ConstrainMode.NONE,
                orientation: NorthOrientation.UPWARDS,
              ),
              styleUri: _mapStyle.uri,
              onMapCreated: _onMapCreated,
              onCameraChangeListener: _onCameraChanged,
              onScrollListener: _onScroll,
            ),

            if (_mapReady && _geofenceRenderData.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: GeofenceOverlayPainter(
                      geofences: _geofenceRenderData,
                    ),
                  ),
                ),
              ),

            if (_mapReady && _userScreenX != null && _userScreenY != null)
              Positioned(
                left: _userScreenX! - 30,
                top: _userScreenY! - 40,
                child: UserMapMarker(
                  arrowTurns: _arrowTurns,
                  activityEmoji: activityEmoji,
                  photoUrl: _userPhotoPath,
                  battery: me?.battery ?? 100,
                  speed: speed.toStringAsFixed(0),
                  speedColor: _speedColor(speed),
                  onTap: _showGroupOverview,
                ),
              ),

            ..._buildMemberMarkers(),

            if (widget.isEmbeddedInShell)
              Positioned(
                top: screenPad.top + 8,
                left: 12,
                child: GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D0D0D).withAlpha(200),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Center(
                      child: Text(activityEmoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ),

            // Compact status pills
            if (_mapReady && widget.isEmbeddedInShell)
              Positioned(
                top: screenPad.top + 8,
                left: 60,
                right: 60,
                child: _buildStatusPills(gpsData, members.length, lastUpdateAgo),
              ),

            // Full status bar for standalone mode
            if (_mapReady && !widget.isEmbeddedInShell)
              Positioned(
                top: screenPad.top + 12,
                left: 60,
                right: 60,
                child: MapStatusBar(
                  accuracy: '${(gpsData?.accuracy ?? 0).toStringAsFixed(0)}m',
                  memberCount: members.length,
                  lastUpdateAgo: lastUpdateAgo,
                ),
              ),

            if (_mapReady && _activeGeofenceLabel != null && _activeGeofenceId != null)
              Positioned(
                top: screenPad.top + 60,
                left: 64,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withAlpha(180),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, size: 12, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text(
                        'In $_activeGeofenceLabel',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Right side action buttons
            Positioned(
              top: screenPad.top + 56,
              right: 16,
              child: Column(
                children: [
                  MapButton(
                    icon: Icons.layers,
                    onPressed: _mapReady ? _showStyleSheet : null,
                    active: false,
                    tooltip: 'Map Style',
                  ),
                ],
              ),
            ),

            // Floating member card
            if (_mapReady && otherMembers.isNotEmpty && _showMembers)
              Positioned(
                left: 16,
                top: widget.isEmbeddedInShell ? screenPad.top + 56 : screenPad.top + 104,
                child: FloatingMembersCard(
                  members: otherMembers,
                  memberCount: members.length,
                  onMemberTap: (m) {
                    setState(() => _selectedMemberId = m.id);
                    _focusOnMember(m.latitude ?? 0, m.longitude ?? 0);
                    _showMemberProfile(m);
                  },
                ),
              ),

            // Bottom right controls
            Positioned(
              right: 16,
              bottom: widget.isEmbeddedInShell ? 100 : 200,
              child: Column(
                children: [
                  if (members.length > 1) ...[
                    MapButton(
                      icon: Icons.groups,
                      onPressed: _mapReady ? _showGroupOverview : null,
                      active: _selectedMemberId != null,
                      tooltip: 'Group Overview',
                    ),
                    const SizedBox(height: 8),
                  ],
                  MapButton(
                    icon: Icons.add,
                    onPressed: _mapReady ? _zoomIn : null,
                    active: false,
                    tooltip: 'Zoom In',
                  ),
                  const SizedBox(height: 8),
                  MapButton(
                    icon: Icons.remove,
                    onPressed: _mapReady ? _zoomOut : null,
                    active: false,
                    tooltip: 'Zoom Out',
                  ),
                ],
              ),
            ),

            // Bottom info bar (standalone only)
            if (!widget.isEmbeddedInShell)
              Positioned(
                left: 16,
                right: 16,
                bottom: screenPad.bottom + 16,
                child: BottomInfoBar(
                  distance: '12.3',
                  altitude: '${(gpsData?.altitude ?? 0).toStringAsFixed(0)}',
                  heading: heading.toStringAsFixed(0),
                  headingDir: _headingDir(heading),
                  accuracy: '${(gpsData?.accuracy ?? 0).toStringAsFixed(0)}',
                  memberCount: members.length,
                ),
              ),

            // Loading/error overlay
            if (!_mapReady || _mapError)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_mapError)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ThemeConstants.primaryColor,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          _mapError ? _mapErrorMessage : 'Loading map...',
                          style: TextStyle(
                            fontSize: 12,
                            color: _mapError
                                ? const Color(0xFFFF1744)
                                : Colors.white.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
  }

  void _zoomIn() async {
    if (!_mapReady || _mapController == null) return;
    try {
      final cam = await _mapController!.getCameraState();
      final z = (cam.zoom + 1).clamp(_minZoom, _maxZoom);
      _programmaticMove = true;
      await _mapController!.flyTo(
        CameraOptions(center: cam.center, zoom: z, bearing: cam.bearing, pitch: cam.pitch),
        MapAnimationOptions(duration: 200),
      );
      _programmaticMove = false;
    } catch (_) {
      _programmaticMove = false;
    }
  }

  void _zoomOut() async {
    if (!_mapReady || _mapController == null) return;
    try {
      final cam = await _mapController!.getCameraState();
      final z = (cam.zoom - 1).clamp(_minZoom, _maxZoom);
      _programmaticMove = true;
      await _mapController!.flyTo(
        CameraOptions(center: cam.center, zoom: z, bearing: cam.bearing, pitch: cam.pitch),
        MapAnimationOptions(duration: 200),
      );
      _programmaticMove = false;
    } catch (_) {
      _programmaticMove = false;
    }
  }

  Widget _buildStatusPills(GpsData? gpsData, int memberCount, String lastUpdateAgo) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gps_fixed, size: 12, color: Color(0xFF00E676)),
          const SizedBox(width: 4),
          Text('${(gpsData?.accuracy ?? 0).toStringAsFixed(0)}m', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          const Icon(Icons.people, size: 12, color: Color(0xFF448AFF)),
          const SizedBox(width: 4),
          Text('$memberCount', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E676))),
          const SizedBox(width: 4),
          const Text('Live', style: TextStyle(fontSize: 11, color: Color(0xFF00E676), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MemberProfileSheet extends StatelessWidget {
  final MemberInfo member;
  final VoidCallback onLocate;

  const _MemberProfileSheet({required this.member, required this.onLocate});

  @override
  Widget build(BuildContext context) {
    final emoji = _profileEmoji(member.activity);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16, right: 16, top: 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            child: Text(emoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 12),
          Text(member.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _presenceColor(member.presence).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.presence == 'online' ? 'Online' : member.presence == 'away' ? 'Away' : 'Offline',
              style: TextStyle(fontSize: 12, color: _presenceColor(member.presence), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(Icons.speed, '${member.speed.toStringAsFixed(1)} km/h'),
              _stat(Icons.battery_charging_full, '${member.battery?.toInt() ?? 0}%'),
              _stat(Icons.directions_walk, member.activity),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLocate,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Locate on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _presenceColor(String presence) {
    if (presence == 'online') return const Color(0xFF00E676);
    if (presence == 'away') return const Color(0xFFFFC107);
    return Colors.red;
  }

  String _profileEmoji(String activity) {
    switch (activity) {
      case 'Walking': return '\u{1F6B6}';
      case 'Running': return '\u{1F3C3}';
      case 'Cycling': return '\u{1F6B4}';
      case 'Driving': return '\u{1F697}';
      case 'Stationary': return '\u{1F9CD}';
      default: return '\u{1F4CD}';
    }
  }
}
