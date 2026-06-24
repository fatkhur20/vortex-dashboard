import 'dart:math';

class LocationSnapshot {
  final DateTime timestamp;
  final double lat;
  final double lng;
  LocationSnapshot(this.timestamp, this.lat, this.lng);
}

class TimelineEvent {
  final DateTime startTime;
  final DateTime endTime;
  final String label;
  final bool isTravel;
  final double? placeLat;
  final double? placeLng;
  TimelineEvent({
    required this.startTime,
    required this.endTime,
    required this.label,
    this.isTravel = false,
    this.placeLat,
    this.placeLng,
  });
  Duration get duration => endTime.difference(startTime);
}

class LocationHistory {
  static final LocationHistory _instance = LocationHistory._();
  factory LocationHistory() => _instance;
  LocationHistory._();

  final Map<String, List<LocationSnapshot>> _history = {};

  void record(String memberId, double lat, double lng, DateTime time) {
    _history.putIfAbsent(memberId, () => []);
    final list = _history[memberId]!;
    if (list.isNotEmpty) {
      final last = list.last;
      final dist = _haversine(last.lat, last.lng, lat, lng);
      if (dist < 0.02 && time.difference(last.timestamp).inSeconds < 10) return;
    }
    list.add(LocationSnapshot(time, lat, lng));
    if (list.length > 10000) list.removeAt(0);
  }

  List<TimelineEvent> getTimeline(String memberId) {
    final list = _history[memberId];
    if (list == null || list.length < 3) return [];

    final events = <TimelineEvent>[];
    var i = 0;
    while (i < list.length) {
      final start = list[i];
      var j = i + 1;
      while (j < list.length) {
        final dist = _haversine(list[i].lat, list[i].lng, list[j].lat, list[j].lng);
        if (dist > 0.1) break;
        j++;
      }
      final duration = list[j - 1].timestamp.difference(list[i].timestamp);
      if (duration.inMinutes >= 2 && j - i >= 2) {
        events.add(TimelineEvent(
          startTime: list[i].timestamp,
          endTime: list[j - 1].timestamp,
          label: _describePlace(list[i].lat, list[i].lng),
          placeLat: list[i].lat,
          placeLng: list[i].lng,
        ));
        i = j;
      } else {
        i++;
      }
    }
    return events;
  }

  String _describePlace(double lat, double lng) {
    return 'Location ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180;

  void clear() => _history.clear();
}
