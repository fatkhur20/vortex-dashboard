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
  MapMode _mapMode = MapMode.hybrid;
  bool _animating = false;

  static const double _initialZoom = 17.0;
  static const double _minZoom = 5.0;
  static const double _maxZoom = 20.0;

  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456);

  Timer? _followTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnUser(animated: false);
    });
  }

  @override
  void dispose() {
    _followTimer?.cancel();
    _mapController.dispose();
    super.dispose();
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
    if (event is MapEventMoveEnd && _followUser && !_animating) {
      setState(() => _followUser = false);
    }
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

  double _computeHeading(GpsData? gpsData, double compassHeading) {
    final speed = gpsData?.speed ?? 0;
    if (speed > 5) {
      return gpsData?.heading ?? compassHeading;
    }
    return compassHeading;
  }

  double? _lastRotation;

  void _applyRotation(double heading) {
    final target = _headingUp ? heading * 3.1415927 / 180 : 0;
    if (_lastRotation == target) return;
    _lastRotation = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController.camera.rotation != target) {
        _mapController.rotate(target);
      }
    });
  }

  void _toggleFollow() {
    setState(() => _followUser = true);
    _centerOnUser();
  }

  void _toggleHeadingUp() {
    setState(() => _headingUp = !_headingUp);
  }

  void _cycleMapMode() {
    setState(() {
      _mapMode = MapMode.values[(_mapMode.index + 1) % MapMode.values.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    final gpsData = ref.watch(gpsDataProvider);
    final compassHeading = ref.watch(compassHeadingProvider);
    final heading = _computeHeading(gpsData, compassHeading);

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
                              Transform.rotate(
                                angle: 3.1415927,
                                child: Icon(
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

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _MapModeChip(
                    mode: _mapMode,
                    label: 'Hybrid',
                    icon: Icons.satellite_alt,
                    active: _mapMode == MapMode.hybrid,
                    onTap: () => setState(() => _mapMode = MapMode.hybrid),
                  ),
                  const SizedBox(width: 6),
                  _MapModeChip(
                    mode: _mapMode,
                    label: 'Light',
                    icon: Icons.light_mode,
                    active: _mapMode == MapMode.light,
                    onTap: () => setState(() => _mapMode = MapMode.light),
                  ),
                  const SizedBox(width: 6),
                  _MapModeChip(
                    mode: _mapMode,
                    label: 'Dark',
                    icon: Icons.dark_mode,
                    active: _mapMode == MapMode.dark,
                    onTap: () => setState(() => _mapMode = MapMode.dark),
                  ),
                  const Spacer(),
                  _MapButton(
                    icon: _headingUp ? Icons.north : Icons.explore,
                    onPressed: _toggleHeadingUp,
                    active: _headingUp,
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
                _MapButton(
                  icon: _followUser ? Icons.my_location : Icons.location_disabled,
                  onPressed: _toggleFollow,
                  active: _followUser,
                  tooltip: 'Follow GPS',
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.add,
                  onPressed: () {
                    final z = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, z.clamp(_minZoom, _maxZoom));
                  },
                  tooltip: 'Zoom In',
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final z = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, z.clamp(_minZoom, _maxZoom));
                  },
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
                    value: '${(gpsData?.speed ?? 0).toStringAsFixed(0)}',
                    unit: 'km/h',
                    color: _speedColor(gpsData?.speed ?? 0),
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
        ],
      ),
    );
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
}

class _MapModeChip extends StatelessWidget {
  final MapMode mode;
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _MapModeChip({
    required this.mode,
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
  final VoidCallback onPressed;
  final bool active;
  final String tooltip;

  const _MapButton({
    required this.icon,
    required this.onPressed,
    this.active = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? ThemeConstants.primaryColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: active ? ThemeConstants.primaryColor : Colors.white70,
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
