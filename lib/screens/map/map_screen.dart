import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _followMode = true;
  bool _darkMode = true;
  bool _satelliteMode = false;
  bool _mapReady = false;

  static const LatLng _defaultLocation = LatLng(-6.2088, 106.8456);
  static const double _defaultZoom = 15.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapReady = true;
      _centerOnUser();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnUser() {
    final location = ref.read(currentLocationProvider);
    if (location['lat'] != 0 && location['lng'] != 0) {
      _mapController.move(
        LatLng(location['lat']!, location['lng']!),
        _defaultZoom,
      );
    }
  }

  void _toggleFollowMode() {
    setState(() => _followMode = !_followMode);
    if (_followMode) _centerOnUser();
  }

  void _toggleMapType() {
    setState(() => _satelliteMode = !_satelliteMode);
  }

  void _toggleDarkMode() {
    setState(() => _darkMode = !_darkMode);
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom + 1;
    _mapController.move(_mapController.camera.center, zoom);
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom - 1;
    _mapController.move(_mapController.camera.center, zoom);
  }

  List<Polyline> _buildPolylines() {
    final tracking = ref.read(trackingStateProvider);
    if (!tracking.isTracking || tracking.currentRide == null) return [];

    final points = tracking.currentRide!.trackPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    if (points.isEmpty) return [];

    return [
      Polyline(
        points: points,
        color: ThemeConstants.primaryColor,
        strokeWidth: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    final gpsData = ref.watch(gpsDataProvider);
    final tracking = ref.watch(trackingStateProvider);

    final currentPos = (location['lat'] != 0 && location['lng'] != 0)
        ? LatLng(location['lat']!, location['lng']!)
        : _defaultLocation;

    final tileUrl = _satelliteMode
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : _darkMode
            ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MAP', style: TextStyle(letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _satelliteMode ? Icons.map : Icons.satellite,
              color: Colors.white70,
            ),
            tooltip: 'Toggle Satellite',
            onPressed: _toggleMapType,
          ),
          if (!_satelliteMode)
            IconButton(
              icon: Icon(
                _darkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white70,
              ),
              tooltip: 'Toggle Dark Mode',
              onPressed: _toggleDarkMode,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: _defaultZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: (event) {
                if (event is MapEventMoveEnd && _followMode) {
                  setState(() => _followMode = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.vortex.app',
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('Tile error: $tile - $error');
                },
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPos,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThemeConstants.primaryColor,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConstants.primaryColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            right: 16,
            bottom: 260,
            child: Column(
              children: [
                _GlassIconButton(
                  icon: _followMode ? Icons.my_location : Icons.location_disabled,
                  onPressed: _toggleFollowMode,
                  active: _followMode,
                ),
                const SizedBox(height: 8),
                _GlassIconButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: 8),
                _GlassIconButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricTile(
                    label: 'SPEED',
                    value: (gpsData?.speed ?? 0).toStringAsFixed(1),
                    unit: 'km/h',
                  ),
                  _MetricTile(
                    label: 'ALT',
                    value: (gpsData?.altitude ?? 0).toStringAsFixed(0),
                    unit: 'm',
                  ),
                  _MetricTile(
                    label: 'HEADING',
                    value: (gpsData?.heading ?? 0).toStringAsFixed(0),
                    unit: '\u00B0',
                  ),
                  _MetricTile(
                    label: 'ACCURACY',
                    value: (gpsData?.accuracy ?? 0).toStringAsFixed(1),
                    unit: 'm',
                  ),
                ],
              ),
            ),
          ),

          if (tracking.isTracking)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              left: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TRACKING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: active ? ThemeConstants.primaryColor : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
