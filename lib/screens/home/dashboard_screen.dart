import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/models/partner_location.dart';
import 'package:vortex_dashboard/providers/compass_provider.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/partner_provider.dart';
import 'package:vortex_dashboard/providers/activity_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/screens/map/map_screen.dart';
import 'package:vortex_dashboard/screens/settings/settings_screen.dart';
import 'package:vortex_dashboard/screens/history/history_screen.dart';

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
    if (!mounted) return;
    setState(() => _timeString = DateFormat('HH:mm').format(DateTime.now()));
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  void _onNavTapped(int index) {
    setState(() => _bottomNavIndex = index);
    switch (index) {
      case 0: break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()))
            .then((_) => mounted ? setState(() => _bottomNavIndex = 0) : null);
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))
            .then((_) => mounted ? setState(() => _bottomNavIndex = 0) : null);
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
            .then((_) => mounted ? setState(() => _bottomNavIndex = 0) : null);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gpsData = ref.watch(gpsDataProvider);
    final speed = gpsData?.speed ?? 0;
    final accuracy = gpsData?.accuracy ?? 0;
    final heading = ref.watch(compassHeadingProvider);
    final activity = ref.watch(currentActivityProvider).valueOrNull;
    final partner = ref.watch(partnerLocationProvider).valueOrNull;
    final isMoving = ref.watch(isMovingProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeConstants.amoledBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      ThemeConstants.primaryColor.withAlpha(15),
                      ThemeConstants.primaryColor.withAlpha(5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  _buildUserProfile(speed, accuracy, partner, activity),
                  const SizedBox(height: 24),
                  _buildPartnerCard(partner),
                  const SizedBox(height: 20),
                  _buildQuickStats(speed, accuracy, partner),
                  const SizedBox(height: 20),
                  _buildActivityCard(activity),
                  const SizedBox(height: 20),
                  _buildSosButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.radar, color: ThemeConstants.primaryColor.withAlpha(150), size: 20),
          const SizedBox(width: 8),
          Text('LIFE TRACKER', style: TextStyle(
            color: ThemeConstants.primaryColor.withAlpha(150),
            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 3,
          )),
          const Spacer(),
          Text(_timeString, style: TextStyle(
            color: Colors.white.withAlpha(180), fontSize: 16, fontWeight: FontWeight.w300, letterSpacing: 2,
          )),
          const SizedBox(width: 12),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.battery_std, color: ThemeConstants.successColor.withAlpha(200), size: 16),
            const SizedBox(width: 4),
            Text('85%', style: TextStyle(
              color: ThemeConstants.successColor.withAlpha(200), fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildUserProfile(double speed, double accuracy, PartnerLocation? partner, dynamic activity) {
    final activityLabel = activity?.activityLabel ?? 'Unknown';
    final activityIcon = activity?.activityIcon ?? '\u{1F4CD}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: ThemeConstants.primaryColor.withAlpha(80), blurRadius: 16, spreadRadius: 2),
                ],
              ),
              child: const Center(
                child: Text('Y', style: TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                )),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThemeConstants.successColor,
                        boxShadow: [BoxShadow(color: ThemeConstants.successColor.withAlpha(120), blurRadius: 4)],
                      )),
                    const SizedBox(width: 6),
                    Text('Online', style: TextStyle(
                      color: ThemeConstants.successColor, fontSize: 12, fontWeight: FontWeight.w500,
                    )),
                    const SizedBox(width: 12),
                    Text('$activityIcon $activityLabel', style: TextStyle(
                      color: Colors.white.withAlpha(180), fontSize: 12,
                    )),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.speed, size: 13, color: Colors.white.withAlpha(100)),
                    const SizedBox(width: 4),
                    Text('${speed.toStringAsFixed(0)} km/h', style: TextStyle(
                      fontSize: 12, color: Colors.white.withAlpha(150), fontWeight: FontWeight.w500,
                    )),
                    const SizedBox(width: 16),
                    Icon(Icons.my_location, size: 13, color: Colors.white.withAlpha(100)),
                    const SizedBox(width: 4),
                    Text('\u00B1${accuracy.toStringAsFixed(0)}m', style: TextStyle(
                      fontSize: 12, color: accuracy < 10 ? ThemeConstants.successColor.withAlpha(200) : Colors.white.withAlpha(150),
                    )),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(PartnerLocation? partner) {
    if (partner == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Row(children: [
            Container(width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(25),
                border: Border.all(color: Colors.white.withAlpha(25)),
              ),
              child: Icon(Icons.person_add_alt, color: Colors.white.withAlpha(80), size: 24)),
            const SizedBox(width: 16),
            Text('No partner connected', style: TextStyle(
              color: Colors.white.withAlpha(100), fontSize: 14,
            )),
          ]),
        ),
      );
    }

    final distance = ref.read(coupleDistanceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFF4081).withAlpha(80), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partner.name, style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                      )),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: partner.isOnline ? ThemeConstants.successColor : Colors.grey,
                            boxShadow: partner.isOnline
                                ? [BoxShadow(color: ThemeConstants.successColor.withAlpha(120), blurRadius: 4)]
                                : null,
                          )),
                        const SizedBox(width: 6),
                        Text(partner.isOnline ? 'Online' : 'Offline', style: TextStyle(
                          color: partner.isOnline ? ThemeConstants.successColor : Colors.grey,
                          fontSize: 12, fontWeight: FontWeight.w500,
                        )),
                        const SizedBox(width: 12),
                        if (partner.lastSeen != null) ...[
                          Text(partner.lastSeenAgo, style: TextStyle(
                            color: Colors.white.withAlpha(100), fontSize: 11,
                          )),
                        ],
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.speed, size: 13, color: Colors.white.withAlpha(100)),
                        const SizedBox(width: 4),
                        Text('${partner.speed?.toStringAsFixed(0) ?? "--"} km/h', style: TextStyle(
                          fontSize: 12, color: Colors.white.withAlpha(150),
                        )),
                        const SizedBox(width: 16),
                        Icon(Icons.battery_std, size: 13, color: Colors.white.withAlpha(100)),
                        const SizedBox(width: 4),
                        Text('${partner.batteryLevel?.toStringAsFixed(0) ?? "--"}%', style: TextStyle(
                          fontSize: 12, color: Colors.white.withAlpha(150),
                        )),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(Icons.map, size: 14, color: ThemeConstants.primaryColor.withAlpha(180)),
                const SizedBox(width: 8),
                Text('Distance: $distance', style: TextStyle(
                  color: ThemeConstants.primaryColor, fontSize: 13, fontWeight: FontWeight.w600,
                )),
                const Spacer(),
                Icon(Icons.chevron_right, size: 18, color: ThemeConstants.primaryColor.withAlpha(180)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(double speed, double accuracy, PartnerLocation? partner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(children: [
              Icon(Icons.my_location, size: 18, color: accuracy < 10
                  ? ThemeConstants.successColor : ThemeConstants.warningColor),
              const SizedBox(height: 6),
              Text('GPS', style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${accuracy.toStringAsFixed(0)}m', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: accuracy < 10 ? ThemeConstants.successColor : Colors.white,
              )),
            ]),
          )),
          const SizedBox(width: 8),
          Expanded(child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(children: [
              Icon(Icons.people, size: 18, color: ThemeConstants.primaryColor.withAlpha(200)),
              const SizedBox(height: 6),
              Text('MEMBERS', style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('2', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
              )),
            ]),
          )),
          const SizedBox(width: 8),
          Expanded(child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(children: [
              Icon(Icons.route, size: 18, color: ThemeConstants.neonPurple.withAlpha(200)),
              const SizedBox(height: 6),
              Text('TODAY', style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${speed > 0 ? "12km" : "0km"}', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
              )),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    final icon = activity?.activityIcon ?? '\u{1F4CD}';
    final label = activity?.activityLabel ?? 'Stationary';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ThemeConstants.primaryColor.withAlpha(30),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activity', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeConstants.successColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: ThemeConstants.successColor)),
              const SizedBox(width: 4),
              Text('Active', style: TextStyle(fontSize: 10, color: ThemeConstants.successColor, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSosButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          showDialog(context: context, builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('SOS Emergency', style: TextStyle(color: Color(0xFFFF1744), fontWeight: FontWeight.bold)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Share your location with emergency contacts?', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  _sosRow('Location', 'Active'),
                  _sosRow('Battery', '85%'),
                  _sosRow('Timestamp', DateFormat('HH:mm:ss').format(DateTime.now())),
                ]),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(backgroundColor: const Color(0xFFFF1744).withAlpha(50)),
                child: const Text('SEND SOS', style: TextStyle(color: Color(0xFFFF1744), fontWeight: FontWeight.bold)),
              ),
            ],
          ));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF1744), Color(0xFFD50000)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF1744).withAlpha(60), blurRadius: 20, spreadRadius: 4),
            ],
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('SOS EMERGENCY', style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _sosRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$label: ', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(12), width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onNavTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: ThemeConstants.primaryColor,
        unselectedItemColor: Colors.white.withAlpha(75),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(letterSpacing: 0.5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'People'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
