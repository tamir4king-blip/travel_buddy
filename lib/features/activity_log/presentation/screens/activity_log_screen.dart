import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/directional_icon.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Text(
              l10n.activityLog,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── Tab bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primaryLight.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                indicatorPadding: const EdgeInsets.all(2),
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.bookOpen, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.navLog),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.calendarClock, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.unlockTimeline),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LogTab(),
                _TimelineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Log Tab (original content) ──
class _LogTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quests = ref.watch(questsProvider);
    final achievements = ref.watch(achievementsProvider);

    final completedQuests = quests.completedCount;
    final totalQuests = quests.allQuests.length;
    final streak = quests.currentStreak;

    final activeSkills = quests.skillLevels.values.where((lv) => lv > 0).length;
    final totalXp = quests.skillXp.values.fold<int>(0, (sum, xp) => sum + xp);

    final unlocked = achievements.totalUnlocked;
    final total = achievements.totalAchievements;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Quests card
        _LogCard(
          title: l10n.navQuests,
          subtitle: '$completedQuests completed \u00b7 ${streak}d streak',
          icon: LucideIcons.compass,
          color: AppColors.accent,
          progress: totalQuests > 0 ? completedQuests / totalQuests : 0,
          onTap: () => context.go('/quests'),
        ),
        const SizedBox(height: 14),

        // Skills card
        _LogCard(
          title: l10n.navSkills,
          subtitle: '$activeSkills active \u00b7 $totalXp XP',
          icon: LucideIcons.sparkles,
          color: AppColors.purple,
          progress: activeSkills / 44,
          onTap: () => context.go('/skills'),
        ),
        const SizedBox(height: 14),

        // Achievements card
        _LogCard(
          title: l10n.navAchievements,
          subtitle: '$unlocked of $total unlocked',
          icon: LucideIcons.award,
          color: AppColors.primary,
          progress: total > 0 ? unlocked / total : 0,
          onTap: () => context.go('/achievements'),
        ),
      ],
    );
  }
}

// ── Timeline Tab ──
/// A single entry in the timeline — either an unlock or a revisit.
class _TimelineEntry {
  final Achievement achievement;
  final DateTime timestamp;
  final bool isRevisit;
  final int? visitNumber; // e.g. visit #3

  const _TimelineEntry({
    required this.achievement,
    required this.timestamp,
    this.isRevisit = false,
    this.visitNumber,
  });
}

class _TimelineTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final achievements = ref.watch(achievementsProvider);

    // Build timeline entries: unlocks + revisits
    final entries = <_TimelineEntry>[];

    for (final a in achievements.allAchievements) {
      if (!a.isUnlocked || a.unlockedAt == null) continue;

      // Add the initial unlock
      entries.add(_TimelineEntry(achievement: a, timestamp: a.unlockedAt!));

      // Add each revisit from history
      for (var i = 0; i < a.revisitHistory.length; i++) {
        entries.add(_TimelineEntry(
          achievement: a,
          timestamp: a.revisitHistory[i],
          isRevisit: true,
          visitNumber: i + 2, // visit #2, #3, etc.
        ));
      }
    }

    // Sort by timestamp descending
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarClock, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              l10n.noUnlockedTrophiesYet,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<_TimelineEntry>>{};
    for (final entry in entries) {
      final dateKey = DateFormat.yMMMd(locale.languageCode).format(entry.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: dateKeys.length,
      itemBuilder: (context, dateIndex) {
        final dateLabel = dateKeys[dateIndex];
        final items = grouped[dateLabel]!;
        final date = items.first.timestamp;
        final isToday = DateUtils.isSameDay(date, DateTime.now());
        final isYesterday = DateUtils.isSameDay(
            date, DateTime.now().subtract(const Duration(days: 1)));

        String displayDate = dateLabel;
        if (isToday) {
          displayDate = locale.languageCode == 'he' ? 'היום' : 'Today';
        } else if (isYesterday) {
          displayDate = locale.languageCode == 'he' ? 'אתמול' : 'Yesterday';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dateIndex > 0) const SizedBox(height: 20),
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      displayDate,
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.bgCardLight.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            // Timeline rows for this date
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final globalIndex = entries.indexOf(item);
              return Padding(
                padding: EdgeInsets.only(bottom: idx < items.length - 1 ? 8 : 0),
                child: _TimelineRow(
                  achievement: item.achievement,
                  locale: locale,
                  index: globalIndex,
                  isRevisit: item.isRevisit,
                  visitNumber: item.visitNumber,
                  timestamp: item.timestamp,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Achievement achievement;
  final Locale locale;
  final int index;
  final bool isRevisit;
  final int? visitNumber;
  final DateTime timestamp;

  const _TimelineRow({
    required this.achievement,
    required this.locale,
    required this.index,
    this.isRevisit = false,
    this.visitNumber,
    required this.timestamp,
  });

  Color get _tierColor => switch (achievement.tier) {
    AchievementTier.bronze => AppColors.bronze,
    AchievementTier.silver => AppColors.silver,
    AchievementTier.gold => AppColors.gold,
    AchievementTier.platinum => AppColors.platinum,
  };

  String _tierLabel(AppLocalizations l10n) => switch (achievement.tier) {
    AchievementTier.bronze => l10n.tierBronze,
    AchievementTier.silver => l10n.tierSilver,
    AchievementTier.gold => l10n.tierGold,
    AchievementTier.platinum => l10n.tierPlatinum,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = DateFormat.Hm(locale.languageCode).format(timestamp);
    final title = RegistryL10n.achievementTitle(locale, achievement.id, achievement.title);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRevisit
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.bgCardLight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Icon — trophy for unlock, footprints for revisit
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isRevisit
                  ? AppColors.info.withValues(alpha: 0.15)
                  : _tierColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isRevisit
                    ? AppColors.info.withValues(alpha: 0.3)
                    : _tierColor.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Icon(
                isRevisit ? LucideIcons.footprints : LucideIcons.trophy,
                size: 18,
                color: isRevisit ? AppColors.info : _tierColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (isRevisit)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Visit #${visitNumber ?? ""}',
                          style: TextStyle(
                            color: AppColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _tierColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _tierLabel(l10n),
                          style: TextStyle(
                            color: _tierColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (!isRevisit && achievement.isRetroactive) ...[
                      const SizedBox(width: 6),
                      Icon(LucideIcons.history, size: 12, color: AppColors.warning),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time + XP (or revisit label)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              if (isRevisit)
                Text(
                  'Revisit',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap, size: 12, color: AppColors.xpGlow),
                    const SizedBox(width: 2),
                    Text(
                      '${achievement.xpReward}',
                      style: TextStyle(
                        color: AppColors.xpGlow,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: (index * 40).clamp(0, 600)))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.03);
  }
}

// ── Log Card (unchanged from original) ──
class _LogCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback? onTap;

  const _LogCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.10),
              AppColors.bgCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: color.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                DirectionalChevron(color: AppColors.textMuted, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
