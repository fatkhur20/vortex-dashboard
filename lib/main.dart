import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vortex_dashboard/app.dart';
import 'package:vortex_dashboard/core/constants/app_constants.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  if (mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxToken);
  }

  try {
    await Hive.initFlutter();
    await StorageService.initialize();
  } catch (e, s) {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/vortex_crash.log');
    await f.writeAsString('$e\n$s');
  }

  FlutterError.onError = (details) {
    try {
      getApplicationDocumentsDirectory().then((dir) {
        final f = File('${dir.path}/vortex_flutter_error.log');
        f.writeAsStringSync('${details.exception}\n${details.stack}');
      });
    } catch (_) {}
    FlutterError.dumpErrorToConsole(details);
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: ${details.exception}',
            style: const TextStyle(color: Color(0xFFFF1744), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  try {
    runApp(
      const ProviderScope(
        child: VortexDashboardApp(),
      ),
    );
  } catch (e, s) {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/vortex_runapp_crash.log');
    await f.writeAsString('$e\n$s');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Startup error: $e')),
        ),
      ),
    );
  }
}
