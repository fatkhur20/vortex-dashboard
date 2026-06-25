import 'dart:math';

class LocationSample {
  final DateTime timestamp;
  final double lat;
  final double lng;
  final double speed;

  LocationSample({
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.speed,
  });
}

class TripSegment {
  final DateTime startTime;
  final DateTime endTime;
  final bool isMoving;
  final double distanceKm;
  final double avgLat;
  final double avglng;
  String? placeName;

  TripSegment({
    required this.startTime,
    required this.endTime,
    required this.isMoving,
    this.distanceKm = 0,
    this.avgLat = 0,
    this.avglng = 0,
    this.placeName,
  });

  Duration get duration => endTime.difference(startTime);
}

class TripTracker {
  static final TripTracker _instance = TripTracker._();
  factory TripTracker() => _instance;
  TripTracker._();

  final List<LocationSample> _samples = [];

  void record(double lat, double lng, double speed, DateTime timestamp) {
    if (_samples.isNotEmpty) {
      final last = _samples.last;
      final d = _haversineKm(last.lat, last.lng, lat, lng);
      if (d < 0.001 && (timestamp.difference(last.timestamp).inSeconds < 5)) return;
    }
    _samples.add(LocationSample(timestamp: timestamp, lat: lat, lng: lng, speed: speed));
    if (_samples.length > 20000) _samples.removeAt(0);
  }

  List<TripSegment> computeTimeline() {
    if (_samples.length < 2) return [];

    final segments = <TripSegment>[];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todaySamples = _samples.where((s) => s.timestamp.isAfter(todayStart)).toList();
    if (todaySamples.length < 2) return [];

    var segStart = todaySamples.first.timestamp;
    var segMoving = todaySamples.first.speed >= 3;
    var segDist = 0.0;
    var segLatSum = 0.0;
    var segLngSum = 0.0;
    var segSampleCount = 0;
    var segSamples = <LocationSample>[];

    for (var i = 0; i < todaySamples.length; i++) {
      final s = todaySamples[i];
      segSamples.add(s);
      segLatSum += s.lat;
      segLngSum += s.lng;
      segSampleCount++;

      if (i > 0) {
        segDist += _haversineKm(todaySamples[i - 1].lat, todaySamples[i - 1].lng, s.lat, s.lng);
      }

      if (i < todaySamples.length - 1) {
        final moving = s.speed >= 3;
        if (moving != segMoving) {
          final dur = s.timestamp.difference(segStart);
          if (dur.inMinutes >= 5 || segSamples.length > 10) {
            segments.add(TripSegment(
              startTime: segStart,
              endTime: s.timestamp,
              isMoving: segMoving,
              distanceKm: segDist,
              avgLat: segLatSum / segSampleCount,
              avglng: segLngSum / segSampleCount,
            ));
            segStart = s.timestamp;
            segMoving = moving;
            segDist = 0;
            segLatSum = 0;
            segLngSum = 0;
            segSampleCount = 0;
            segSamples = [s];
          }
        }
      }
    }

    if (segSamples.length >= 2) {
      segments.add(TripSegment(
        startTime: segStart,
        endTime: segSamples.last.timestamp,
        isMoving: segMoving,
        distanceKm: segDist,
        avgLat: segLatSum / segSampleCount,
        avglng: segLngSum / segSampleCount,
      ));
    }

    return segments;
  }

  double get totalDistanceKm {
    double d = 0;
    for (var i = 1; i < _samples.length; i++) {
      d += _haversineKm(_samples[i - 1].lat, _samples[i - 1].lng, _samples[i].lat, _samples[i].lng);
    }
    return d;
  }

  Duration get totalMovingTime {
    final d = Duration.zero;
    final segments = computeTimeline();
    Duration dt = Duration.zero;
    for (final s in segments) {
      if (s.isMoving) dt += s.duration;
    }
    return dt;
  }

  Duration get totalStationaryTime {
    Duration dt = Duration.zero;
    final segments = computeTimeline();
    for (final s in segments) {
      if (!s.isMoving) dt += s.duration;
    }
    return dt;
  }

  void clear() => _samples.clear();

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180;
}
