import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/widgets/achievement_detail_sheet.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';

/// Every place in one Israel list, grouped by region (north to south), with
/// visited places checked off — the MTP "what's left to visit" view.
class IsraelListSheet extends ConsumerStatefulWidget {
  const IsraelListSheet({super.key, required this.list});

  final IsraelList list;

  static Future<void> show(BuildContext context, IsraelList list) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IsraelListSheet(list: list),
    );
  }

  @override
  ConsumerState<IsraelListSheet> createState() => _IsraelListSheetState();
}

class _IsraelListSheetState extends ConsumerState<IsraelListSheet> {
  bool _onlyRemaining = false;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    String t(String en, String he) => lang == 'he' ? he : en;

    final places = ref
        .watch(achievementsProvider.select((s) => s.allAchievements))
        .where((a) => a.collectionId == widget.list.id)
        .toList();
    final unlocked = places.where((a) => a.isUnlocked).length;

    final byRegion = <IsraelRegion, List<Achievement>>{};
    for (final a in places) {
      if (_onlyRemaining && a.isUnlocked) continue;
      final region = IsraelRegion.fromTags(a.tags);
      if (region == null) continue;
      byRegion.putIfAbsent(region, () => []).add(a);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Text(widget.list.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.list.label(lang),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        t('$unlocked of ${places.length} visited · +${widget.list.bonusXp} XP for all',
                            '$unlocked מתוך ${places.length} · ‎+${widget.list.bonusXp} XP על הכול'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                FilterChip(
                  label: Text(t('Still to visit', 'עוד לא ביקרתי')),
                  selected: _onlyRemaining,
                  onSelected: (v) => setState(() => _onlyRemaining = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: byRegion.isEmpty
                ? Center(
                    child: Text(
                      t('You\'ve visited them all! 🏆', 'ביקרת בכולם! 🏆'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      for (final region in IsraelRegion.values)
                        if (byRegion[region] case final items?) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                            child: Text(
                              region.label(lang),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          for (final a in items)
                            _PlaceRow(
                              achievement: a,
                              title: RegistryL10n.achievementTitle(
                                  locale, a.id, a.title),
                            ),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.achievement, required this.title});

  final Achievement achievement;
  final String title;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final tierColor = switch (a.tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => AchievementDetailSheet.show(context, a),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Icon(
              a.isUnlocked
                  ? LucideIcons.checkCircle2
                  : a.isPendingClaim
                      ? LucideIcons.mapPin
                      : LucideIcons.circle,
              size: 18,
              color: a.isUnlocked
                  ? AppColors.success
                  : a.isPendingClaim
                      ? AppColors.accent
                      : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: a.isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    a.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${a.xpReward} XP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: tierColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
