part of '../screens/home_screen.dart';

// ── Zone Detail Sheet ──
class _ZoneDetailSheet extends StatelessWidget {
  final ZoneState zone;
  final ZoneContentState content;

  const _ZoneDetailSheet({required this.zone, required this.content});

  static Future<void> show(
    BuildContext context,
    ZoneState zone,
    ZoneContentState content,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => _ZoneDetailContent(
          zone: zone,
          content: content,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ZoneDetailContent extends StatelessWidget {
  final ZoneState zone;
  final ZoneContentState content;
  final ScrollController scrollController;

  const _ZoneDetailContent({
    required this.zone,
    required this.content,
    required this.scrollController,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    // Build unified list sorted by distance
    final items = <_ZoneDetailItem>[];

    for (final nearby in content.nearbyAchievements) {
      items.add(_ZoneDetailItem(
        type: _ZoneItemType.achievement,
        title: nearby.item.title,
        distanceMeters: nearby.distanceMeters,
        achievement: nearby.item,
        isCompleted: nearby.item.isUnlocked,
        isPending: nearby.item.isPendingClaim && !nearby.item.isUnlocked,
        subtitle: _tierLabel(nearby.item.tier),
        xp: nearby.item.xpReward,
      ));
    }

    for (final nearby in content.nearbyActivities) {
      items.add(_ZoneDetailItem(
        type: _ZoneItemType.activity,
        title: nearby.item.title,
        distanceMeters: nearby.distanceMeters,
        activity: nearby.item,
        isCompleted: nearby.item.completionCount > 0,
        subtitle: nearby.item.category,
        xp: nearby.item.xpReward,
      ));
    }

    for (final quest in content.nearbyQuests) {
      items.add(_ZoneDetailItem(
        type: _ZoneItemType.quest,
        title: quest.title,
        distanceMeters: -1, // quests don't have a single location
        quest: quest,
        isCompleted: quest.isCompleted,
        subtitle:
            '${quest.completedStepCount}/${quest.totalSteps} steps',
        xp: quest.xpReward,
        icon: quest.icon,
      ));
    }

    // Sort: quests first (no distance), then by distance
    items.sort((a, b) {
      if (a.distanceMeters < 0 && b.distanceMeters < 0) return 0;
      if (a.distanceMeters < 0) return 1;
      if (b.distanceMeters < 0) return 1;
      return a.distanceMeters.compareTo(b.distanceMeters);
    });

    final achievementCount = content.nearbyAchievements.length;
    final activityCount = content.nearbyActivities.length;
    final questCount = content.nearbyQuests.length;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        Row(
          children: [
            Icon(LucideIcons.radar, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                zone.hasZone ? zone.displayLabel : 'Your Area',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Within 100km radius',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),

        // Summary chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
              icon: LucideIcons.trophy,
              color: AppColors.gold,
              label: '$achievementCount achievements',
            ),
            _SummaryChip(
              icon: LucideIcons.compass,
              color: AppColors.accent,
              label: '$activityCount activities',
            ),
            if (questCount > 0)
              _SummaryChip(
                icon: LucideIcons.scroll,
                color: const Color(0xFF8B5CF6),
                label: '$questCount quests',
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Divider
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Items list
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No nearby items found',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            _ZoneDetailRow(
              item: items[i],
              formatDistance: _formatDistance,
            ),
          ],
      ],
    );
  }

  String _tierLabel(AchievementTier tier) => switch (tier) {
        AchievementTier.bronze => 'Bronze',
        AchievementTier.silver => 'Silver',
        AchievementTier.gold => 'Gold',
        AchievementTier.platinum => 'Platinum',
      };
}

enum _ZoneItemType { achievement, activity, quest }

class _ZoneDetailItem {
  final _ZoneItemType type;
  final String title;
  final double distanceMeters;
  final Achievement? achievement;
  final SideQuest? activity;
  final Quest? quest;
  final bool isCompleted;
  final bool isPending;
  final String subtitle;
  final int xp;
  final String? icon;

  const _ZoneDetailItem({
    required this.type,
    required this.title,
    required this.distanceMeters,
    this.achievement,
    this.activity,
    this.quest,
    this.isCompleted = false,
    this.isPending = false,
    required this.subtitle,
    required this.xp,
    this.icon,
  });
}

class _ZoneDetailRow extends StatelessWidget {
  final _ZoneDetailItem item;
  final String Function(double) formatDistance;

  const _ZoneDetailRow({
    required this.item,
    required this.formatDistance,
  });

  @override
  Widget build(BuildContext context) {
    final (typeIcon, typeColor) = switch (item.type) {
      _ZoneItemType.achievement => (LucideIcons.trophy, AppColors.gold),
      _ZoneItemType.activity => (LucideIcons.compass, AppColors.accent),
      _ZoneItemType.quest => (LucideIcons.scroll, const Color(0xFF8B5CF6)),
    };

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.icon != null
                  ? Center(
                      child:
                          Text(item.icon!, style: const TextStyle(fontSize: 16)))
                  : Icon(typeIcon, size: 16, color: typeColor),
            ),
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.isPending
                          ? AppColors.gold
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.zap,
                          size: 10, color: AppColors.xpGreen),
                      const SizedBox(width: 2),
                      Text(
                        '+${item.xp}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.xpGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Distance
            if (item.distanceMeters >= 0) ...[
              const SizedBox(width: 8),
              Text(
                formatDistance(item.distanceMeters),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(width: 8),

            // Status
            if (item.isPending)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(
                item.isCompleted ? LucideIcons.check : LucideIcons.chevronRight,
                size: 16,
                color: item.isCompleted
                    ? AppColors.success
                    : AppColors.textMuted.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    switch (item.type) {
      case _ZoneItemType.achievement:
        if (item.achievement != null) {
          AchievementDetailSheet.show(context, item.achievement!);
        }
      case _ZoneItemType.activity:
        if (item.activity != null) {
          context.push(
              '/skills/${item.activity!.skillType}/activity/${item.activity!.id}');
        }
      case _ZoneItemType.quest:
        // No dedicated quest detail screen — just dismiss
        break;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _SummaryChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
