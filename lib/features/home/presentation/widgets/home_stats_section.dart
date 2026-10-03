part of '../screens/home_screen.dart';

// ─── Stats Section ──────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final QuestsState quests;
  final SkillsState skills;
  final AchievementsState achievements;
  final VoidCallback onSkillsTap;
  final VoidCallback onAchievementsTap;

  const _StatsSection({
    required this.quests,
    required this.skills,
    required this.achievements,
    required this.onSkillsTap,
    required this.onAchievementsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Get top skills sorted by level (descending), take top 4
    final topSkillEntries = quests.skillLevels.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSkills = topSkillEntries.take(4).toList();

    // Group achievements by country using id prefix patterns
    // Local Netanya achievements: collectionId in [beaches, landmarks, parks, culture]
    // Travel achievements: collectionId in [europe, americas, national-parks, ski-resorts, ...]
    final localCollections = {'beaches', 'landmarks', 'parks', 'culture'};
    final localAll = achievements.allAchievements
        .where((a) => localCollections.contains(a.collectionId))
        .toList();
    final localUnlocked = localAll.where((a) => a.isUnlocked).length;

    // Country achievements grouped by collectionId
    final countryGroups = <String, ({int unlocked, int total})>{};
    for (final a in achievements.allAchievements) {
      if (localCollections.contains(a.collectionId)) continue;
      if (a.collectionId == null) continue;
      final group = countryGroups[a.collectionId!] ??
          (unlocked: 0, total: 0);
      countryGroups[a.collectionId!] = (
        unlocked: group.unlocked + (a.isUnlocked ? 1 : 0),
        total: group.total + 1,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Skills ──
        _SectionHeader(title: l10n.topSkills),
        const SizedBox(height: 16),
        if (topSkills.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.brain, color: AppColors.textMuted, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.noSkillsYet,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...topSkills.map((entry) {
            final skill = skills.getSkillById(entry.key);
            if (skill == null) return const SizedBox.shrink();
            final level = entry.value;
            final xp = quests.skillXp[entry.key] ?? 0;
            final xpInLevel = xp % skill.xpPerLevel;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkillRow(
                icon: skill.icon,
                name: skill.name,
                level: level,
                xpProgress: xpInLevel / skill.xpPerLevel,
                gradientStart: _parseColor(skill.gradientStart),
                gradientEnd: _parseColor(skill.gradientEnd),
                onTap: onSkillsTap,
              ),
            );
          }),
        if (topSkills.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: onSkillsTap,
              child: Text(
                l10n.seeAll,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),

        // ── Achievement Breakdown ──
        _SectionHeader(title: l10n.achievements),
        const SizedBox(height: 16),

        // Local (Netanya) summary
        _AchievementGroupRow(
          emoji: '\u{1F3D9}\u{FE0F}',
          label: 'Netanya',
          unlocked: localUnlocked,
          total: localAll.length,
          color: AppColors.primary,
          onTap: onAchievementsTap,
        ),

        // Country-based groups
        ..._buildCountryRows(countryGroups, l10n, onAchievementsTap),
      ],
    );
  }

  List<Widget> _buildCountryRows(
    Map<String, ({int unlocked, int total})> groups,
    AppLocalizations l10n,
    VoidCallback onTap,
  ) {
    const collectionMeta = <String, ({String emoji, String label, Color color})>{
      'europe': (emoji: '\u{1F1EA}\u{1F1FA}', label: 'Europe', color: Color(0xFF3B82F6)),
      'americas': (emoji: '\u{1F30E}', label: 'Americas', color: Color(0xFFF59E0B)),
      'national-parks': (emoji: '\u{1F332}', label: 'National Parks', color: Color(0xFF10B981)),
      'ski-resorts': (emoji: '\u{26F7}\u{FE0F}', label: 'Ski Resorts', color: Color(0xFF8B5CF6)),
      'capitals': (emoji: '\u{1F3DB}\u{FE0F}', label: 'Capitals', color: Color(0xFFEF4444)),
      'ancient-sites': (emoji: '\u{1F3DB}\u{FE0F}', label: 'Ancient Sites', color: Color(0xFFB45309)),
      'holy-sites': (emoji: '\u{1F6D0}', label: 'Holy Sites', color: Color(0xFFB07A2E)),
      'seas': (emoji: '\u{1F30A}', label: 'Seas', color: Color(0xFF0277BD)),
      'tourist-destinations': (emoji: '\u{2B50}', label: 'Top Destinations', color: Color(0xFFEC4899)),
    };

    final rows = <Widget>[];
    for (final entry in groups.entries) {
      final meta = collectionMeta[entry.key];
      if (meta == null) continue;
      rows.add(_AchievementGroupRow(
        emoji: meta.emoji,
        label: meta.label,
        unlocked: entry.value.unlocked,
        total: entry.value.total,
        color: meta.color,
        onTap: onTap,
      ));
    }
    return rows;
  }

  static Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _SkillRow extends StatelessWidget {
  final String icon;
  final String name;
  final int level;
  final double xpProgress;
  final Color gradientStart;
  final Color gradientEnd;
  final VoidCallback? onTap;

  const _SkillRow({
    required this.icon,
    required this.name,
    required this.level,
    required this.xpProgress,
    required this.gradientStart,
    required this.gradientEnd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gradientStart.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Lv.$level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: xpProgress,
                      backgroundColor: AppColors.bgCardLight.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(gradientStart),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementGroupRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int unlocked;
  final int total;
  final Color color;
  final VoidCallback? onTap;

  const _AchievementGroupRow({
    required this.emoji,
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? unlocked / total : 0.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$unlocked / $total',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.bgCardLight.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              DirectionalChevron(color: AppColors.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
