import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/nearby_achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';

class DebugToolsScreen extends ConsumerWidget {
  const DebugToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geo = ref.watch(geolocationProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);
    final nearby = ref.watch(nearbyAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider State Inspector
          _StateCard(
            title: 'GeolocationProvider',
            icon: LucideIcons.mapPin,
            entries: {
              'latitude': geo.latitude?.toStringAsFixed(6) ?? 'null',
              'longitude': geo.longitude?.toStringAsFixed(6) ?? 'null',
              'isTracking': '${geo.isTracking}',
              'isLiveTracking': '${geo.isLiveTracking}',
              'hasPermission': '${geo.hasPermission}',
              'isSpoofing': '${geo.isSpoofing}',
              'error': geo.error ?? 'null',
            },
          ),
          const SizedBox(height: 12),

          _StateCard(
            title: 'AchievementsProvider',
            icon: LucideIcons.award,
            entries: {
              'total': '${achievements.totalAchievements}',
              'unlocked': '${achievements.totalUnlocked}',
              'filterTier': achievements.filterTier?.name ?? 'none',
              'filterCollection': achievements.filterCollection ?? 'none',
              'searchQuery':
                  achievements.searchQuery.isEmpty ? '(empty)' : achievements.searchQuery,
              'completedCollections':
                  '${achievements.completedCollections.length}',
            },
          ),
          const SizedBox(height: 12),

          _StateCard(
            title: 'QuestsProvider',
            icon: LucideIcons.compass,
            entries: {
              'total': '${quests.allQuests.length}',
              'completed': '${quests.completedCount}',
              'streak': '${quests.currentStreak}',
              'skillTypes': '${quests.skillXp.length}',
              'filterCategory': quests.filterCategory ?? 'none',
              'filterDifficulty':
                  quests.filterDifficulty?.name ?? 'none',
            },
          ),
          const SizedBox(height: 12),

          _StateCard(
            title: 'NearbyAchievementsProvider',
            icon: LucideIcons.radio,
            entries: {
              'nearbyCount': '${nearby.nearbyCount}',
              'newlyDiscovered': '${nearby.newlyDiscovered.length}',
              'nearby': nearby.nearby.map((a) => a.title).join(', ').isEmpty
                  ? '(none)'
                  : nearby.nearby.map((a) => a.title).join(', '),
            },
          ),
          const SizedBox(height: 20),

          // Trigger Proximity Alert
          const Text('Trigger Proximity Alert',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Tap an achievement to spoof your location to its coordinates and trigger the proximity pipeline.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...achievementRegistry.where((a) => a.latitude != null && !a.isUnlocked).map(
            (a) {
              // Check if already unlocked from provider state
              final current = achievements.allAchievements
                  .where((x) => x.id == a.id)
                  .firstOrNull;
              if (current?.isUnlocked == true) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref
                          .read(geolocationProvider.notifier)
                          .enableSpoof(a.latitude!, a.longitude!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Spoofed to ${a.title} — proximity alert should trigger'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.zap,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(a.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ),
                          Text(
                            '${a.tier.name} • ${a.claimRadius?.toInt() ?? 0}m',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Test Sentry Crash
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => throw Exception('Sentry test crash'),
              child: const Text('Test Sentry Crash'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Force Refresh
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(achievementsProvider);
                ref.invalidate(questsProvider);
                ref.invalidate(nearbyAchievementsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All providers invalidated'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Force Refresh All Providers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, String> entries;

  const _StateCard({
    required this.title,
    required this.icon,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(e.key,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ),
                  Expanded(
                    child: Text(e.value,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
