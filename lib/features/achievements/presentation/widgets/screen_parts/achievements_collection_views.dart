part of '../../screens/achievements_screen.dart';

// ══════════════════════════════════════════════════════════════
// Collection Info (data holder for a collection inside a tier)
// ══════════════════════════════════════════════════════════════

class _CollectionInfo {
  final String label;
  final IconData icon;
  final List<Achievement> achievements;
  final bool isCountryCollection;

  const _CollectionInfo({
    required this.label,
    required this.icon,
    required this.achievements,
    this.isCountryCollection = false,
  });
}

// ══════════════════════════════════════════════════════════════
// Tier Section (top-level: Global / Continental / Country / Zone)
// ══════════════════════════════════════════════════════════════

class _TierSection extends StatelessWidget {
  final _GeoTier tier;
  final List<Achievement> achievements;
  final List<_CollectionInfo> collections;

  const _TierSection({
    required this.tier,
    required this.achievements,
    required this.collections,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final total = achievements.length;
    final isComplete = total > 0 && unlocked == total;
    final color = _geoTierColor(tier);

    final tierIcon = switch (tier) {
      _GeoTier.global => LucideIcons.globe2,
      _GeoTier.continent => LucideIcons.globe,
      _GeoTier.country => LucideIcons.flag,
      _GeoTier.zone => LucideIcons.mapPin,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isComplete
                ? color.withValues(alpha: 0.4)
                : AppColors.bgCardLight.withValues(alpha: 0.5),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: const RoundedRectangleBorder(),
            collapsedShape: const RoundedRectangleBorder(),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(tierIcon, size: 18, color: color),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _geoTierLabel(tier),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _GeoTierBadge(tier: tier),
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  '$unlocked / $total',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  '${collections.length} ${collections.length == 1 ? 'collection' : 'collections'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: _ProgressBadge(
                value: total > 0 ? unlocked / total : 0),
            children: [
              const Divider(height: 1, indent: 16, endIndent: 16),
              for (final collection in collections)
                _CollectionAccordion(collection: collection),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Collection Accordion (inside a tier section)
// ══════════════════════════════════════════════════════════════

class _CollectionAccordion extends StatelessWidget {
  final _CollectionInfo collection;

  const _CollectionAccordion({required this.collection});

  @override
  Widget build(BuildContext context) {
    final unlocked =
        collection.achievements.where((a) => a.isUnlocked).length;
    final total = collection.achievements.length;
    final isComplete = total > 0 && unlocked == total;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.bgCardLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            collection.icon,
            size: 14,
            color: isComplete ? AppColors.success : AppColors.textMuted,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                collection.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'COLLECTION',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$unlocked / $total',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        children: collection.isCountryCollection
            ? _buildByContinentGroups(context)
            : [
                for (var i = 0; i < collection.achievements.length; i++)
                  _AchievementRow(
                      achievement: collection.achievements[i], index: i),
              ],
      ),
    );
  }

  List<Widget> _buildByContinentGroups(BuildContext context) {
    final byContinent = <String, List<Achievement>>{};
    for (final a in collection.achievements) {
      final continent = a.collectionId;
      if (continent == null) continue;
      byContinent.putIfAbsent(continent, () => []).add(a);
    }

    return [
      for (final cInfo in _continents)
        if (byContinent.containsKey(cInfo.id))
          _ContinentSubAccordion(
            continent: cInfo,
            achievements: byContinent[cInfo.id]!,
          ),
    ];
  }
}

// ══════════════════════════════════════════════════════════════
// Continent Sub-Accordion (inside a collection)
// ══════════════════════════════════════════════════════════════

class _ContinentSubAccordion extends StatelessWidget {
  final _ContinentInfo continent;
  final List<Achievement> achievements;

  const _ContinentSubAccordion({
    required this.continent,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final total = achievements.length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
        leading: Text(continent.emoji, style: const TextStyle(fontSize: 18)),
        title: Text(
          continent.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '$unlocked / $total',
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        children: [
          for (var i = 0; i < achievements.length; i++)
            _AchievementRow(achievement: achievements[i], index: i),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Achievement Row
// ══════════════════════════════════════════════════════════════

class _AchievementRow extends ConsumerWidget {
  final Achievement achievement;
  final int index;

  const _AchievementRow({required this.achievement, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch fresh state so pending claim status is reactive
    final fresh = ref.watch(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == achievement.id, orElse: () => achievement);
    final isPending = fresh.isPendingClaim && !fresh.isUnlocked;

    final locale = Localizations.localeOf(context);
    final geo = ref.watch(geolocationProvider);
    final title = RegistryL10n.achievementTitle(
        locale, achievement.id, achievement.title);

    String? distanceLabel;
    if (geo.hasLocation &&
        achievement.latitude != null &&
        achievement.longitude != null) {
      final dist =
          geo.distanceTo(achievement.latitude!, achievement.longitude!);
      distanceLabel = dist < 1000
          ? '${dist.round()}m'
          : '${(dist / 1000).toStringAsFixed(1)}km';
    }

    final tierColor = switch (achievement.tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };

    return InkWell(
      onTap: () => AchievementDetailSheet.show(context, fresh),
      child: Container(
        decoration: isPending
            ? BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        child: Row(
          children: [
            if (isPending)
              Icon(LucideIcons.sparkles, size: 12, color: AppColors.gold)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierColor,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isPending
                      ? AppColors.gold
                      : fresh.isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                  fontWeight: isPending || fresh.isUnlocked
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (distanceLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                distanceLabel,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(width: 8),
            if (isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                fresh.isUnlocked
                    ? LucideIcons.check
                    : LucideIcons.circle,
                size: 14,
                color: fresh.isUnlocked
                    ? AppColors.success
                    : AppColors.textMuted.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════════════════════════

/// Badge showing the geographic difficulty tier.
class _GeoTierBadge extends StatelessWidget {
  final _GeoTier tier;

  const _GeoTierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final color = _geoTierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _geoTierLabel(tier),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Percentage completion badge.
class _ProgressBadge extends StatelessWidget {
  final double value;

  const _ProgressBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final color = pct == 100
        ? AppColors.success
        : pct > 0
            ? AppColors.primaryLight
            : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Achievement Timeline Tab
