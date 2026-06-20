import 'package:flutter/material.dart';
import 'package:vortex_dashboard/screens/home/dashboard_screen.dart';
import 'package:vortex_dashboard/screens/map/map_screen.dart';
import 'package:vortex_dashboard/screens/tracking/tracking_screen.dart';
import 'package:vortex_dashboard/screens/compass/compass_screen.dart';
import 'package:vortex_dashboard/screens/altimeter/altimeter_screen.dart';
import 'package:vortex_dashboard/screens/gps_status/gps_status_screen.dart';
import 'package:vortex_dashboard/screens/weather/weather_screen.dart';
import 'package:vortex_dashboard/screens/performance/performance_screen.dart';
import 'package:vortex_dashboard/screens/ride_history/ride_history_screen.dart';
import 'package:vortex_dashboard/screens/settings/settings_screen.dart';
import 'package:vortex_dashboard/screens/sos/sos_screen.dart';
import 'package:vortex_dashboard/screens/trip_analytics/trip_analytics_screen.dart';

class AppRouter {
  static const String dashboard = '/';
  static const String map = '/map';
  static const String tracking = '/tracking';
  static const String compass = '/compass';
  static const String altimeter = '/altimeter';
  static const String gpsStatus = '/gps-status';
  static const String weather = '/weather';
  static const String performance = '/performance';
  static const String rideHistory = '/ride-history';
  static const String settings = '/settings';
  static const String sos = '/sos';
  static const String tripAnalytics = '/trip-analytics';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );
      case map:
        return MaterialPageRoute(
          builder: (_) => const MapScreen(),
        );
      case tracking:
        return MaterialPageRoute(
          builder: (_) => const TrackingScreen(),
        );
      case compass:
        return MaterialPageRoute(
          builder: (_) => const CompassScreen(),
        );
      case altimeter:
        return MaterialPageRoute(
          builder: (_) => const AltimeterScreen(),
        );
      case gpsStatus:
        return MaterialPageRoute(
          builder: (_) => const GpsStatusScreen(),
        );
      case weather:
        return MaterialPageRoute(
          builder: (_) => const WeatherScreen(),
        );
      case performance:
        return MaterialPageRoute(
          builder: (_) => const PerformanceScreen(),
        );
      case rideHistory:
        return MaterialPageRoute(
          builder: (_) => const RideHistoryScreen(),
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      case sos:
        return MaterialPageRoute(
          builder: (_) => const SosScreen(),
        );
      case tripAnalytics:
        return MaterialPageRoute(
          builder: (_) => const TripAnalyticsScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );
    }
  }
}
