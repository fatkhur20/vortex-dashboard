import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/tracking_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/screens/map/map_screen.dart';

class GroupScreen extends ConsumerStatefulWidget {
  final bool showCreate;
  const GroupScreen({super.key, this.showCreate = false});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final activeId = ref.watch(activeGroupIdProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.amoledBackground,
      appBar: AppBar(
        title: const Text('Groups', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickActions(),
          const SizedBox(height: 24),
          const Text('My Groups', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2)),
          const SizedBox(height: 12),
          groupsAsync.when(
            data: (groups) => groups.isEmpty
                ? GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text('No groups yet', style: TextStyle(color: Colors.white38))),
                  )
                : Column(
                    children: groups.map((g) => _groupTile(g, g.id == activeId)).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _actionBtn(Icons.add_circle_outline, 'Create', _showCreateDialog)),
        const SizedBox(width: 12),
        Expanded(child: _actionBtn(Icons.qr_code_scanner, 'Join', _showJoinDialog)),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: ThemeConstants.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _groupTile(GroupInfo g, bool active) {
    final icon = g.memberCount == 1 ? Icons.person : g.memberCount == 2 ? Icons.favorite : Icons.groups;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await ref.read(groupActionsProvider).switchGroup(g.id);
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MapScreen()));
        },
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? ThemeConstants.primaryColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(icon, color: active ? ThemeConstants.primaryColor : Colors.white38, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${g.memberCount} ${g.memberCount == 1 ? 'member' : 'members'} · ${g.typeLabel}',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Active', style: TextStyle(fontSize: 11, color: ThemeConstants.primaryColor, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    _nameCtrl.text = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Group', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Group name',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _loading = true);
              await ref.read(groupActionsProvider).create(name);
              ref.read(groupActionsProvider).refresh();
              setState(() => _loading = false);
            },
            child: const Text('Create', style: TextStyle(color: ThemeConstants.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog() {
    _codeCtrl.text = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Join Group', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ThemeConstants.primaryColor, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                hintStyle: TextStyle(color: Colors.white15, fontSize: 28, letterSpacing: 8),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final code = _codeCtrl.text.trim().toUpperCase();
              if (code.length != 6) return;
              Navigator.pop(ctx);
              try {
                await ref.read(groupActionsProvider).join(code);
                ref.read(groupActionsProvider).refresh();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MapScreen()));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
              }
            },
            child: const Text('Join', style: TextStyle(color: ThemeConstants.primaryColor)),
          ),
        ],
      ),
    );
  }
}
