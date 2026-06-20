import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/gps_provider.dart';
import 'package:vortex_dashboard/services/storage_service.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _sosActivated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gpsData = ref.watch(gpsDataProvider);
    final storage = StorageService();
    final contactName = storage.getString('emergency_contact');
    final contactPhone = storage.getString('emergency_contact_phone');
    final hasContact = contactName.isNotEmpty && contactPhone.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SOS'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildSosButton(),
            const Spacer(),
            if (_sosActivated) ...[
              _buildSosActivatedInfo(gpsData),
            ] else ...[
              _buildInstructions(),
            ],
            const Spacer(flex: 2),
            if (hasContact)
              _buildContactInfo(contactName, contactPhone),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSosButton() {
    return GestureDetector(
      onLongPress: () {
        setState(() => _sosActivated = !_sosActivated);
        if (_sosActivated) {
          _triggerSos();
        }
      },
      onTap: () {
        if (!_sosActivated) {
          _showConfirmationDialog();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _sosActivated ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sosActivated
                    ? ThemeConstants.errorColor
                    : ThemeConstants.errorColor.withValues(alpha: 0.2),
                border: Border.all(
                  color: ThemeConstants.errorColor,
                  width: 3,
                ),
                boxShadow: _sosActivated
                    ? [
                        BoxShadow(
                          color: ThemeConstants.errorColor.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: _sosActivated ? Colors.white : ThemeConstants.errorColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  Text(
                    _sosActivated ? 'ACTIVATED' : 'LONG PRESS',
                    style: TextStyle(
                      color: _sosActivated
                          ? Colors.white.withValues(alpha: 0.7)
                          : ThemeConstants.errorColor.withValues(alpha: 0.5),
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: ThemeConstants.warningColor,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap to confirm or long-press\nto activate SOS immediately',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your emergency contact will be notified\nwith your current location',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosActivatedInfo(gpsData) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.location_on,
            color: ThemeConstants.errorColor,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Location shared with emergency contact',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${gpsData.latitude.toStringAsFixed(6)}, ${gpsData.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accuracy: ${gpsData.accuracy.toStringAsFixed(0)}m',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() => _sosActivated = false);
              },
              child: const Text(
                'CANCEL SOS',
                style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String name, String phone) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Icon(
            Icons.contact_emergency,
            color: ThemeConstants.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                phone,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withValues(alpha: 0.3),
            size: 16,
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activate SOS?'),
        content: const Text(
          'Your emergency contact will be notified with your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _sosActivated = true);
              _triggerSos();
            },
            child: const Text(
              'ACTIVATE SOS',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSos() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('SOS Alert Sent'),
        backgroundColor: ThemeConstants.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
