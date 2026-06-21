import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/models/partner_location.dart';
import 'package:vortex_dashboard/models/geofence.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/partner_provider.dart';
import 'package:vortex_dashboard/providers/activity_provider.dart';
import 'package:vortex_dashboard/providers/geofence_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

enum MapStyle { satelliteHybrid, streets, dark, outdoors, custom }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  MapboxMap? _mapController;
  bool _mapReady = false;
  bool _mapError = false;
  String _mapErrorMessage = '';
  Timer? _mapReadyTimeout;

  bool _followUser = true;
  bool _headingUp = false;
  MapStyle _mapStyle = MapStyle.satelliteHybrid;
  bool _showDebug = true;

  double? _userScreenX;
  double? _userScreenY;
  double? _partnerScreenX;
  double? _partnerScreenY;
  Timer? _screenPosTimer;

  double _currentZoom = 18.0;
  double _currentBearing = 0.0;
  double _currentPitch = 0.0;

  static const double _initialZoom = 18.0;
  static const double _minZoom = 3.0;
  static const double _maxZoom = 20.0;
  static const double _defaultLat = -6.2088;
  static const double _defaultLng = 106.8456;

  bool _programmaticMove = false;

  bool _show3D = true;
  bool _showTerrain = true;
  bool _satelliteOverlay = false;
  bool _showGeofences = true;
  bool _showPartner = true;

  double _renderFps = 0;
  int _frameCount = 0;
  DateTime _fpsStart = DateTime.now();
  Timer? _fpsTimer;

  AnimationController? _partnerPulseController;
  AnimationController? _glowController;

  static const List<String> _styleUris = {
    MapStyle.satelliteHybrid: 'mapbox://styles/mapbox/satellite-streets-v12',
    MapStyle.streets: 'mapbox://styles/mapbox/streets-v12',
    MapStyle.dark: 'mapbox://styles/mapbox/dark-v11',
    MapStyle.outdoors: 'mapbox://styles/mapbox/outdoors-v12',
    MapStyle.custom: 'mapbox://styles/mapbox/streets-v12',
  };

  String get _styleUri => _styleUris[_mapStyle]!;

  @override
  void initState() {
    super.initState();
    _mapReadyTimeout = Timer(const Duration(seconds: 20), () {
      if (!_mapReady && mounted) {
        setState(() {
          _mapError = true;
          _mapErrorMessage = 'Map initialization timeout';
        });
      }
    });
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _renderFps = _frameCount.toDouble();
          _frameCount = 0;
        });
      }
    });
    _partnerPulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _screenPosTimer?.cancel();
    _mapReadyTimeout?.cancel();
    _fpsTimer?.cancel();
    _partnerPulseController?.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  double _computeHeading(GpsData? gpsData, double compassHeading) {
    final speed = gpsData?.speed ?? 0;
    final gpsH = gpsData?.heading ?? -1;
    if (speed > 5 && gpsH >= 0) return gpsH;
    if (compassHeading > 0) return compassHeading;
    if (gpsH >= 0) return gpsH;
    return 0;
  }

  double? _lastBearing;
  double _lastFollowLat = 0;
  double _lastFollowLng = 0;

  void _onCameraChanged(CameraChangedEventData data) {
    _frameCount++;
    if (!_programmaticMove && _followUser && mounted) {
      setState(() => _followUser = false);
    }
    _programmaticMove = false;
  }

  void _onScroll(_) {
    if (_followUser && mounted) {
      setState(() => _followUser = false);
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapReadyTimeout?.cancel();
    _mapController = mapboxMap;
    mapboxMap.setBounds(CameraBoundsOptions(
      minZoom: _minZoom,
      maxZoom: _maxZoom,
    ));
    setState(() => _mapReady = true);
    _startScreenPosUpdates();
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
        if (_followUser) {
          final lat = loc['lat']!;
          final lng = loc['lng']!;
          if (lat != _lastFollowLat || lng != _lastFollowLng) {
            _lastFollowLat = lat;
            _lastFollowLng = lng;
            _followToUser(lat, lng);
          }
        }
        final partner = ref.read(partnerLocationProvider).valueOrNull;
        if (partner != null && _showPartner) {
          final pscreen = await _mapController!.pixelForCoordinate(
            Point(coordinates: Position(partner.longitude, partner.latitude)),
          );
          if (mounted) {
            setState(() {
              _partnerScreenX = pscreen.x;
              _partnerScreenY = pscreen.y;
            });
          }
        }
      } catch (_) {}
    });
  }

  void _toggleFollow() {
    if (!_mapReady) return;
    setState(() {
      _followUser = true;
      _lastFollowLat = 0;
      _lastFollowLng = 0;
    });
  }

  void _followToUser(double lat, double lng) async {
    if (!_mapReady || _mapController == null) return;
    try {
      final cam = await _mapController!.getCameraState();
      _programmaticMove = true;
      await _mapController!.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: cam.zoom,
          bearing: _headingUp
              ? _computeHeading(
                  ref.read(gpsDataProvider),
                  ref.read(compassHeadingProvider),
                )
              : 0,
        ),
      );
      _programmaticMove = false;
    } catch (_) {
      _programmaticMove = false;
    }
  }

  void _toggleHeadingUp() {
    setState(() {
      _headingUp = !_headingUp;
      _lastBearing = null;
    });
  }

  void _applyCameraBearing(double heading) async {
    if (!_mapReady || _mapController == null) return;
    final target = _headingUp ? heading : 0.0;
    if (_lastBearing == target) return;
    _lastBearing = target;
    try {
      final cam = await _mapController!.getCameraState();
      _programmaticMove = true;
      await _mapController!.setCamera(
        CameraOptions(
          center: cam.center,
          zoom: cam.zoom,
          bearing: target,
          pitch: cam.pitch,
        ),
      );
      _programmaticMove = false;
    } catch (_) {
      _programmaticMove = false;
    }
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

  Future<void> _recenter() async {
    if (!_mapReady || _mapController == null) return;
    final loc = ref.read(currentLocationProvider);
    if (loc['lat'] == 0) return;
    try {
      _programmaticMove = true;
      await _mapController!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(loc['lng']!, loc['lat']!)),
          zoom: _initialZoom,
          bearing: _headingUp ? _computeHeading(ref.read(gpsDataProvider), ref.read(compassHeadingProvider)) : 0,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 800),
      );
      _programmaticMove = false;
      setState(() => _followUser = true);
    } catch (_) {
      _programmaticMove = false;
    }
  }

  void _changeStyle(MapStyle style) async {
    setState(() => _mapStyle = style);
    if (_mapController != null) {
      try {
        await _mapController!.loadStyleURI(_styleUri);
      } catch (_) {}
    }
  }

  void _toggle3D() {
    setState(() => _show3D = !_show3D);
    if (_mapController != null) {
      _apply3DSettings();
    }
  }

  void _toggleTerrain() {
    setState(() => _showTerrain = !_showTerrain);
    if (_mapController != null) {
      _applyTerrainSettings();
    }
  }

  Future<void> _apply3DSettings() async {
    if (_mapController == null || !_mapReady) return;
    try {
      final cam = await _mapController!.getCameraState();
      final targetPitch = _show3D ? 60.0 : 0.0;
      if (cam.pitch != targetPitch) {
        _programmaticMove = true;
        await _mapController!.setCamera(
          CameraOptions(
            center: cam.center,
            zoom: cam.zoom,
            bearing: cam.bearing,
            pitch: targetPitch,
          ),
        );
        _programmaticMove = false;
      }
    } catch (_) {
      _programmaticMove = false;
    }
  }

  Future<void> _applyTerrainSettings() async {
    if (_mapController == null || !_mapReady) return;

  }

  void _centerOnPartner() async {
    if (!_mapReady || _mapController == null) return;
    final partner = ref.read(partnerLocationProvider).valueOrNull;
    if (partner == null) return;
    try {
      _programmaticMove = true;
      await _mapController!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(partner.longitude, partner.latitude)),
          zoom: 16,
        ),
        MapAnimationOptions(duration: 800),
      );
      _programmaticMove = false;
    } catch (_) {
      _programmaticMove = false;
    }
  }

  Color _speedColor(double speed) {
    if (speed < 1) return Colors.white;
    if (speed < 40) return ThemeConstants.successColor;
    if (speed < 80) return ThemeConstants.warningColor;
    return const Color(0xFFFF1744);
  }

  String _headingDir(double heading) {
    final dirs = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                  'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    return dirs[((heading + 11.25) / 22.5).floor() % 16];
  }

  String _headingSourceLabel(double speed, double gpsH, double compassH) {
    if (speed > 5 && gpsH >= 0) return 'GPS';
    if (compassH > 0) return 'Compass';
    if (gpsH >= 0) return 'GPS(static)';
    return '---';
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    final gpsData = ref.watch(gpsDataProvider);
    final compassHeading = ref.watch(compassHeadingProvider);
    final heading = _computeHeading(gpsData, compassHeading);
    final speed = gpsData?.speed ?? 0;
    final gpsH = gpsData?.heading ?? -1;
    final activity = ref.watch(currentActivityProvider).valueOrNull;
    final partner = ref.watch(partnerLocationProvider).valueOrNull;
    final geofences = ref.watch(geofenceListProvider);

    _applyCameraBearing(heading);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MapWidget(
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(_defaultLng, _defaultLat)),
              zoom: _initialZoom,
            ),
            mapOptions: MapOptions(
              pixelRatio: 1.0,
              constrainMode: ConstrainMode.NONE,
              orientation: NorthOrientation.UPWARDS,
            ),
            styleUri: _styleUri,
            onMapCreated: _onMapCreated,
            onCameraChangeListener: _onCameraChanged,
            onScrollListener: _onScroll,
          ),

          if (_mapReady && _userScreenX != null && _userScreenY != null)
            Positioned(
              left: _userScreenX! - 40,
              top: _userScreenY! - 40,
              child: GestureDetector(
                onTap: _toggleFollow,
                child: AnimatedRotation(
                  turns: heading / 360,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: SizedBox(
                    width: 80, height: 80,
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          boxShadow: [
                            BoxShadow(color: ThemeConstants.primaryColor.withAlpha(100), blurRadius: 20, spreadRadius: 4),
                            BoxShadow(color: ThemeConstants.primaryColor.withAlpha(50), blurRadius: 40, spreadRadius: 8),
                          ],
                        ),
                      ),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            ThemeConstants.primaryColor.withAlpha(150),
                            ThemeConstants.primaryColor.withAlpha(0),
                          ]),
                        ),
                      ),
                      Icon(Icons.navigation, color: Colors.white, size: 28,
                        shadows: [Shadow(color: ThemeConstants.primaryColor.withAlpha(200), blurRadius: 8)]),
                    ]),
                  ),
                ),
              ),
            ),

          if (_mapReady && _userScreenX != null && _userScreenY != null)
            Positioned(
              left: _userScreenX! - 40,
              top: _userScreenY! + 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeConstants.primaryColor.withAlpha(75), width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(activity?.activity.icon ?? '📍',
                    style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text('${speed.toStringAsFixed(0)} km/h',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _speedColor(speed))),
                ]),
              ),
            ),

          if (_mapReady && _partnerScreenX != null && _partnerScreenY != null && _showPartner && partner != null)
            Positioned(
              left: _partnerScreenX! - 40,
              top: _partnerScreenY! - 40,
              child: AnimatedBuilder(
                animation: _partnerPulseController!,
                builder: (context, child) {
                  final scale = 1.0 + (_partnerPulseController!.value * 0.15);
                  return Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: 80, height: 80,
                      child: Stack(alignment: Alignment.center, children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFF4081).withAlpha(100), blurRadius: 20, spreadRadius: 4),
                              BoxShadow(color: const Color(0xFFFF4081).withAlpha(50), blurRadius: 40, spreadRadius: 8),
                            ],
                          ),
                        ),
                        Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF4081),
                          ),
                          child: Center(
                            child: Text(
                              partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),

          if (_mapReady && _partnerScreenX != null && _partnerScreenY != null && _showPartner && partner != null)
            Positioned(
              left: _partnerScreenX! - 50,
              top: _partnerScreenY! + 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081).withAlpha(180),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  partner.isMoving ? '● ${partner.speed?.toStringAsFixed(0) ?? "--"} km/h' : '● Stationary',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          if (_showDebug && _mapReady)
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              left: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                borderRadius: 12,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  _dbgRow('Ready', 'YES'),
                  _dbgRow('Zoom', '${_currentZoom.toStringAsFixed(1)}'),
                  _dbgRow('Bearing', '${_currentBearing.toStringAsFixed(0)}°'),
                  _dbgRow('Pitch', '${_currentPitch.toStringAsFixed(0)}°'),
                  _dbgRow('FPS', '${_renderFps.toStringAsFixed(0)}'),
                  _dbgRow('GPS H.', '${gpsH >= 0 ? "${gpsH.toStringAsFixed(0)}°" : "---"}'),
                  _dbgRow('Compass', '${compassHeading.toStringAsFixed(0)}°'),
                  _dbgRow('Active', '${heading.toStringAsFixed(0)}° ${_headingDir(heading)}'),
                  _dbgRow('Source', _headingSourceLabel(speed, gpsH, compassHeading)),
                  _dbgRow('Speed', '${speed.toStringAsFixed(1)} km/h'),
                  _dbgRow('Accuracy', '${(gpsData?.accuracy ?? 0).toStringAsFixed(0)} m'),
                  _dbgRow('Activity', activity?.activity.label ?? '---'),
                  _dbgRow('Partner', partner?.isOnline == true ? 'Online' : 'Offline'),
                  _dbgRow('3D', _show3D ? 'ON' : 'OFF'),
                  _dbgRow('Style', _mapStyle.name),
                  if (_mapError) _dbgRow('Error', _mapErrorMessage),
                ]),
              ),
            ),

          if (_showDebug && !_mapReady)
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              left: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                borderRadius: 12,
                child: _dbgRow('Ready', 'NO'),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _MapStyleChip(label: 'Hybrid', icon: Icons.satellite_alt,
                    active: _mapStyle == MapStyle.satelliteHybrid,
                    onTap: () => _changeStyle(MapStyle.satelliteHybrid)),
                  const SizedBox(width: 6),
                  _MapStyleChip(label: 'Light', icon: Icons.light_mode,
                    active: _mapStyle == MapStyle.streets,
                    onTap: () => _changeStyle(MapStyle.streets)),
                  const SizedBox(width: 6),
                  _MapStyleChip(label: 'Dark', icon: Icons.dark_mode,
                    active: _mapStyle == MapStyle.dark,
                    onTap: () => _changeStyle(MapStyle.dark)),
                  const SizedBox(width: 6),
                  _MapStyleChip(label: 'Outdoor', icon: Icons.terrain,
                    active: _mapStyle == MapStyle.outdoors,
                    onTap: () => _changeStyle(MapStyle.outdoors)),
                  const SizedBox(width: 6),
                  _MapStyleChip(label: 'Custom', icon: Icons.palette,
                    active: _mapStyle == MapStyle.custom,
                    onTap: () => _changeStyle(MapStyle.custom)),
                  const Spacer(),
                ]),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            right: 16,
            child: Column(children: [
              _MapButton(icon: _headingUp ? Icons.north : Icons.explore,
                onPressed: _mapReady ? _toggleHeadingUp : null,
                active: _headingUp, tooltip: _headingUp ? 'North Up' : 'Heading Up'),
              const SizedBox(height: 6),
              _MapButton(icon: Icons.threed_rotation,
                onPressed: _mapReady ? _toggle3D : null,
                active: _show3D, tooltip: '3D View'),
              const SizedBox(height: 6),
              _MapButton(icon: Icons.landscape,
                onPressed: _mapReady ? _toggleTerrain : null,
                active: _showTerrain, tooltip: 'Terrain'),
              const SizedBox(height: 6),
              _MapButton(icon: _showDebug ? Icons.bug_report : Icons.bug_report_outlined,
                onPressed: () => setState(() => _showDebug = !_showDebug),
                active: _showDebug, tooltip: 'Debug'),
            ]),
          ),

          if (_mapReady && partner != null && _showPartner)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 220,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                borderRadius: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: partner.isOnline ? const Color(0xFF00E676) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Partner', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(150), fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  _infoRow('Distance', ref.read(coupleDistanceProvider)),
                  const SizedBox(height: 3),
                  _infoRow('ETA', ref.read(coupleEtaProvider)),
                  const SizedBox(height: 3),
                  _infoRow('Activity', partner.activity ?? '---'),
                  if (partner.batteryLevel != null) ...[
                    const SizedBox(height: 3),
                    _infoRow('Battery', '${partner.batteryLevel!.toStringAsFixed(0)}%'),
                  ],
                ]),
              ),
            ),

          Positioned(
            right: 16,
            bottom: 200,
            child: Column(children: [
              _MapButton(icon: Icons.my_location,
                onPressed: _mapReady ? _recenter : null,
                active: false, tooltip: 'Recenter'),
              const SizedBox(height: 8),
              _MapButton(icon: _followUser ? Icons.navigation : Icons.navigation_outlined,
                onPressed: _mapReady ? _toggleFollow : null,
                active: _followUser, tooltip: 'Follow GPS'),
              const SizedBox(height: 8),
              if (partner != null)
                Column(children: [
                  _MapButton(icon: Icons.favorite,
                    onPressed: _mapReady ? _centerOnPartner : null,
                    active: true, tooltip: 'Partner'),
                  const SizedBox(height: 8),
                ]),
              _MapButton(icon: Icons.add,
                onPressed: _mapReady ? _zoomIn : null,
                tooltip: 'Zoom In'),
              const SizedBox(height: 8),
              _MapButton(icon: Icons.remove,
                onPressed: _mapReady ? _zoomOut : null,
                tooltip: 'Zoom Out'),
            ]),
          ),

          Positioned(
            left: 16, right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: 16,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _InfoTile(label: 'SPEED', value: '${speed.toStringAsFixed(0)}', unit: 'km/h', color: _speedColor(speed)),
                _InfoTile(label: 'ALT', value: '${(gpsData?.altitude ?? 0).toStringAsFixed(0)}', unit: 'm'),
                _InfoTile(label: 'HDG', value: '${heading.toStringAsFixed(0)}°', unit: _headingDir(heading)),
                _InfoTile(label: 'ACC', value: '${(gpsData?.accuracy ?? 0).toStringAsFixed(0)}', unit: 'm',
                  color: (gpsData?.accuracy ?? 99) < 10 ? ThemeConstants.successColor : ThemeConstants.warningColor),
                _InfoTile(label: 'DST', value: ref.read(coupleDistanceProvider), unit: partner != null ? '' : '--'),
              ]),
            ),
          ),

          if (!_mapReady || _mapError)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (!_mapError)
                      SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _mapError ? _mapErrorMessage : 'Loading map...',
                      style: TextStyle(
                        fontSize: 12,
                        color: _mapError ? const Color(0xFFFF1744) : Colors.white.withAlpha(128),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: ', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(128), fontWeight: FontWeight.w500)),
      Text(value, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _dbgRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(100), fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MapStyleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _MapStyleChip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ThemeConstants.primaryColor.withAlpha(50) : Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? ThemeConstants.primaryColor.withAlpha(128) : Colors.white.withAlpha(25),
            width: active ? 1.5 : 0.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? ThemeConstants.primaryColor : Colors.white60),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: active ? ThemeConstants.primaryColor : Colors.white60,
            letterSpacing: 0.5,
          )),
        ]),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final String tooltip;
  const _MapButton({required this.icon, this.onPressed, this.active = false, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: disabled ? Colors.black.withAlpha(50) : Colors.black.withAlpha(128),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? ThemeConstants.primaryColor.withAlpha(128) : Colors.white.withAlpha(disabled ? 12 : 25),
              width: 1,
            ),
          ),
          child: Icon(icon,
            color: disabled ? Colors.white24 : (active ? ThemeConstants.primaryColor : Colors.white70),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;
  const _InfoTile({required this.label, required this.value, required this.unit, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(
        fontSize: 9, fontWeight: FontWeight.w600,
        letterSpacing: 1.2, color: Colors.white.withAlpha(128),
      )),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: c,
        shadows: [Shadow(color: c.withAlpha(75), blurRadius: 4)],
      )),
      Text(unit, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(100))),
    ]);
  }
}
