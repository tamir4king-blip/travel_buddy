part of '../../screens/quests_screen.dart';

// ─── Quest chain card ────────────────────────────────────────────────────────

class _QuestChainCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onTap;

  const _QuestChainCard({required this.quest, required this.onTap});

  static Color _rarityColor(QuestRarity r) => switch (r) {
        QuestRarity.common => const Color(0xFF6B7280),
        QuestRarity.rare => const Color(0xFF3B82F6),
        QuestRarity.epic => const Color(0xFF8B5CF6),
        QuestRarity.legendary => const Color(0xFFF59E0B),
      };

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(quest.rarity);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget card = ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quest.isClaimed
                ? AppColors.success.withValues(alpha: 0.3)
                : quest.isClaimable
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + title + rarity
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(quest.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress row
            Row(
              children: [
                // Rarity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    quest.rarity.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // XP badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.xpGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${quest.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.xpGreen,
                    ),
                  ),
                ),
                const Spacer(),
                // Step counter
                Text(
                  '${quest.completedStepCount}/${quest.totalSteps}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: quest.isClaimed
                        ? AppColors.success
                        : quest.isClaimable
                            ? AppColors.gold
                            : color,
                  ),
                ),
                if (quest.isClaimed) ...[
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.success),
                ] else if (quest.isClaimable) ...[
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.gift, size: 16, color: AppColors.gold),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Step progress dots
            _StepProgressDots(
              total: quest.totalSteps,
              completed: quest.completedStepCount,
              color: quest.isClaimed
                  ? AppColors.success
                  : quest.isClaimable
                      ? AppColors.gold
                      : color,
            ),
          ],
        ),
      ),
    );

    if (quest.rarity == QuestRarity.legendary) {
      card = GlowContainer(
        glowColor: color,
        borderRadius: 16,
        child: card,
      );
    }

    return card;
  }
}

// ─── Step progress dots ──────────────────────────────────────────────────────

class _StepProgressDots extends StatelessWidget {
  final int total;
  final int completed;
  final Color color;

  const _StepProgressDots({
    required this.total,
    required this.completed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < completed;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: done ? color : AppColors.bgCardLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

