import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/dashboard_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/settings_provider.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/widgets/common/section_title.dart';
import 'package:vortex_dashboard/widgets/common/stat_tile.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/widgets/speedometer/speedometer_widget.dart';
import 'package:vortex_dashboard/screens/map/map_screen.dart';
import 'package:vortex_dashboard/screens/tracking/tracking_screen.dart';
import 'package:vortex_dashboard/screens/performance/performance_screen.dart';
import 'package:vortex_dashboard/screens/settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _bottomNavIndex = 0;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    setState(() {
      _timeString = DateFormat('HH:mm').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  void _onNavTapped(int index) {
    setState(() => _bottomNavIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        ).then((_) => setState(() => _bottomNavIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrackingScreen()),
        ).then((_) => setState(() => _bottomNavIndex = 0));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PerformanceScreen()),
        ).then((_) => setState(() => _bottomNavIndex = 0));
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ).then((_) => setState(() => _bottomNavIndex = 0));
        break;
    }
  }

  String _formatHeading(double heading) {
    final directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((heading + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    final gpsData = ref.watch(gpsDataProvider);
    final heading = ref.watch(compassHeadingProvider);
    final useKmh = ref.watch(useKmhProvider);
    final trackingState = ref.watch(trackingStateProvider);
    final dashboardData = ref.watch(dashboardDataProvider);
    final speed = gpsData.speed;
    final speedColor = speed.speedColor;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeConstants.amoledBackground,
      body: Stack(
        children: [
          _buildBackgroundGlow(speedColor),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  _buildSpeedometer(speed, useKmh, speedColor),
                  const SizedBox(height: 16),
                  _buildQuickStats(speed, gpsData.altitude, heading, gpsData.accuracy, useKmh),
                  const SizedBox(height: 16),
                  _buildTripSection(trackingState.totalDistance, dashboardData.tripADistance),
                  const SizedBox(height: 12),
                  _buildBottomInfo(gpsData.latitude, gpsData.longitude),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _buildCompassIndicator(heading),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBackgroundGlow(Color color) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.2,
              colors: [
                color.withOpacity(0.06),
                color.withOpacity(0.02),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            Icons.speed,
            color: ThemeConstants.primaryColor.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'VORTEX',
            style: TextStyle(
              color: ThemeConstants.primaryColor.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            _timeString,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 16),
          _buildBatteryIndicator(),
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.battery_std,
          color: ThemeConstants.successColor.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          '85%',
          style: TextStyle(
            color: ThemeConstants.successColor.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedometer(double speed, bool useKmh, Color speedColor) {
    return Center(
      child: SpeedometerWidget(
        speed: speed,
        useKmh: useKmh,
        size: 280,
      ),
    );
  }

  Widget _buildQuickStats(double speed, double altitude, double heading, double accuracy, bool useKmh) {
    final unit = useKmh ? 'km/h' : 'mph';
    final displaySpeed = useKmh
        ? speed.toStringAsFixed(0)
        : (speed * 0.621371).toStringAsFixed(0);
    final headingDir = _formatHeading(heading);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SectionTitle(
            title: 'Quick Stats',
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GlassCard.neon(
                  padding: const EdgeInsets.all(12),
                  child: StatTile(
                    label: 'SPEED',
                    value: '$displaySpeed $unit',
                    icon: Icons.speed,
                    valueColor: speed.speedColor,
                    showGlow: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassCard.neon(
                  padding: const EdgeInsets.all(12),
                  child: StatTile(
                    label: 'ALTITUDE',
                    value: '${altitude.toStringAsFixed(0)} m',
                    icon: Icons.terrain,
                    valueColor: ThemeConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GlassCard.neon(
                  padding: const EdgeInsets.all(12),
                  child: StatTile(
                    label: 'HEADING',
                    value: '${heading.toStringAsFixed(0)}° $headingDir',
                    icon: Icons.navigation,
                    valueColor: ThemeConstants.neonPurple,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassCard.neon(
                  padding: const EdgeInsets.all(12),
                  child: StatTile(
                    label: 'GPS ACCURACY',
                    value: '${accuracy.toStringAsFixed(0)} m',
                    icon: Icons.my_location,
                    valueColor: accuracy < 10
                        ? ThemeConstants.successColor
                        : ThemeConstants.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripSection(double trackingDistance, double tripADistance) {
    final distance = trackingDistance > 0 ? trackingDistance : tripADistance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SectionTitle(
            title: 'Trip A',
            icon: Icons.route_rounded,
          ),
          const SizedBox(height: 8),
          GlassCard.neon(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ThemeConstants.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.route,
                    color: ThemeConstants.primaryColor.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISTANCE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${distance.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ThemeConstants.primaryColor.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TRIP',
                        style: TextStyle(
                          color: ThemeConstants.primaryColor.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo(double lat, double lng) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
        opacity: 0.08,
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: ThemeConstants.primaryColor.withOpacity(0.6),
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeConstants.successColor.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: ThemeConstants.successColor.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassIndicator(double heading) {
    return GestureDetector(
      onTap: () => _onNavTapped(1),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: ThemeConstants.neonBlue.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ThemeConstants.neonBlue.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Transform.rotate(
          angle: heading * 3.1415927 / 180,
          child: Icon(
            Icons.navigation,
            color: ThemeConstants.neonBlue.withOpacity(0.8),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onNavTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: ThemeConstants.primaryColor,
        unselectedItemColor: Colors.white.withOpacity(0.3),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(letterSpacing: 0.5),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Performance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

extension on double {
  Color get speedColor {
    if (this < 60) return ThemeConstants.speedLow;
    if (this < 100) return ThemeConstants.speedMedium;
    if (this < 140) return ThemeConstants.speedHigh;
    return ThemeConstants.speedCritical;
  }
}
