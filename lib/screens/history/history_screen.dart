import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gpsData = ref.watch(gpsDataProvider);
    final speed = gpsData?.speed ?? 0;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Location History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ThemeConstants.primaryColor,
          labelColor: ThemeConstants.primaryColor,
          unselectedLabelColor: Colors.white.withAlpha(100),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Yesterday'),
            Tab(text: '7 Days'),
            Tab(text: '30 Days'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimeline('Today', speed, now),
          _buildTimeline('Yesterday', speed, now.subtract(const Duration(days: 1))),
          _buildTimeline('Past 7 Days', speed, now.subtract(const Duration(days: 7))),
          _buildTimeline('Past 30 Days', speed, now.subtract(const Duration(days: 30))),
        ],
      ),
    );
  }

  Widget _buildTimeline(String label, double speed, DateTime reference) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsSummary(speed, reference),
          const SizedBox(height: 16),
          _buildTimelineEntry(
            time: DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(minutes: 5))),
            location: 'Current Location',
            coords: '${reference.toIso8601String().substring(0, 10)}',
            type: 'current',
          ),
          _buildTimelineEntry(
            time: DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(hours: 1))),
            location: 'Simulated Stop',
            coords: '-6.2088, 106.8456',
            type: 'stop',
          ),
          _buildTimelineEntry(
            time: DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(hours: 2))),
            location: 'Simulated Movement',
            coords: '-6.2000, 106.8300',
            type: 'move',
          ),
          if (label == 'Today') ...[
            const SizedBox(height: 16),
            _buildRoutePlaybackCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSummary(double speed, DateTime reference) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Distance', '${speed > 0 ? "12.3" : "0.0"} km'),
          _statItem('Duration', speed > 0 ? '2h 15m' : '--'),
          _statItem('Stops', '3'),
          _statItem('Places', '2'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildTimelineEntry({
    required String time,
    required String location,
    required String coords,
    required String type,
  }) {
    final isCurrent = type == 'current';
    final isStop = type == 'stop';
    final color = isCurrent
        ? ThemeConstants.primaryColor
        : isStop
            ? ThemeConstants.warningColor
            : ThemeConstants.neonPurple;
    final icon = isCurrent
        ? Icons.my_location
        : isStop
            ? Icons.location_off
            : Icons.directions_run;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(30),
                  border: Border.all(color: color.withAlpha(100), width: 1.5),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              Container(width: 2, height: 40,
                color: Colors.white.withAlpha(15)),
            ]),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(location, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isCurrent ? ThemeConstants.primaryColor : Colors.white,
                    )),
                    const Spacer(),
                    Text(time, style: TextStyle(
                      fontSize: 11, color: Colors.white.withAlpha(100),
                    )),
                  ]),
                  const SizedBox(height: 4),
                  Text(coords, style: TextStyle(
                    fontSize: 10, color: Colors.white.withAlpha(60),
                    fontFamily: 'monospace',
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePlaybackCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.play_circle, color: ThemeConstants.primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route Playback', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                Text('Today\'s movement', style: TextStyle(
                  fontSize: 11, color: Colors.white.withAlpha(100))),
              ],
            )),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ThemeConstants.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.play_arrow, color: ThemeConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text('Play Route', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: ThemeConstants.primaryColor)),
            ]),
          ),
        ],
      ),
    );
  }
}
