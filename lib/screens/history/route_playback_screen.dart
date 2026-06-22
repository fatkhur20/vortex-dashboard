import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class RoutePlaybackScreen extends StatefulWidget {
  final List<GpsData> trackPoints;

  const RoutePlaybackScreen({super.key, required this.trackPoints});

  @override
  State<RoutePlaybackScreen> createState() => _RoutePlaybackScreenState();
}

class _RoutePlaybackScreenState extends State<RoutePlaybackScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _progress = 0.0;
  bool _isPlaying = false;
  double _speedMultiplier = 1.0;
  Timer? _playbackTimer;
  late AnimationController _markerPulseController;

  double _minLat = 0, _maxLat = 0, _minLng = 0, _maxLng = 0;
  final Map<int, Offset> _cachedOffsets = {};
  Size _lastSize = Size.zero;

  static const _speeds = [1.0, 2.0, 4.0, 8.0];

  @override
  void initState() {
    super.initState();
    _calculateBounds();
    _markerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _markerPulseController.dispose();
    super.dispose();
  }

  void _calculateBounds() {
    if (widget.trackPoints.isEmpty) return;
    _minLat = widget.trackPoints.map((p) => p.latitude).reduce(min);
    _maxLat = widget.trackPoints.map((p) => p.latitude).reduce(max);
    _minLng = widget.trackPoints.map((p) => p.longitude).reduce(min);
    _maxLng = widget.trackPoints.map((p) => p.longitude).reduce(max);

    final latPad = (_maxLat - _minLat) * 0.1;
    final lngPad = (_maxLng - _minLng) * 0.1;
    _minLat -= latPad;
    _maxLat += latPad;
    _minLng -= lngPad;
    _maxLng += lngPad;
  }

  Offset _latLngToOffset(double lat, double lng, Size size) {
    const pad = 40.0;
    final w = size.width - 2 * pad;
    final h = size.height - 2 * pad;
    final lngRange = _maxLng - _minLng;
    final latRange = _maxLat - _minLat;
    if (lngRange == 0 || latRange == 0) return Offset(size.width / 2, size.height / 2);
    final x = pad + (lng - _minLng) / lngRange * w;
    final y = pad + (_maxLat - lat) / latRange * h;
    return Offset(x, y);
  }

  void _cacheOffsets(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;
    _cachedOffsets.clear();
    for (int i = 0; i < widget.trackPoints.length; i++) {
      _cachedOffsets[i] = _latLngToOffset(
        widget.trackPoints[i].latitude,
        widget.trackPoints[i].longitude,
        size,
      );
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    if (_currentIndex >= widget.trackPoints.length - 1) {
      setState(() {
        _currentIndex = 0;
        _progress = 0.0;
      });
    }
    setState(() => _isPlaying = true);
    _advancePoint();
  }

  void _pause() {
    setState(() => _isPlaying = false);
    _playbackTimer?.cancel();
  }

  void _advancePoint() {
    _playbackTimer?.cancel();
    if (!_isPlaying || _currentIndex >= widget.trackPoints.length - 1) {
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    final current = widget.trackPoints[_currentIndex];
    final next = widget.trackPoints[_currentIndex + 1];
    final dt = next.timestamp.difference(current.timestamp).inMilliseconds;
    final interval = (dt / _speedMultiplier).clamp(16, 5000).toInt();

    final startIndex = _currentIndex;
    double stepProgress = 0.0;
    final steps = (interval / 16).round().clamp(1, 120);
    final stepSize = 1.0 / steps;

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }
      stepProgress += stepSize;
      if (stepProgress >= 1.0) {
        timer.cancel();
        if (_currentIndex == startIndex) {
          setState(() {
            _currentIndex++;
            _progress = _currentIndex / (widget.trackPoints.length - 1);
          });
          _advancePoint();
        }
      } else {
        if (mounted) {
          setState(() {
            _progress = (startIndex + stepProgress) / (widget.trackPoints.length - 1);
          });
        }
      }
    });
  }

  void _cycleSpeed() {
    setState(() {
      final idx = _speeds.indexOf(_speedMultiplier);
      _speedMultiplier = _speeds[(idx + 1) % _speeds.length];
    });
    if (_isPlaying) {
      _advancePoint();
    }
  }

  void _reset() {
    _playbackTimer?.cancel();
    setState(() {
      _currentIndex = 0;
      _progress = 0.0;
      _isPlaying = false;
    });
  }

  GpsData? get _currentPoint {
    if (widget.trackPoints.isEmpty) return null;
    final idx = (_progress * (widget.trackPoints.length - 1)).round().clamp(0, widget.trackPoints.length - 1);
    return widget.trackPoints[idx];
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${h}:${m}:${s}';
  }

  @override
  Widget build(BuildContext context) {
    final point = _currentPoint;
    final totalDuration = widget.trackPoints.length >= 2
        ? widget.trackPoints.last.timestamp.difference(widget.trackPoints.first.timestamp)
        : Duration.zero;
    final elapsed = widget.trackPoints.length >= 2 && point != null
        ? point.timestamp.difference(widget.trackPoints.first.timestamp)
        : Duration.zero;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Route Playback',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          border: Border.all(color: Colors.white.withAlpha(15)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _RoutePainter(
                              offsets: _cachedOffsets,
                              currentIndex: _currentIndex,
                              progress: _progress,
                              totalPoints: widget.trackPoints.length,
                              pulseValue: _markerPulseController.value,
                              cacheOffsets: _cacheOffsets,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildProgressBar(elapsed, totalDuration),
            _buildStats(point),
            _buildControls(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(Duration elapsed, Duration total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(
                ThemeConstants.primaryColor.withAlpha(200),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(elapsed),
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(100))),
              Text(_formatDuration(total),
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(100))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(GpsData? point) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 14,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Speed', '${point?.speed.toStringAsFixed(0) ?? "--"} km/h'),
            _statItem('Time', point != null ? DateFormat('HH:mm:ss').format(point.timestamp) : '--:--:--'),
            _statItem('Altitude', '${point?.altitude.toStringAsFixed(0) ?? "--"} m'),
            _statItem('Point', '${_currentIndex + 1}/${widget.trackPoints.length}'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(100))),
    ]);
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        borderRadius: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _controlButton(Icons.skip_previous, 'Skip Back', !_isPlaying, () {
              if (_currentIndex > 0) {
                setState(() {
                  _currentIndex = max(0, _currentIndex - 10);
                  _progress = _currentIndex / (widget.trackPoints.length - 1);
                });
              }
            }),
            const SizedBox(width: 20),
            _controlButton(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              _isPlaying ? 'Pause' : 'Play',
              false, _togglePlay,
              large: true,
            ),
            const SizedBox(width: 20),
            _controlButton(Icons.skip_next, 'Skip Forward', !_isPlaying, () {
              if (_currentIndex < widget.trackPoints.length - 1) {
                setState(() {
                  _currentIndex = min(widget.trackPoints.length - 1, _currentIndex + 10);
                  _progress = _currentIndex / (widget.trackPoints.length - 1);
                });
              }
            }),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _cycleSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ThemeConstants.primaryColor.withAlpha(80)),
                ),
                child: Text(
                  '${_speedMultiplier.toStringAsFixed(0)}x',
                  style: TextStyle(
                    color: ThemeConstants.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, String tooltip, bool disabled, VoidCallback onTap, {bool large = false}) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: large ? 52 : 40,
          height: large ? 52 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: disabled
                ? Colors.white.withAlpha(10)
                : large
                    ? ThemeConstants.primaryColor.withAlpha(30)
                    : Colors.white.withAlpha(15),
          ),
          child: Icon(
            icon,
            color: disabled ? Colors.white24 : (large ? ThemeConstants.primaryColor : Colors.white70),
            size: large ? 28 : 20,
          ),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final Map<int, Offset> offsets;
  final int currentIndex;
  final double progress;
  final int totalPoints;
  final double pulseValue;
  final void Function(Size) cacheOffsets;

  _RoutePainter({
    required this.offsets,
    required this.currentIndex,
    required this.progress,
    required this.totalPoints,
    required this.pulseValue,
    required this.cacheOffsets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    cacheOffsets(size);
    if (offsets.isEmpty) return;

    final bgPaint = Paint()..color = const Color(0xFF0D1117);
    canvas.drawRect(Offset.zero & size, bgPaint);

    _drawGrid(canvas, size);
    _drawRouteLine(canvas);
    _drawStartEnd(canvas);
    _drawMarker(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 0.5;
    const gridLines = 6;
    for (int i = 0; i <= gridLines; i++) {
      final t = i / gridLines;
      canvas.drawLine(Offset(0, t * size.height), Offset(size.width, t * size.height), gridPaint);
      canvas.drawLine(Offset(t * size.width, 0), Offset(t * size.width, size.height), gridPaint);
    }
  }

  void _drawRouteLine(Canvas canvas) {
    if (offsets.length < 2) return;

    final playedPaint = Paint()
      ..color = ThemeConstants.primaryColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final remainingPaint = Paint()
      ..color = Colors.white.withAlpha(30)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final playedCount = (progress * (totalPoints - 1)).round().clamp(0, totalPoints - 1);

    // Route behind marker (played)
    for (int i = 0; i < playedCount && i + 1 < offsets.length; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, playedPaint);
      }
    }

    // Route ahead of marker (remaining)
    for (int i = playedCount; i + 1 < offsets.length; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, remainingPaint);
      }
    }
  }

  void _drawStartEnd(Canvas canvas) {
    final start = offsets[0];
    final end = offsets[totalPoints - 1];
    if (start != null) {
      canvas.drawCircle(start, 5, Paint()..color = ThemeConstants.successColor);
    }
    if (end != null) {
      canvas.drawCircle(end, 5, Paint()..color = const Color(0xFFFF1744));
    }
  }

  void _drawMarker(Canvas canvas) {
    final idx = (progress * (totalPoints - 1)).round().clamp(0, totalPoints - 1);
    final pos = offsets[idx];
    if (pos == null) return;

    final radius = 6.0 + pulseValue * 4;

    final glowPaint = Paint()
      ..color = ThemeConstants.primaryColor.withAlpha((50 * (1 - pulseValue * 0.5)).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(pos, radius + 6, glowPaint);

    canvas.drawCircle(
      pos,
      radius,
      Paint()..color = ThemeConstants.primaryColor,
    );

    canvas.drawCircle(
      pos,
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) {
    return old.progress != progress || old.pulseValue != pulseValue;
  }
}
