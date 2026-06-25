import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vortex_dashboard/services/trip_tracker.dart';
import 'package:vortex_dashboard/services/reverse_geocoder.dart';

class TripSummarySheet extends StatefulWidget {
  final String displayName;
  final String? photoUrl;
  final String presence;
  final double battery;

  const TripSummarySheet({
    super.key,
    required this.displayName,
    this.photoUrl,
    required this.presence,
    required this.battery,
  });

  @override
  State<TripSummarySheet> createState() => _TripSummarySheetState();
}

class _TripSummarySheetState extends State<TripSummarySheet> {
  bool _loadingNames = true;

  @override
  void initState() {
    super.initState();
    _resolvePlaceNames();
  }

  Future<void> _resolvePlaceNames() async {
    final tracker = TripTracker();
    final segments = tracker.computeTimeline();
    final geocoder = ReverseGeocoder();
    for (final seg in segments) {
      if (!seg.isMoving && seg.avgLat != 0) {
        seg.placeName = await geocoder.lookup(seg.avgLat, seg.avglng);
      }
    }
    if (mounted) setState(() => _loadingNames = false);
  }

  @override
  Widget build(BuildContext context) {
    final tracker = TripTracker();
    final segments = tracker.computeTimeline();
    final totalDist = tracker.totalDistanceKm;
    final moveTime = tracker.totalMovingTime;
    final stationaryTime = tracker.totalStationaryTime;

    final presenceColor = widget.presence == 'online'
        ? const Color(0xFF00E676)
        : widget.presence == 'away'
            ? const Color(0xFFFFC107)
            : Colors.red;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16, right: 16, top: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(12))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withAlpha(20),
                backgroundImage: widget.photoUrl != null
                    ? FileImage(File(widget.photoUrl!))
                    : null,
                child: widget.photoUrl == null
                    ? Text(
                        widget.displayName.isNotEmpty
                            ? widget.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.displayName,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: presenceColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.presence == 'online' ? 'Online'
                              : widget.presence == 'away' ? 'Away' : 'Offline',
                          style: TextStyle(
                            fontSize: 12, color: presenceColor, fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.flash_on, size: 12, color: widget.battery > 20
                            ? Colors.white54 : const Color(0xFFFF5252)),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.battery.toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.battery > 20 ? Colors.white54 : const Color(0xFFFF5252),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(10)),
            ),
            child: Row(
              children: [
                _summaryItem(Icons.route, '${totalDist.toStringAsFixed(1)} km', 'Distance'),
                _summaryDivider(),
                _summaryItem(Icons.directions_run, _fmtDuration(moveTime), 'Moving'),
                _summaryDivider(),
                _summaryItem(Icons.pause, _fmtDuration(stationaryTime), 'Stopped'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Timeline
          if (segments.isEmpty && !_loadingNames)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No activity recorded yet today',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            )
          else if (_loadingNames && segments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: segments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final seg = segments[i];
                  return _TimelineRow(segment: seg, isLast: i == segments.length - 1);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700,
          )),
          Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 10,
          )),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(width: 1, height: 32, color: Colors.white.withAlpha(15));
  }

  String _fmtDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }
}

class _TimelineRow extends StatelessWidget {
  final TripSegment segment;
  final bool isLast;

  const _TimelineRow({required this.segment, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final timeStr = '${segment.startTime.hour.toString().padLeft(2, '0')}:${segment.startTime.minute.toString().padLeft(2, '0')}'
        ' - ${segment.endTime.hour.toString().padLeft(2, '0')}:${segment.endTime.minute.toString().padLeft(2, '0')}';
    final icon = segment.isMoving ? Icons.directions_car : Icons.location_on;
    final iconColor = segment.isMoving ? const Color(0xFF448AFF) : const Color(0xFF00E676);

    String subtitle;
    if (segment.isMoving) {
      subtitle = 'Travel ${segment.distanceKm.toStringAsFixed(1)} km';
    } else {
      subtitle = segment.placeName ?? 'Location';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            if (!isLast)
              Container(width: 2, height: 30, color: Colors.white.withAlpha(12)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeStr, style: const TextStyle(
                  color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 1),
                Text(
                  segment.isMoving ? 'Moving · ${segment.duration.inMinutes}m' : 'Stationary · ${segment.duration.inMinutes}m',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
