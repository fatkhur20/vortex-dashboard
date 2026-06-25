import 'dart:convert';
import 'package:http/http.dart' as http;

class ReverseGeocoder {
  static final ReverseGeocoder _instance = ReverseGeocoder._();
  factory ReverseGeocoder() => _instance;
  ReverseGeocoder._();

  final Map<String, String> _cache = {};
  DateTime _lastRequest = DateTime(2000);
  static const int _minIntervalMs = 1100;

  Future<String> lookup(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final now = DateTime.now();
    final diff = now.difference(_lastRequest).inMilliseconds;
    if (diff < _minIntervalMs) {
      await Future.delayed(Duration(milliseconds: _minIntervalMs - diff));
    }
    _lastRequest = DateTime.now();

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=0&zoom=16',
      );
      final resp = await http.get(url, headers: {
        'User-Agent': 'VortexDashboard/1.0',
      });
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String? ?? '';
        final short = _shorten(displayName);
        if (short.isNotEmpty) {
          _cache[key] = short;
          return short;
        }
      }
    } catch (_) {}

    _cache[key] = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    return _cache[key]!;
  }

  String _shorten(String name) {
    final parts = name.split(', ');
    if (parts.length >= 3) {
      return parts.take(3).join(', ');
    }
    return name;
  }
}
