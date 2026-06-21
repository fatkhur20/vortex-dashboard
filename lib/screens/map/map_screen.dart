import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

enum MapMode { hybrid, light, dark }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _followUser = true;
  bool _headingUp = false;
  MapMode _mapMode = MapMode.light;
  bool _showDebug = true;
  bool _mapReady = false;

  static const double _initialZoom = 17.0;
  static const double _minZoom = 5.0;
  static const double _maxZoom = 19.0;
  static const double _hybridMaxZoom = 18.0;

  double get _effectiveMaxZoom => _mapMode == MapMode.hybrid ? _hybridMaxZoom : _maxZoom;

  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapReady() {
    setState(() => _mapReady = true);
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd && _followUser) {
      setState(() => _followUser = false);
    }
  }

  double _computeHeading(GpsData? gpsData, double compassHeading) {
    final speed = gpsData?.speed ?? 0;
    final gpsH = gpsData?.heading ?? -1;
    if (speed > 5 && gpsH >= 0) {
      return gpsH;
    }
    if (compassHeading > 0) {
      return compassHeading;
    }
    if (gpsH >= 0) {
      return gpsH;
    }
    return 0;
  }

  double? _lastRotation;

  void _applyRotation(double heading) {
    if (!_mapReady) return;
    const double _deg2rad = 3.141592653589793 / 180.0;
    final target = _headingUp ? heading * _deg2rad : 0.0;
    if (_lastRotation == target) return;
    _lastRotation = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mapReady) return;
      if (_mapController.camera.rotation != target) {
        _mapController.rotate(target);
      }
    });
  }

  void _toggleFollow() {
    if (!_mapReady) return;
    setState(() => _followUser = true);
    _followToUser();
  }

  void _followToUser() {
    if (!_mapReady) return;
    final loc = ref.read(currentLocationProvider);
    if (loc['lat'] == 0 && loc['lng'] == 0) return;
    final pos = LatLng(loc['lat']!, loc['lng']!);
    _mapController.move(pos, _mapController.camera.zoom);
  }

  void _toggleHeadingUp() {
    setState(() {
      _headingUp = !_headingUp;
      _lastRotation = null;
    });
  }

  void _zoomIn() {
    if (!_mapReady) return;
    final z = (_mapController.camera.zoom + 1).clamp(_minZoom, _effectiveMaxZoom);
    _mapController.move(_mapController.camera.center, z);
  }

  void _zoomOut() {
    if (!_mapReady) return;
    final z = (_mapController.camera.zoom - 1).clamp(_minZoom, _effectiveMaxZoom);
    _mapController.move(_mapController.camera.center, z);
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

    final currentPos = (location['lat'] != 0 && location['lng'] != 0)
        ? LatLng(location['lat']!, location['lng']!)
        : _defaultCenter;

    _applyRotation(heading);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _initialZoom,
              minZoom: _minZoom,
              maxZoom: _effectiveMaxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: _onMapEvent,
              onMapReady: _onMapReady,
            ),
            children: [
              TileLayer(
                urlTemplate: _mapMode == MapMode.hybrid
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : _mapMode == MapMode.dark
                        ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vortex.app',
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('Map tile error: $tile - $error');
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPos,
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: _toggleFollow,
                      child: AnimatedRotation(
                        turns: heading / 360,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: ThemeConstants.primaryColor.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: ThemeConstants.primaryColor.withValues(alpha: 0.2),
                                      blurRadius: 40,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      ThemeConstants.primaryColor.withValues(alpha: 0.6),
                                      ThemeConstants.primaryColor.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 28,
                                shadows: [
                                  Shadow(
                                    color: ThemeConstants.primaryColor.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_showDebug)
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              left: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                borderRadius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dbgRow('Ready', _mapReady ? 'YES' : 'NO'),
                    _dbgRow('Zoom', _mapReady ? '${(_mapController.camera.zoom).toStringAsFixed(1)}' : '---'),
                    _dbgRow('GPS H.', '${gpsH >= 0 ? "${gpsH.toStringAsFixed(0)}°" : "---"}'),
                    _dbgRow('Compass', '${compassHeading.toStringAsFixed(0)}°'),
                    _dbgRow('Active', '${heading.toStringAsFixed(0)}° ${_headingDir(heading)}'),
                    _dbgRow('Source', _headingSourceLabel(speed, gpsH, compassHeading)),
                    _dbgRow('Speed', '${speed.toStringAsFixed(1)} km/h'),
                    _dbgRow('Accuracy', '${(gpsData?.accuracy ?? 0).toStringAsFixed(0)} m'),
                    _dbgRow('Rotate', _headingUp ? 'Heading Up' : 'North Up'),
                    _dbgRow('Mode', _mapMode.name.toUpperCase()),
                  ],
                ),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _MapModeChip(
                    label: 'Hybrid',
                    icon: Icons.satellite_alt,
                    active: _mapMode == MapMode.hybrid,
                    onTap: () => setState(() => _mapMode = MapMode.hybrid),
                  ),
                  const SizedBox(width: 6),
                  _MapModeChip(
                    label: 'Light',
                    icon: Icons.light_mode,
                    active: _mapMode == MapMode.light,
                    onTap: () => setState(() => _mapMode = MapMode.light),
                  ),
                  const SizedBox(width: 6),
                  _MapModeChip(
                    label: 'Dark',
                    icon: Icons.dark_mode,
                    active: _mapMode == MapMode.dark,
                    onTap: () => setState(() => _mapMode = MapMode.dark),
                  ),
                  const Spacer(),
                  _MapButton(
                    icon: _headingUp ? Icons.north : Icons.explore,
                    onPressed: _mapReady ? _toggleHeadingUp : null,
                    active: _headingUp,
                    tooltip: _headingUp ? 'North Up' : 'Heading Up',
                  ),
                  const SizedBox(width: 6),
                  _MapButton(
                    icon: _showDebug ? Icons.bug_report : Icons.bug_report_outlined,
                    onPressed: () => setState(() => _showDebug = !_showDebug),
                    active: _showDebug,
                    tooltip: 'Debug',
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                _MapButton(
                  icon: _followUser ? Icons.my_location : Icons.location_disabled,
                  onPressed: _mapReady ? _toggleFollow : null,
                  active: _followUser,
                  tooltip: 'Follow GPS',
                ),
                const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.add,
                    onPressed: _mapReady ? _zoomIn : null,
                    tooltip: 'Zoom In',
                  ),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.remove,
                    onPressed: _mapReady ? _zoomOut : null,
                  tooltip: 'Zoom In',
                ),
                const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.remove,
                    onPressed: _mapReady ? _zoomOut : null,
                  tooltip: 'Zoom Out',
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoTile(
                    label: 'SPEED',
                    value: '${speed.toStringAsFixed(0)}',
                    unit: 'km/h',
                    color: _speedColor(speed),
                  ),
                  _InfoTile(
                    label: 'ALT',
                    value: '${(gpsData?.altitude ?? 0).toStringAsFixed(0)}',
                    unit: 'm',
                  ),
                  _InfoTile(
                    label: 'HEADING',
                    value: '${heading.toStringAsFixed(0)}°',
                    unit: _headingDir(heading),
                  ),
                  _InfoTile(
                    label: 'ACCURACY',
                    value: '${(gpsData?.accuracy ?? 0).toStringAsFixed(0)}',
                    unit: 'm',
                    color: (gpsData?.accuracy ?? 99) < 10
                        ? ThemeConstants.successColor
                        : ThemeConstants.warningColor,
                  ),
                ],
              ),
            ),
          ),

          if (!_mapReady)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading map...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dbgRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MapModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _MapModeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? ThemeConstants.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? ThemeConstants.primaryColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: active ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? ThemeConstants.primaryColor : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? ThemeConstants.primaryColor : Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final String tooltip;

  const _MapButton({
    required this.icon,
    this.onPressed,
    this.active = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: disabled ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? ThemeConstants.primaryColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: disabled ? 0.05 : 0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
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

  const _InfoTile({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c,
            shadows: [
              Shadow(color: c.withValues(alpha: 0.3), blurRadius: 4),
            ],
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
