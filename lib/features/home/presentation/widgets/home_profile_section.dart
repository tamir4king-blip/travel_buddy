part of '../screens/home_screen.dart';

// ─── Section Header with Gradient Accent Bar ─────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.cyan],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ],
    );
  }
}

// ─── Unified Profile Unit ───────────────────────────────────────────────────

class _ProfileUnit extends StatelessWidget {
  final UserProfile user;
  final int currentTotalLevel;
  final int maxTotalLevel;
  final int unlockedAchievements;
  final int totalAchievements;
  final int completedQuests;
  final int totalQuests;
  final int streakDays;
  final VoidCallback onAvatarTap;
  final VoidCallback onSkillsTap;
  final VoidCallback onAchievementsTap;
  final VoidCallback onQuestsTap;

  const _ProfileUnit({
    required this.user,
    required this.currentTotalLevel,
    required this.maxTotalLevel,
    required this.unlockedAchievements,
    required this.totalAchievements,
    required this.completedQuests,
    required this.totalQuests,
    required this.streakDays,
    required this.onAvatarTap,
    required this.onSkillsTap,
    required this.onAchievementsTap,
    required this.onQuestsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final xpInLevel = user.totalXp % 200;
    final xpNeeded = 200 - xpInLevel;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E),  // teal-700
            Color(0xFF0D9488),  // teal-600
            Color(0xFF115E59),  // teal-800
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background trophy icon
          Positioned(
            right: -8,
            top: 10,
            child: Icon(
              LucideIcons.trophy,
              size: 90,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar row: greeting + avatar ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientText(
                            text: l10n.welcomeBack,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF472B6)],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.displayName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.cyan],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF115E59),
                              ),
                              child: ProfileAvatar(
                                avatarUrl: user.avatarUrl,
                                displayName: user.displayName,
                                radius: 26,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.levelN(user.level),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── XP progress ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.xpToNextLevel(xpNeeded),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ShimmerOverlay(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.zap, size: 13, color: AppColors.xpGlow),
                            const SizedBox(width: 4),
                            AnimatedCounter(
                              value: user.totalXp,
                              suffix: ' XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${user.level}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: XpProgressBar(current: xpInLevel, max: 200)),
                    const SizedBox(width: 8),
                    Text(
                      '${user.level + 1}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Divider ──
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Progress stats row ──
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStatTile(
                        label: l10n.totalSkillLevel,
                        value: '$currentTotalLevel/$maxTotalLevel',
                        icon: LucideIcons.brain,
                        color: AppColors.xpGlow,
                        onTap: onSkillsTap,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _ProfileStatTile(
                        label: l10n.achievements,
                        value: '$unlockedAchievements/$totalAchievements',
                        icon: LucideIcons.trophy,
                        color: AppColors.purple,
                        onTap: onAchievementsTap,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _ProfileStatTile(
                        label: l10n.quests,
                        value: '$completedQuests/$totalQuests',
                        icon: LucideIcons.swords,
                        color: AppColors.accent,
                        onTap: onQuestsTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProfileStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
