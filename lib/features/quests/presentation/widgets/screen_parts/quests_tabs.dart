part of '../../screens/quests_screen.dart';

// ─── Tab bar ─────────────────────────────────────────────────────────────────

class _QuestTabs extends StatelessWidget {
  final _QuestTab selected;
  final int activeCount;
  final int claimCount;
  final int availableCount;
  final int completedCount;
  final ValueChanged<_QuestTab> onChanged;

  const _QuestTabs({
    required this.selected,
    required this.activeCount,
    required this.claimCount,
    required this.availableCount,
    required this.completedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tab('Active', activeCount, _QuestTab.active),
          _tab('Claim', claimCount, _QuestTab.claim, highlight: claimCount > 0),
          _tab('Available', availableCount, _QuestTab.available),
          _tab('Done', completedCount, _QuestTab.completed),
        ],
      ),
    );
  }

  Widget _tab(String label, int count, _QuestTab tab, {bool highlight = false}) {
    final isSelected = selected == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: highlight && !isSelected
                      ? AppColors.gold
                      : isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: highlight
                        ? AppColors.gold.withValues(alpha: 0.2)
                        : isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.bgCardLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: highlight
                          ? AppColors.gold
                          : isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

