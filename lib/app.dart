import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/theme/app_theme.dart';
import 'package:vortex_dashboard/providers/settings_provider.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/screens/auth/login_screen.dart';
import 'package:vortex_dashboard/screens/home/home_shell.dart';
import 'package:vortex_dashboard/screens/splash_screen.dart';
import 'package:vortex_dashboard/services/permission_service.dart';
import 'package:vortex_dashboard/services/storage_service.dart';

class CircleApp extends ConsumerStatefulWidget {
  const CircleApp({super.key});

  @override
  ConsumerState<CircleApp> createState() => _CircleAppState();
}

class _CircleAppState extends ConsumerState<CircleApp> {
  bool _initialized = false;
  bool _showLogin = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await PermissionService.requestAllPermissions();
    final savedName = StorageService.instance.getString('user_display_name');
    if (savedName.isNotEmpty) {
      await _doInitialize(savedName, null);
    } else {
      setState(() => _showLogin = true);
    }
  }

  void _onLogin(String name, String? photoPath) async {
    setState(() => _showLogin = false);
    await _doInitialize(name, photoPath);
  }

  Future<void> _doInitialize(String displayName, String? photoPath) async {
    final svc = ref.read(trackingServiceProvider);
    await svc.initialize(displayName: displayName);
    await StorageService.instance.saveString('user_display_name', displayName);
    if (photoPath != null) {
      await StorageService.instance.saveString('user_photo_path', photoPath);
    }
    final groupId = await svc.getOrCreatePersonalGroup();
    svc.startSync(ref, groupId: groupId);
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    Widget home;
    if (_showLogin) {
      home = LoginScreen(onLogin: _onLogin);
    } else if (!_initialized) {
      home = const SplashScreen();
    } else {
      home = const HomeShell();
    }

    return MaterialApp(
      title: 'Circle',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: home,
    );
  }
}
