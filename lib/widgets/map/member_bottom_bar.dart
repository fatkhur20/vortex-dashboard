import 'package:flutter/material.dart';
import 'package:vortex_dashboard/models/member_info.dart';
import 'package:vortex_dashboard/services/location_history.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class MemberBottomBar extends StatefulWidget {
  final List<MemberInfo> members;
  final String? selectedMemberId;
  final ValueChanged<MemberInfo> onMemberTap;

  const MemberBottomBar({
    super.key,
    required this.members,
    this.selectedMemberId,
    required this.onMemberTap,
  });

  @override
  State<MemberBottomBar> createState() => _MemberBottomBarState();
}

class _MemberBottomBarState extends State<MemberBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(MemberBottomBar old) {
    super.didUpdateWidget(old);
    if (widget.selectedMemberId != null && old.selectedMemberId == null) {
      _animController.forward();
    } else if (widget.selectedMemberId == null && old.selectedMemberId != null) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.members.where((m) => m.id != widget.selectedMemberId || widget.selectedMemberId == null).toList();
    final selected = widget.selectedMemberId != null
        ? widget.members.where((m) => m.id == widget.selectedMemberId).firstOrNull
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected != null)
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1,
            child: _TimelinePanel(member: selected, onClose: () {
              widget.onMemberTap(selected);
            }),
          ),
        Container(
          height: 64,
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final m = members[i];
              final isSelected = m.id == widget.selectedMemberId;
              return _MemberAvatar(
                member: m,
                isSelected: isSelected,
                onTap: () => widget.onMemberTap(m),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final MemberInfo member;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberAvatar({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final online = member.presence == 'online';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryColor.withAlpha(30)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? ThemeConstants.primaryColor.withAlpha(150)
                : Colors.white.withAlpha(15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withAlpha(20),
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (online)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              member.displayName.length > 6
                  ? '${member.displayName.substring(0, 5)}..'
                  : member.displayName,
              style: const TextStyle(
                fontSize: 8, color: Colors.white70, fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on, size: 7,
                    color: (member.battery ?? 100) > 20
                        ? Colors.white54 : const Color(0xFFFF5252)),
                const SizedBox(width: 2),
                Text(
                  '${(member.battery ?? 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 8,
                    color: (member.battery ?? 100) > 20
                        ? Colors.white54 : const Color(0xFFFF5252),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (member.speed > 0) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.speed, size: 7, color: Colors.white38),
                  const SizedBox(width: 1),
                  Text(
                    '${member.speed.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 8, color: Colors.white54, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  final MemberInfo member;
  final VoidCallback onClose;

  const _TimelinePanel({required this.member, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final events = LocationHistory().getTimeline(member.id);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white.withAlpha(20),
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  member.displayName,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No history yet this session',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            )
          else
            ...events.map((e) => _timelineRow(e)),
        ],
      ),
    );
  }

  Widget _timelineRow(TimelineEvent e) {
    final icon = e.isTravel ? Icons.directions_car : Icons.location_on;
    final iconColor = e.isTravel ? const Color(0xFF448AFF) : const Color(0xFF00E676);
    final timeStr =
        '${e.startTime.hour.toString().padLeft(2, '0')}:${e.startTime.minute.toString().padLeft(2, '0')}';
    final durStr = e.duration.inMinutes >= 60
        ? '${e.duration.inHours}h ${e.duration.inMinutes % 60}m'
        : '${e.duration.inMinutes}m';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              e.label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$timeStr ($durStr)',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
