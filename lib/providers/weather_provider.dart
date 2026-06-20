import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/models/weather_model.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final weatherProvider = FutureProvider.autoDispose<WeatherModel>((ref) async {
  final location = ref.watch(currentLocationProvider);
  final service = ref.watch(weatherServiceProvider);

  return service.getWeather(
    latitude: location['lat']!,
    longitude: location['lng']!,
  );
});

final weatherRefreshProvider = StateNotifierProvider<WeatherRefreshNotifier, int>((ref) {
  return WeatherRefreshNotifier();
});

class WeatherRefreshNotifier extends StateNotifier<int> {
  Timer? _timer;

  WeatherRefreshNotifier() : super(0);

  void refresh() {
    state++;
  }

  void startAutoRefresh({Duration interval = const Duration(minutes: 5)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
