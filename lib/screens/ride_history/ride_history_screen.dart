import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/ride_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';
import 'package:vortex_dashboard/core/utils/extensions.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(rideListProvider);
    final stats = ref.watch(rideStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RIDE HISTORY'),
        centerTitle: true,
        actions: [
          if (rides.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatsHeader(stats),
            _buildSearchBar(),
            Expanded(
              child: rides.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        return _buildRideCard(rides[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(AsyncValue<Map<String, dynamic>> stats) {
    return stats.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${data['rideCount']}',
                'Rides',
                Icons.route,
              ),
              _buildStatItem(
                '${(data['totalDistance'] as double).toStringAsFixed(1)}',
                'Total KM',
                Icons.straighten,
              ),
              _buildStatItem(
                '${(data['maxSpeed'] as double).toStringAsFixed(0)}',
                'Max KM/H',
                Icons.speed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ThemeConstants.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search rides...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            border: InputBorder.none,
            icon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.5),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(rideListProvider.notifier).search('');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            ref.read(rideListProvider.notifier).search(value);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route,
              color: Colors.white.withOpacity(0.2),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No rides recorded yet',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking to record your rides',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(ride) {
    final duration = ride.duration;
    final dateStr = ride.startTime.dateFormatted;
    final timeStr =
        '${ride.startTime.timeFormatted} - ${ride.endTime?.timeFormatted ?? "..."}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: ThemeConstants.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.5),
                    size: 18,
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Ride'),
                          content: const Text(
                            'Are you sure you want to delete this ride?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(rideListProvider.notifier).deleteRide(ride.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'export_gpx',
                      child: ListTile(
                        leading: Icon(Icons.file_download),
                        title: Text('Export GPX'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export_csv',
                      child: ListTile(
                        leading: Icon(Icons.file_download),
                        title: Text('Export CSV'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              timeStr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRideStat(
                  '${ride.distanceKm.toStringAsFixed(2)}',
                  'KM',
                ),
                _buildRideStat(
                  duration.shortFormat,
                  'Duration',
                ),
                _buildRideStat(
                  '${ride.averageSpeedKmh.toStringAsFixed(0)}',
                  'Avg KM/H',
                ),
                _buildRideStat(
                  '${ride.maxSpeedKmh.toStringAsFixed(0)}',
                  'Max KM/H',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Rides'),
        content: const Text(
          'Are you sure you want to delete all ride history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(rideListProvider.notifier).deleteAllRides();
              Navigator.pop(ctx);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
