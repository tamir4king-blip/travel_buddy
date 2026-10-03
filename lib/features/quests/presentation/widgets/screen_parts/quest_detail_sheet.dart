part of '../../screens/quests_screen.dart';

// ─── Quest detail sheet ──────────────────────────────────────────────────────

class _QuestDetailSheet extends StatelessWidget {
  final Quest quest;
  final VoidCallback onStart;
  final VoidCallback onAbandon;
  final VoidCallback onClaim;

  const _QuestDetailSheet({
    required this.quest,
    required this.onStart,
    required this.onAbandon,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final color = _QuestChainCard._rarityColor(quest.rarity);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Icon + title
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(quest.icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                quest.rarity.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${quest.xpReward} XP',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.xpGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                quest.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Progress bar
              _StepProgressDots(
                total: quest.totalSteps,
                completed: quest.completedStepCount,
                color: quest.isClaimed
                    ? AppColors.success
                    : quest.isClaimable
                        ? AppColors.gold
                        : color,
              ),
              const SizedBox(height: 6),
              Text(
                '${quest.completedStepCount} of ${quest.totalSteps} steps completed',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              // ── Steps list ──
              const Text(
                'Steps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(quest.steps.length, (i) {
                final step = quest.steps[i];
                final isActive = !step.isCompleted &&
                    (i == 0 || quest.steps[i - 1].isCompleted);
                return _StepTile(
                  step: step,
                  index: i,
                  isActive: isActive,
                  isLast: i == quest.steps.length - 1,
                  color: color,
                );
              }),
              const SizedBox(height: 24),
              // ── Action button ──
              if (!quest.isStarted && !quest.isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: const Text('Start Quest'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              if (quest.isStarted && !quest.isCompleted) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAbandon,
                    icon: Icon(LucideIcons.x, size: 16, color: AppColors.error),
                    label: Text('Abandon Quest',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              // Ready to claim — show claim button
              if (quest.isClaimable)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onClaim,
                    icon: const Icon(LucideIcons.gift, size: 18),
                    label: Text('Claim +${quest.xpReward} XP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              // Already claimed
              if (quest.isClaimed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Completed!',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Step tile ───────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  final QuestStep step;
  final int index;
  final bool isActive;
  final bool isLast;
  final Color color;

  const _StepTile({
    required this.step,
    required this.index,
    required this.isActive,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Circle indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? AppColors.success
                        : isActive
                            ? color
                            : AppColors.bgCardLight,
                    border: Border.all(
                      color: step.isCompleted
                          ? AppColors.success
                          : isActive
                              ? color
                              : AppColors.bgCardLight.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: step.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.isCompleted
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.bgCardLight.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        step.type == QuestStepType.activity
                            ? LucideIcons.compass
                            : LucideIcons.trophy,
                        size: 14,
                        color: step.isCompleted
                            ? AppColors.success
                            : isActive
                                ? color
                                : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: step.isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: step.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (step.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (step.type == QuestStepType.activity
                              ? AppColors.primary
                              : AppColors.gold)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      step.type == QuestStepType.activity ? 'Activity' : 'Achievement',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: step.type == QuestStepType.activity
                            ? AppColors.primary
                            : AppColors.gold,
                      ),
                    ),
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
