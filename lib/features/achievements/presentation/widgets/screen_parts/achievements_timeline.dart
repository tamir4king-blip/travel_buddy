part of '../../screens/achievements_screen.dart';

// ══════════════════════════════════════════════════════════════

class _TimelineEntry {
  final Achievement achievement;
  final DateTime timestamp;
  final bool isRevisit;
  final int? visitNumber;

  const _TimelineEntry({
    required this.achievement,
    required this.timestamp,
    this.isRevisit = false,
    this.visitNumber,
  });
}

class _AchievementTimelineTab extends ConsumerWidget {
  const _AchievementTimelineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final achievements = ref.watch(achievementsProvider);

    final entries = <_TimelineEntry>[];
    for (final a in achievements.allAchievements) {
      if (!a.isUnlocked || a.unlockedAt == null) continue;

      entries
          .add(_TimelineEntry(achievement: a, timestamp: a.unlockedAt!));

      for (var i = 0; i < a.revisitHistory.length; i++) {
        entries.add(_TimelineEntry(
          achievement: a,
          timestamp: a.revisitHistory[i],
          isRevisit: true,
          visitNumber: i + 2,
        ));
      }
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarClock,
                size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              l10n.noUnlockedTrophiesYet,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<_TimelineEntry>>{};
    for (final entry in entries) {
      final dateKey =
          DateFormat.yMMMd(locale.languageCode).format(entry.timestamp);
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
          displayDate =
              locale.languageCode == 'he' ? '\u05d4\u05d9\u05d5\u05dd' : 'Today';
        } else if (isYesterday) {
          displayDate =
              locale.languageCode == 'he' ? '\u05d0\u05ea\u05de\u05d5\u05dc' : 'Yesterday';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dateIndex > 0) const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.15)),
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
                      color:
                          AppColors.bgCardLight.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final globalIndex = entries.indexOf(item);
              return Padding(
                padding: EdgeInsets.only(
                    bottom: idx < items.length - 1 ? 8 : 0),
                child: _TimelineRow(
                  achievement: item.achievement,
                  timestamp: item.timestamp,
                  isRevisit: item.isRevisit,
                  visitNumber: item.visitNumber,
                  index: globalIndex,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Timeline Row ──

class _TimelineRow extends StatelessWidget {
  final Achievement achievement;
  final DateTime timestamp;
  final bool isRevisit;
  final int? visitNumber;
  final int index;

  const _TimelineRow({
    required this.achievement,
    required this.timestamp,
    this.isRevisit = false,
    this.visitNumber,
    required this.index,
  });

  Color get _tierColor => switch (achievement.tier) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platinum => AppColors.platinum,
      };

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final time = DateFormat.Hm(locale.languageCode).format(timestamp);
    final title = RegistryL10n.achievementTitle(
        locale, achievement.id, achievement.title);

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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: (isRevisit ? AppColors.info : _tierColor)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isRevisit
                        ? 'Visit #${visitNumber ?? ""}'
                        : _tierLabel,
                    style: TextStyle(
                      color: isRevisit ? AppColors.info : _tierColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                    Icon(LucideIcons.zap,
                        size: 12, color: AppColors.xpGlow),
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

  String get _tierLabel => switch (achievement.tier) {
        AchievementTier.bronze => 'Bronze',
        AchievementTier.silver => 'Silver',
        AchievementTier.gold => 'Gold',
        AchievementTier.platinum => 'Platinum',
      };
}

// ══════════════════════════════════════════════════════════════
// Pending Claims Banner (achievements only)
// ══════════════════════════════════════════════════════════════

class _AchievementsPendingClaims extends ConsumerWidget {
  const _AchievementsPendingClaims();

  Future<void> _claimAll(
    BuildContext context,
    WidgetRef ref,
    List<Achievement> pending,
  ) async {
    final navContext = Navigator.of(context, rootNavigator: true).context;
    final notifier = ref.read(achievementsProvider.notifier);
    final batch = pending.take(claimAllMaxBatch).toList();
    final claimed = <Achievement>[];
    var totalXp = 0;

    for (final achievement in batch) {
      final success = await notifier.confirmPendingClaim(achievement.id);
      if (success) {
        claimed.add(achievement);
        totalXp += achievement.xpReward;
      }
    }

    if (claimed.isEmpty || !navContext.mounted) return;

    await AchievementUnlockPopup.showChain(navContext, claimed);

    if (navContext.mounted) {
      await ClaimAllSummaryDialog.show(
        navContext,
        claimed: claimed,
        totalXp: totalXp,
      );
    }
  }

  Future<void> _claimSingle(
    BuildContext context,
    WidgetRef ref,
    Achievement achievement,
  ) async {
    final navContext = Navigator.of(context, rootNavigator: true).context;
    final notifier = ref.read(achievementsProvider.notifier);
    final claimed = await notifier.confirmPendingClaim(achievement.id);
    if (claimed && navContext.mounted) {
      await AchievementUnlockPopup.show(navContext, achievement);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final pendingClaims = achievements.allAchievements
        .where((a) => a.isPendingClaim && !a.isUnlocked)
        .toList();

    if (pendingClaims.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.trophy, size: 16, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pendingClaims.length} ${pendingClaims.length == 1 ? 'achievement' : 'achievements'} ready to claim!',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (pendingClaims.length > 1)
                    GestureDetector(
                      onTap: () => _claimAll(context, ref, pendingClaims),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.gold, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Claim All',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                itemCount: pendingClaims.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final achievement = pendingClaims[index];
                  return GestureDetector(
                    onTap: () => _claimSingle(context, ref, achievement),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.sparkles,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              achievement.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
