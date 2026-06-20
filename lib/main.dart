import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vortex_dashboard/app.dart';
import 'package:vortex_dashboard/core/constants/app_constants.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    await StorageService.initialize();
  } catch (e, s) {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/vortex_crash.log');
    await f.writeAsString('$e\n$s');
  }

  FlutterError.onError = (details) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/vortex_flutter_error.log');
    await f.writeAsString('${details.exception}\n${details.stack}');
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
