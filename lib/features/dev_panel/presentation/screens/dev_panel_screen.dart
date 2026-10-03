import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';

class DevPanelScreen extends ConsumerWidget {
  const DevPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geo = ref.watch(geolocationProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DEV PANEL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Color(0xFFFBBF24),
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _DevTile(
              icon: LucideIcons.mapPin,
              label: 'GPS Spoofing',
              status: geo.isSpoofing ? 'Spoofing: ON' : 'Spoofing: OFF',
              statusColor:
                  geo.isSpoofing ? AppColors.success : AppColors.textMuted,
              onTap: () => context.push('/dev-panel/gps'),
            ),
            _DevTile(
              icon: LucideIcons.award,
              label: 'Achievement Editor',
              status:
                  '${achievements.totalUnlocked}/${achievements.totalAchievements} unlocked',
              statusColor: AppColors.accent,
              onTap: () => context.push('/dev-panel/achievements'),
            ),
            _DevTile(
              icon: LucideIcons.compass,
              label: 'Quest Editor',
              status:
                  '${quests.completedCount}/${quests.allQuests.length} completed',
              statusColor: AppColors.primary,
              onTap: () => context.push('/dev-panel/quests'),
            ),
            _DevTile(
              icon: LucideIcons.database,
              label: 'Data Management',
              status: 'View & clear data',
              statusColor: AppColors.textMuted,
              onTap: () => context.push('/dev-panel/data'),
            ),
            _DevTile(
              icon: LucideIcons.hexagon,
              label: 'Polygon Editor',
              status: 'Draw claim areas',
              statusColor: AppColors.accent,
              onTap: () => context.push('/dev-panel/polygon-editor'),
            ),
            _DevTile(
              icon: LucideIcons.bug,
              label: 'Debug Tools',
              status: 'Providers & logs',
              statusColor: AppColors.textMuted,
              onTap: () => context.push('/dev-panel/debug'),
            ),
            _DevTile(
              icon: LucideIcons.history,
              label: 'Change History',
              status: 'Polygon / pin edits',
              statusColor: AppColors.info,
              onTap: () => context.push('/dev-panel/history'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;

  const _DevTile({
    required this.icon,
    required this.label,
    required this.status,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, size: 20, color: const Color(0xFFFBBF24)),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
