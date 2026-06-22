import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';
import 'package:vortex_dashboard/providers/geofence_provider.dart';
import 'package:vortex_dashboard/widgets/glass/glass_card.dart';

class GeofenceScreen extends ConsumerWidget {
  const GeofenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofences = ref.watch(geofenceListProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.amoledBackground,
      appBar: AppBar(
        title: const Text('Saved Places', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: geofences.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ThemeConstants.primaryColor.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.place, color: ThemeConstants.primaryColor, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('No saved places yet',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('Add a place from the map quick actions',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: geofences.length,
              itemBuilder: (ctx, i) {
                final gf = geofences[i];
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gf.typeColor.withValues(alpha: 0.2),
                        ),
                        child: Icon(Icons.place, color: gf.typeColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(gf.name,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('${gf.latitude.toStringAsFixed(4)}, ${gf.longitude.toStringAsFixed(4)} \u2022 ${gf.radiusMeters.toInt()}m radius',
                                style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (d) => AlertDialog(
                              backgroundColor: ThemeConstants.darkBackground,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Delete Place', style: TextStyle(color: Colors.white)),
                              content: Text('Delete "${gf.name}"?', style: const TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                                TextButton(onPressed: () => Navigator.pop(d, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(geofenceListProvider.notifier).delete(gf.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
