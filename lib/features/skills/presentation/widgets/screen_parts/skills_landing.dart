part of '../../screens/skills_screen.dart';

// ─── Skills Landing Page ──────────────────────────────────────────────────────

class _SkillsLandingPage extends StatelessWidget {
  final SkillsState skillsState;
  final QuestsState questsState;
  final Locale locale;
  final ValueChanged<QuestSuperCategory> onCategorySelected;

  const _SkillsLandingPage({
    required this.skillsState,
    required this.questsState,
    required this.locale,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: questSuperCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sc = questSuperCategories[index];
        final skills = skillsState.allSkills
            .where((s) => s.categories.any(
                (cat) => sc.questCategories.contains(cat)))
            .toList();
        final totalXp = skills.fold<int>(
            0, (sum, s) => sum + (questsState.skillXp[s.id] ?? 0));

        return _CategoryCard(
          superCategory: sc,
          skillCount: skills.length,
          totalXp: totalXp,
          locale: locale,
          onTap: () => onCategorySelected(sc),
          index: index,
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final QuestSuperCategory superCategory;
  final int skillCount;
  final int totalXp;
  final Locale locale;
  final VoidCallback onTap;
  final int index;

  const _CategoryCard({
    required this.superCategory,
    required this.skillCount,
    required this.totalXp,
    required this.locale,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.bgCard,
          border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: superCategory.color.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: superCategory.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    superCategory.icon,
                    size: 24,
                    color: superCategory.color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      superCategory.label(locale),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.nSkills(skillCount)}  •  $totalXp XP',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chevron
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05);
  }
}

