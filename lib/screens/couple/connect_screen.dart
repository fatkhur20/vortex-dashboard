import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/partner_provider.dart';
import 'package:vortex_dashboard/screens/map/map_screen.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final _codeController = TextEditingController();
  bool _isCreatingInvite = false;
  bool _isJoining = false;
  String? _inviteCode;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.amoledBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _inviteCode != null ? _buildInviteView() : _buildConnectView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                ThemeConstants.primaryColor.withValues(alpha: 0.3),
                ThemeConstants.primaryColor.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Icon(Icons.favorite, size: 48, color: ThemeConstants.primaryColor),
        ),
        const SizedBox(height: 24),
        Text(
          'Connect With Partner',
          style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share your invite code or enter your\npartner\'s code to get started',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.5), height: 1.4),
        ),
        const SizedBox(height: 48),

        _buildActionButton(
          icon: Icons.person_add_alt_1,
          label: 'Generate Invite',
          subtitle: 'Create a code to share with your partner',
          loading: _isCreatingInvite,
          onTap: _createInvite,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.qr_code_scanner,
          label: 'Scan QR Code',
          subtitle: 'Scan your partner\'s invite code',
          loading: false,
          onTap: () => _showEnterCodeSheet(),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.keyboard,
          label: 'Enter Code',
          subtitle: 'Type your partner\'s 6-character code',
          loading: false,
          onTap: () => _showEnterCodeSheet(),
        ),

        if (_error != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ThemeConstants.errorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: ThemeConstants.errorColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_error!, style: TextStyle(color: ThemeConstants.errorColor, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildInviteView() {
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$_inviteCode';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ThemeConstants.successColor.withValues(alpha: 0.15),
          ),
          child: Icon(Icons.check_circle, size: 40, color: ThemeConstants.successColor),
        ),
        const SizedBox(height: 20),
        Text(
          'Invite Created',
          style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Share this code with your partner',
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 32),

        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Column(
            children: [
              Text(
                _inviteCode!,
                style: TextStyle(
                  fontSize: 42, fontWeight: FontWeight.w800,
                  color: ThemeConstants.primaryColor,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expires in 1 hour',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(qrUrl, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.qr_code, size: 120, color: Colors.grey.shade800),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Center(child: CircularProgressIndicator(
                  color: ThemeConstants.primaryColor,
                ));
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: GlassCard.neon(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextButton.icon(
              onPressed: _shareInvite,
              icon: Icon(Icons.share, color: ThemeConstants.primaryColor, size: 20),
              label: Text(
                'SHARE INVITE',
                style: TextStyle(
                  color: ThemeConstants.primaryColor,
                  letterSpacing: 2, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() { _inviteCode = null; _error = null; }),
          child: Text(
            'Create new code',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
        ),

        if (_success != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ThemeConstants.successColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: ThemeConstants.successColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_success!, style: TextStyle(color: ThemeConstants.successColor, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon, required String label, required String subtitle,
    required bool loading, required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: loading
                      ? Padding(padding: const EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2.5, color: ThemeConstants.primaryColor))
                      : Icon(icon, color: ThemeConstants.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,
                      )),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45), fontSize: 13,
                      )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnterCodeSheet() {
    _codeController.text = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: ThemeConstants.darkBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enter Invite Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Ask your partner to share their code',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w700,
                  color: ThemeConstants.primaryColor, letterSpacing: 8,
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.15),
                    letterSpacing: 8, fontSize: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GlassCard.neon(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextButton(
                  onPressed: _isJoining ? null : _joinWithCode,
                  child: _isJoining
                      ? SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: ThemeConstants.primaryColor,
                          ),
                        )
                      : Text(
                          'CONNECT',
                          style: TextStyle(
                            color: ThemeConstants.primaryColor,
                            letterSpacing: 2, fontWeight: FontWeight.w600, fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _createInvite() async {
    setState(() { _isCreatingInvite = true; _error = null; });
    try {
      final invite = await ref.read(pairActionProvider).createInvite();
      setState(() {
        _inviteCode = invite.code;
        _isCreatingInvite = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isCreatingInvite = false;
      });
    }
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) return;
    setState(() { _isJoining = true; _error = null; });
    try {
      final user = ref.read(coupleTrackingServiceProvider).currentUser;
      await ref.read(pairActionProvider).joinInvite(code, name: user?.displayName);
      setState(() => _isJoining = false);
      if (mounted) {
        ref.read(coupleTrackingServiceProvider).startSync(ref);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MapScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isJoining = false;
      });
    }
  }

  Future<void> _shareInvite() async {
    if (_inviteCode == null) return;
    if (_inviteCode!.isEmpty) return;
    try {
      await Share.share(
        'Join my group on Vortex Tracker!\n\nInvite code: $_inviteCode\n\nDownload Vortex Tracker and enter this code to connect.',
        subject: 'Vortex Tracker Invite',
      );
    } catch (_) {}
  }
}
