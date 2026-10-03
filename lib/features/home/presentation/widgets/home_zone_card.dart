part of '../screens/home_screen.dart';

// ── Nearby Zone Card ──
class _NearbyZoneCard extends ConsumerStatefulWidget {
  const _NearbyZoneCard();

  @override
  ConsumerState<_NearbyZoneCard> createState() => _NearbyZoneCardState();
}

class _NearbyZoneCardState extends ConsumerState<_NearbyZoneCard> {
  bool _isRefreshing = false;

  Future<void> _refreshZone() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(geolocationProvider.notifier).getCurrentLocation();
      await ref.read(zoneProvider.notifier).forceRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = ref.watch(zoneProvider);
    final content = ref.watch(zoneContentProvider);
    final geo = ref.watch(geolocationProvider);

    final hasLocation = geo.hasLocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: hasLocation
          ? _buildContent(zone, content)
          : _buildNoLocation(),
    );
  }

  Widget _buildNoLocation() {
    return Row(
      children: [
        Icon(LucideIcons.mapPinOff, size: 18,
            color: AppColors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'No location available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ),
        GestureDetector(
          onTap: _isRefreshing ? null : _refreshZone,
          child: _isRefreshing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                )
              : Icon(LucideIcons.refreshCw, size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildContent(ZoneState zone, ZoneContentState content) {
    final overallPct = (content.overallProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(LucideIcons.radar, size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              'Current Zone',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Zone name + refresh + progress %
        Row(
          children: [
            Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                zone.hasZone ? zone.displayLabel : 'Your Area',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _isRefreshing ? null : _refreshZone,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _isRefreshing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      )
                    : Icon(LucideIcons.refreshCw, size: 16,
                        color: AppColors.primary.withValues(alpha: 0.5)),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$overallPct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Overall progress bar
        _ZoneProgressBar(
          progress: content.overallProgress,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),

        // ── Achievements row (location achievements only) ──
        _ZoneCategory(
          icon: LucideIcons.trophy,
          color: AppColors.gold,
          label: 'Achievements',
          earned: content.unlockedTravelTrophies,
          total: content.totalTravelTrophies,
          progress: content.totalTravelTrophies > 0
              ? content.unlockedTravelTrophies / content.totalTravelTrophies
              : 0,
        ),
        const SizedBox(height: 10),

        // ── Activities row (quests in zone) ──
        _ZoneCategory(
          icon: LucideIcons.compass,
          color: AppColors.accent,
          label: 'Activities',
          earned: content.completedActivities,
          total: content.totalActivitiesInZone,
          progress: content.activityProgress,
        ),

        // ── Story Quests in zone ──
        if (content.nearbyQuests.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ZoneQuestsMiniBar(quests: content.nearbyQuests),
        ],

        // ── View Details tap target ──
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _ZoneDetailSheet.show(context, zone, content),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.list, size: 14,
                    color: AppColors.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  'View All Nearby',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoneProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const _ZoneProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 5,
        backgroundColor: color.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _ZoneCategory extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int earned;
  final int total;
  final double progress;

  const _ZoneCategory({
    required this.icon,
    required this.color,
    required this.label,
    required this.earned,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$earned / $total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _ZoneProgressBar(progress: progress, color: color),
      ],
    );
  }
}

// ── Story Quests Mini Bar (inside zone card) ──
class _ZoneQuestsMiniBar extends StatelessWidget {
  final List<Quest> quests;

  const _ZoneQuestsMiniBar({required this.quests});

  @override
  Widget build(BuildContext context) {
    const questColor = Color(0xFF8B5CF6);

    return Column(
      children: [
        Row(
          children: [
            Icon(LucideIcons.scroll, size: 16, color: questColor),
            const SizedBox(width: 8),
            Text(
              'Quests',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${quests.length} active nearby',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: questColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quests.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final quest = quests[index];
              final stepsLeft = quest.totalSteps - quest.completedStepCount;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: questColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: questColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(quest.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(
                        quest.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: questColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$stepsLeft left',
                      style: TextStyle(
                        fontSize: 10,
                        color: questColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
