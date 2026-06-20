import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/models/ride_model.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/providers/ride_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/widgets/common/stat_tile.dart';
import 'package:vortex_dashboard/core/utils/extensions.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _startRecording() {
    ref.read(trackingStateProvider.notifier).startTracking();
    _stopwatch.reset();
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pulseController.repeat(reverse: true);
  }

  void _stopRecording() {
    ref.read(trackingStateProvider.notifier).stopTracking();
    _stopwatch.stop();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _showRideCompleteDialog();
  }

  void _showRideCompleteDialog() {
    final state = ref.read(trackingStateProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Ride Complete',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogStat(
              'Distance',
              '${state.totalDistance.toStringAsFixed(2)} km',
            ),
            _dialogStat(
              'Duration',
              _formatDuration(_stopwatch.elapsed),
            ),
            _dialogStat(
              'Max Speed',
              '${state.maxSpeed.toStringAsFixed(1)} km/h',
            ),
            _dialogStat(
              'Avg Speed',
              '${state.avgSpeed.toStringAsFixed(1)} km/h',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exported as CSV')),
              );
            },
            child: const Text('Export CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exported as GPX')),
              );
            },
            child: const Text('Export GPX'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ride saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _dialogStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingStateProvider);
    final gpsData = ref.watch(gpsDataProvider);
    final isRecording = trackingState.isTracking;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('TRACKING'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeConstants.amoledBackground,
              const Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: isRecording
              ? _buildRecordingView(trackingState, gpsData)
              : _buildIdleView(trackingState),
        ),
      ),
    );
  }

  Widget _buildRecordingView(TrackingState state, GpsData? gps) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 120,
          ),
          child: Column(
            children: [
              _buildStatsGrid(state, gps),
              const SizedBox(height: 24),
              _buildTrackPointsList(state),
              const SizedBox(height: 12),
              _buildExportButtons(),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: _buildRecordButton(true),
        ),
      ],
    );
  }

  Widget _buildIdleView(TrackingState state) {
    return Stack(
      children: [
        Positioned.fill(child: _buildRideHistory(state)),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: _buildRecordButton(false),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(TrackingState state, GpsData? gps) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: StatTile(
                  label: 'Speed',
                  value: '${(gps?.speed ?? 0).toStringAsFixed(1)} km/h',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                child: StatTile(
                  label: 'Distance',
                  value: '${state.totalDistance.toStringAsFixed(2)} km',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: StatTile(
                  label: 'Duration',
                  value: _formatDuration(_stopwatch.elapsed),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                child: StatTile(
                  label: 'Max Speed',
                  value: '${state.maxSpeed.toStringAsFixed(1)} km/h',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: StatTile(
                  label: 'Avg Speed',
                  value: '${state.avgSpeed.toStringAsFixed(1)} km/h',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                child: StatTile(
                  label: 'Max Alt.',
                  value: '${state.maxAltitude.toStringAsFixed(0)} m',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordButton(bool isRecording) {
    const size = 80.0;

    Widget button = GestureDetector(
      onTap: isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: isRecording ? size * 0.85 : size,
        height: isRecording ? size * 0.85 : size,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isRecording ? BorderRadius.circular(16) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          isRecording
              ? Icons.stop_rounded
              : Icons.fiber_manual_record_rounded,
          color: Colors.white,
          size: isRecording ? 36 : 40,
        ),
      ),
    );

    if (isRecording) {
      button = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: button,
      );
    }

    return Center(child: button);
  }

  Widget _buildTrackPointsList(TrackingState state) {
    final points = state.trackPoints;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Track Points',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (points.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No points recorded yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: points.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Colors.white12),
                itemBuilder: (context, index) {
                  final point = points[index] as GpsData;
                  return ListTile(
                    dense: true,
                    leading: Text(
                      '#${index + 1}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    title: Text(
                      '${point.speed.toStringAsFixed(1)} km/h',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      point.timestamp.toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: Text(
                      '${point.altitude.toStringAsFixed(0)} m',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exported as GPX')),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, color: Colors.greenAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'GPX',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exported as CSV')),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'CSV',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideHistory(TrackingState state) {
    final history = state.rideHistory;
    if (history.isEmpty) {
      return Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_bike,
                  color: Colors.white24,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No rides yet',
                  style: TextStyle(color: Colors.white38, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the red button to start recording',
                  style: const TextStyle(color: Colors.white24),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100,
      ),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final ride = history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: ListTile(
              title: Text(
                ride.startTime.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${ride.distanceKm.toStringAsFixed(2)} km  •  ${_formatDuration(ride.duration)}',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Text(
                '${ride.averageSpeedKmh.toStringAsFixed(1)} km/h',
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ),
          ),
        );
      },
    );
  }
}
