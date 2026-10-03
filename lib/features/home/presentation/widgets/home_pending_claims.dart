part of '../screens/home_screen.dart';

// ── Pending Quest Chain Claims Banner for Home Screen ──
class _HomeQuestChainClaims extends ConsumerWidget {
  const _HomeQuestChainClaims();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chainState = ref.watch(questChainProvider);
    final claimable = chainState.claimableQuests;

    if (claimable.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(LucideIcons.scroll, size: 16, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${claimable.length} ${claimable.length == 1 ? 'quest' : 'quests'} ready to claim!',
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
              itemCount: claimable.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final quest = claimable[index];
                return GestureDetector(
                  onTap: () {
                    ref.read(questChainProvider.notifier).claimQuest(quest.id);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(quest.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            quest.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+${quest.xpReward} XP',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
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
    );
  }
}

// ── Pending Claims Banner for Home Screen ──
// Always visible — shows pending trophies/revisits, or a waiting state.
class _HomePendingClaims extends ConsumerWidget {
  const _HomePendingClaims();

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final pendingClaims = achievements.allAchievements
        .where((a) => a.isPendingClaim && !a.isUnlocked)
        .toList();
    final pendingRevisits = achievements.allAchievements
        .where((a) => a.isPendingRevisit && a.isUnlocked)
        .toList();
    final hasPending = pendingClaims.isNotEmpty || pendingRevisits.isNotEmpty;
    final totalPending = pendingClaims.length + pendingRevisits.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasPending
              ? [
                  AppColors.gold.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.08),
                ]
              : [
                  AppColors.bgCard,
                  AppColors.bgCard,
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPending
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.bgCardLight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.trophy,
                  size: 16,
                  color: hasPending ? AppColors.gold : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasPending
                        ? '$totalPending ${totalPending == 1 ? 'trophy' : 'trophies'} ready to claim!'
                        : 'No trophies to claim yet',
                    style: TextStyle(
                      color: hasPending ? AppColors.gold : AppColors.textMuted,
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
          if (hasPending)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                itemCount: totalPending,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  // Show pending claims first, then revisits
                  final isRevisit = index >= pendingClaims.length;
                  final achievement = isRevisit
                      ? pendingRevisits[index - pendingClaims.length]
                      : pendingClaims[index];

                  return GestureDetector(
                    onTap: () async {
                      final navContext =
                          Navigator.of(context, rootNavigator: true).context;
                      final notifier =
                          ref.read(achievementsProvider.notifier);
                      if (isRevisit) {
                        final acknowledged =
                            await notifier.acknowledgeRevisit(achievement.id);
                        if (acknowledged && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(LucideIcons.footprints,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Visit #${achievement.visitCount} claimed — ${achievement.title}'),
                                ],
                              ),
                              backgroundColor: AppColors.info,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        final claimed =
                            await notifier.confirmPendingClaim(achievement.id);
                        if (claimed && navContext.mounted) {
                          await AchievementUnlockPopup.show(
                              navContext, achievement);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRevisit
                              ? [AppColors.info, AppColors.info.withValues(alpha: 0.8)]
                              : [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRevisit
                                ? LucideIcons.footprints
                                : LucideIcons.sparkles,
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
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isRevisit
                                ? 'Claim Revisit'
                                : '+${achievement.xpReward} XP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                'Explore the map to discover trophies nearby!',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
