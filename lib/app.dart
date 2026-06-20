import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/theme/app_theme.dart';
import 'package:vortex_dashboard/providers/settings_provider.dart';
import 'package:vortex_dashboard/screens/home/dashboard_screen.dart';
import 'package:vortex_dashboard/screens/splash_screen.dart';
import 'package:vortex_dashboard/services/permission_service.dart';

class VortexDashboardApp extends ConsumerStatefulWidget {
  const VortexDashboardApp({super.key});

  @override
  ConsumerState<VortexDashboardApp> createState() => _VortexDashboardAppState();
}

class _VortexDashboardAppState extends ConsumerState<VortexDashboardApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await PermissionService.requestAllPermissions();
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Vortex Dashboard',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _initialized
          ? const DashboardScreen()
          : const SplashScreen(),
    );
  }
}
