import 'dart:math';
import 'package:vortex_dashboard/models/gps_data.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

class HeatmapService {
  static final HeatmapService _instance = HeatmapService._();
  factory HeatmapService() => _instance;
  HeatmapService._();

  List<HeatmapPoint> _points = [];
  bool _loaded = false;

  List<HeatmapPoint> get points => _points;
  bool get hasData => _points.isNotEmpty;

  Future<void> loadFromStorage() async {
    final rides = StorageService().getAllRides();
    final raw = <GpsData>[];
    for (final ride in rides) {
      raw.addAll(ride.trackPoints);
    }
    _points = _cluster(raw);
    _loaded = true;
  }

  void addPoints(List<GpsData> data) {
    final newPoints = _cluster(data);
    _points = _merge(_points, newPoints);
  }

  void clear() {
    _points = [];
    _loaded = false;
  }

  List<HeatmapPoint> _cluster(List<GpsData> data) {
    if (data.isEmpty) return [];
    const clusterMeters = 30.0;
    final clustered = <HeatmapPoint>[];
    for (final pt in data) {
      bool found = false;
      for (final c in clustered) {
        final d = _haversine(c.lat, c.lng, pt.latitude, pt.longitude) * 1000;
        if (d < clusterMeters) {
          final total = c.count + 1;
          c.lat = c.lat * (c.count / total) + pt.latitude * (1 / total);
          c.lng = c.lng * (c.count / total) + pt.longitude * (1 / total);
          c.count = total;
          c.weight = c.weight + (pt.speed > 0 ? 1.5 : 1.0);
          found = true;
          break;
        }
      }
      if (!found) {
        clustered.add(HeatmapPoint(
          lat: pt.latitude,
          lng: pt.longitude,
          weight: pt.speed > 0 ? 1.5 : 1.0,
        ));
      }
    }
    return clustered;
  }

  List<HeatmapPoint> _merge(List<HeatmapPoint> a, List<HeatmapPoint> b) {
    final merged = [...a];
    const clusterMeters = 30.0;
    for (final pt in b) {
      bool found = false;
      for (final m in merged) {
        final d = _haversine(m.lat, m.lng, pt.lat, pt.lng) * 1000;
        if (d < clusterMeters) {
          final total = m.count + pt.count;
          m.lat = (m.lat * m.count + pt.lat * pt.count) / total;
          m.lng = (m.lng * m.count + pt.lng * pt.count) / total;
          m.count = total;
          m.weight = m.weight + pt.weight;
          found = true;
          break;
        }
      }
      if (!found) merged.add(pt);
    }
    return merged;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = _sin2(dLat / 2) + _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLon / 2);
    return r * 2 * _atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180;
  double _sin2(double x) { final s = sin(x); return s * s; }
  double _cos(double x) => cos(x);
  double _atan2(double y, double x) => atan2(y, x);
}

class HeatmapPoint {
  final String id;
  double lat;
  double lng;
  double weight;
  int count;

  HeatmapPoint({
    required this.lat,
    required this.lng,
    this.weight = 1.0,
    this.count = 1,
    String? id,
  }) : id = id ?? '${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
}
