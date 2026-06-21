import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

enum MapMode { hybrid, light, dark }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _followUser = true;
  bool _headingUp = false;
  MapMode _mapMode = MapMode.hybrid;
  bool _showDebug = true;

  static const double _initialZoom = 17.0;
  static const double _minZoom = 5.0;
  static const double _maxZoom = 19.0;
  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456);

  double? _lastRotation;
  double _effectiveHeading = 0;
  double _gpsHeading = 0;
  double _compassHeading = 0;
  String _headingSource = '--';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnUser(animated: false));
  }

  void _centerOnUser({bool animated = true}) {
    final loc = ref.read(currentLocationProvider);
    if (loc['lat'] == 0 && loc['lng'] == 0) return;
    final pos = LatLng(loc['lat']!, loc['lng']!);
    if (animated) {
      _mapController.move(pos, _mapController.camera.zoom);
    } else {
      _mapController.move(pos, _initialZoom);
    }
  }

  void _onMapEvent(MapEvent event) {
    if (_followUser && event is MapEventMoveEnd) {
      setState(() => _followUser = false);
    }
  }

  void _computeHeading(GpsData? gpsData, double compassH) {
    _compassHeading = compassH;
    _gpsHeading = gpsData?.heading ?? 0;
    final speed = gpsData?.speed ?? 0;

    double heading;
    if (speed > 5 && _gpsHeading > 0) {
      heading = _gpsHeading;
      _headingSource = 'GPS';
    } else if (_compassHeading > 0) {
      heading = _compassHeading;
      _headingSource = speed > 5 ? 'GPS(0)→Comp' : 'Compass';
    } else {
      heading = _gpsHeading > 0 ? _gpsHeading : 0;
      _headingSource = 'Fallback';
    }

    _effectiveHeading = heading;
  }

  void _applyRotation() {
    if (_lastRotation == _effectiveHeading) return;
    _lastRotation = _effectiveHeading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _headingUp ? _effectiveHeading * math.pi / 180.0 : 0.0;
      if ((_mapController.camera.rotation - target).abs() > 0.01) {
        _mapController.rotate(target);
      }
    });
  }

  double _clampZoom(double zoom) => zoom.clamp(_minZoom, _maxZoom);

  void _zoomIn() {
    final z = _clampZoom(_mapController.camera.zoom + 1);
    _mapController.move(_mapController.camera.center, z);
    setState(() {});
  }

  void _zoomOut() {
    final z = _clampZoom(_mapController.camera.zoom - 1);
    _mapController.move(_mapController.camera.center, z);
    setState(() {});
  }

  void _toggleFollow() {
    setState(() => _followUser = true);
    _centerOnUser();
  }

  void _toggleHeadingUp() {
    setState(() {
      _headingUp = !_headingUp;
      _lastRotation = null;
    });
  }

  String get _tileUrl {
    switch (_mapMode) {
      case MapMode.hybrid:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapMode.light:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapMode.dark:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
    }
  }

  String get _overlayUrl {
    if (_mapMode != MapMode.hybrid) return '';
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  String _headingDir(double h) {
    final d = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
               'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    return d[((h + 11.25) / 22.5).floor() % 16];
  }

  Color _speedColor(double s) {
    if (s < 1) return Colors.white;
    if (s < 40) return ThemeConstants.successColor;
    if (s < 80) return ThemeConstants.warningColor;
    return const Color(0xFFFF1744);
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    final gpsData = ref.watch(gpsDataProvider);
    final compassH = ref.watch(compassHeadingProvider);
    final zoom = _mapController.camera.zoom;

    _computeHeading(gpsData, compassH);
    _applyRotation();

    final hasGps = location['lat'] != 0 && location['lng'] != 0;
    final currentPos = hasGps ? LatLng(location['lat']!, location['lng']!) : _defaultCenter;
    final h = _effectiveHeading;

    if (_followUser && hasGps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentPos, zoom);
      });
    }

    final atMaxZoom = zoom >= _maxZoom - 0.1;
    final atMinZoom = zoom <= _minZoom + 0.1;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: _initialZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: 'com.vortex.app',
                errorTileCallback: (tile, error, _) {
                  debugPrint('Tile error: $tile - $error');
                },
              ),
              if (_mapMode == MapMode.hybrid)
                Opacity(
                  opacity: 0.35,
                  child: ClipRect(
                    child: TileLayer(
                      urlTemplate: _overlayUrl,
                      userAgentPackageName: 'com.vortex.app',
                    ),
                  ),
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPos,
                    width: 80,
                    height: 80,
                    child: AnimatedRotation(
                      turns: h / 360,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: ThemeConstants.primaryColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4),
                                  BoxShadow(color: ThemeConstants.primaryColor.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 8),
                                ],
                              ),
                            ),
                            Transform.rotate(
                              angle: math.pi,
                              child: Icon(Icons.navigation, color: Colors.white, size: 28,
                                shadows: [Shadow(color: ThemeConstants.primaryColor.withValues(alpha: 0.8), blurRadius: 8)]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...MapMode.values.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _ModeChip(
                      label: m.name.toUpperCase(),
                      icon: m == MapMode.hybrid ? Icons.satellite_alt : m == MapMode.light ? Icons.light_mode : Icons.dark_mode,
                      active: _mapMode == m,
                      onTap: () => setState(() => _mapMode = m),
                    ),
                  )),
                  const Spacer(),
                  _MapBtn(
                    icon: _headingUp ? Icons.north : Icons.explore,
                    active: _headingUp,
                    onPressed: _toggleHeadingUp,
                    tooltip: _headingUp ? 'North Up' : 'Heading Up',
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
                _MapBtn(
                  icon: _followUser ? Icons.my_location : Icons.location_disabled,
                  active: _followUser,
                  onPressed: _toggleFollow,
                  tooltip: 'Follow GPS',
                ),
                const SizedBox(height: 8),
                _MapBtn(
                  icon: Icons.add,
                  onPressed: atMaxZoom ? null : _zoomIn,
                  tooltip: 'Zoom In',
                  disabled: atMaxZoom,
                ),
                const SizedBox(height: 8),
                _MapBtn(
                  icon: Icons.remove,
                  onPressed: atMinZoom ? null : _zoomOut,
                  tooltip: 'Zoom Out',
                  disabled: atMinZoom,
                ),
                const SizedBox(height: 8),
                _MapBtn(
                  icon: Icons.bug_report,
                  active: _showDebug,
                  onPressed: () => setState(() => _showDebug = !_showDebug),
                  tooltip: 'Debug',
                ),
              ],
            ),
          ),

          if (_showDebug)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              left: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                borderRadius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dbg('Zoom', zoom.toStringAsFixed(1)),
                    _dbg('GPS Heading', '${_gpsHeading.toStringAsFixed(0)}°'),
                    _dbg('Compass', '${_compassHeading.toStringAsFixed(0)}°'),
                    _dbg('Active H.', '${h.toStringAsFixed(0)}° ${_headingDir(h)}'),
                    _dbg('Source', _headingSource),
                    _dbg('Speed', '${(gpsData?.speed ?? 0).toStringAsFixed(1)} km/h'),
                    _dbg('Accuracy', '${(gpsData?.accuracy ?? 0).toStringAsFixed(0)} m'),
                    _dbg('Rotate', _headingUp ? 'Heading Up' : 'North Up'),
                  ],
                ),
              ),
            ),

          Positioned(
            left: 16, right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoTile(label: 'SPEED', value: '${(gpsData?.speed ?? 0).toStringAsFixed(0)}', unit: 'km/h', color: _speedColor(gpsData?.speed ?? 0)),
                  _InfoTile(label: 'ALT', value: '${(gpsData?.altitude ?? 0).toStringAsFixed(0)}', unit: 'm'),
                  _InfoTile(label: 'HEADING', value: '${h.toStringAsFixed(0)}°', unit: _headingDir(h)),
                  _InfoTile(label: 'ACC', value: '${(gpsData?.accuracy ?? 0).toStringAsFixed(0)}', unit: 'm', color: (gpsData?.accuracy ?? 99) < 10 ? ThemeConstants.successColor : ThemeConstants.warningColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dbg(String label, String value) {
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

class _ModeChip extends StatelessWidget {
  final String label; final IconData icon; final bool active; final VoidCallback onTap;
  const _ModeChip({required this.label, required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ThemeConstants.primaryColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? ThemeConstants.primaryColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1), width: active ? 1.5 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? ThemeConstants.primaryColor : Colors.white60),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? ThemeConstants.primaryColor : Colors.white60, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon; final VoidCallback? onPressed; final bool active; final String tooltip; final bool disabled;
  const _MapBtn({required this.icon, this.onPressed, this.active = false, required this.tooltip, this.disabled = false});
  @override
  Widget build(BuildContext context) {
    final c = disabled ? Colors.white24 : (active ? ThemeConstants.primaryColor : Colors.white70);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? ThemeConstants.primaryColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: Icon(icon, color: c, size: 20),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value, unit; final Color? color;
  const _InfoTile({required this.label, required this.value, required this.unit, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.5))),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c, shadows: [Shadow(color: c.withValues(alpha: 0.3), blurRadius: 4)])),
      Text(unit, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
    ]);
  }
}
