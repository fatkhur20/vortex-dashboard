import 'package:flutter/material.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/models/member_info.dart';

class FloatingMembersCard extends StatelessWidget {
  final List<MemberInfo> members;
  final int memberCount;
  final void Function(MemberInfo) onMemberTap;

  const FloatingMembersCard({
    super.key,
    required this.members,
    required this.memberCount,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withAlpha(210),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: ThemeConstants.primaryColor, size: 16),
              const SizedBox(width: 6),
              Text(
                '$memberCount member${memberCount == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...members.take(4).map((m) => _memberTile(m)),
          if (members.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${members.length - 4} more',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _memberTile(MemberInfo member) {
    final emoji = _activityEmoji(member.activity);
    final isOnline = member.presence == 'online';
    return GestureDetector(
      onTap: () => onMemberTap(member),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                member.displayName.length > 12
                    ? '${member.displayName.substring(0, 12)}...'
                    : member.displayName,
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? const Color(0xFF00E676) : member.presence == 'away' ? const Color(0xFFFFC107) : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _activityEmoji(String activity) {
    switch (activity) {
      case 'Walking': return '\u{1F6B6}';
      case 'Running': return '\u{1F3C3}';
      case 'Cycling': return '\u{1F6B4}';
      case 'Driving': return '\u{1F697}';
      case 'Stationary': return '\u{1F9CD}';
      default: return '\u{1F4CD}';
    }
  }
}
