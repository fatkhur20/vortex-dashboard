import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VortexApp());
}

class VortexApp extends StatelessWidget {
  const VortexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vortex',
      theme: ThemeData.dark(),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Vortex Dashboard', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
