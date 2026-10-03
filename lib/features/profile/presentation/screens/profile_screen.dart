import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/auth_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/skills_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/xp_progress_bar.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/top_skills_section.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/recent_achievements_section.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';
import 'package:travel_buddy_mobile/features/dev_panel/presentation/widgets/dev_entry_gesture.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);
    final skills = ref.watch(skillsProvider);
    final locale = Localizations.localeOf(context).languageCode;

    final currentLevelXp = UserProfileNotifier.xpForLevel(user.level);
    final nextLevelXp = UserProfileNotifier.xpForLevel(user.level + 1);
    final xpInLevel = user.totalXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    final xpRemaining = nextLevelXp - user.totalXp;

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primary,
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 1. Avatar with gradient ring
              GlowContainer(
                glowColor: AppColors.primary,
                borderRadius: 50,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.gradientPrimary,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgDark,
                    ),
                    child: ProfileAvatar(
                      avatarUrl: user.avatarUrl,
                      displayName: user.displayName,
                      radius: 48,
                      onTap: () => context.push('/profile/edit'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Display name
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(duration: 400.ms),
              if (user.username != null) ...[
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              if (user.bio != null) ...[
                const SizedBox(height: 8),
                Text(
                  user.bio!,
                  style: const TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],

              // 3. Member since (long-press for dev panel)
              const SizedBox(height: 8),
              if (kDebugMode)
                DevEntryGesture(
                  child: Text(
                    l10n.memberSince(
                      DateFormat.yMMMM(locale).format(user.createdAt),
                    ),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                )
              else
                Text(
                  l10n.memberSince(
                    DateFormat.yMMMM(locale).format(user.createdAt),
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // 4. XP Card
              _XpCard(
                level: user.level,
                totalXp: user.totalXp,
                xpInLevel: xpInLevel,
                xpNeeded: xpNeeded,
                xpRemaining: xpRemaining,
              ),
              const SizedBox(height: 24),

              // 5. Quick Stats Row — 4 items
              Row(
                children: [
                  Expanded(
                    child: ScaleTap(
                      child: _StatChip(
                        label: l10n.achievements,
                        value: achievements.totalUnlocked,
                        icon: LucideIcons.award,
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ScaleTap(
                      child: _StatChip(
                        label: l10n.quests,
                        value: quests.completedCount,
                        icon: LucideIcons.compass,
                        color: AppColors.accent,
                      ),
                    ).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ScaleTap(
                      child: _StatChip(
                        label: l10n.streak,
                        value: quests.currentStreak,
                        displayValue: l10n.streakDays(quests.currentStreak),
                        icon: LucideIcons.flame,
                        color: AppColors.error,
                      ),
                    ).animate(delay: 160.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ScaleTap(
                      child: _StatChip(
                        label: l10n.collections,
                        value: achievements.completedCollections.length,
                        icon: LucideIcons.layers,
                        color: AppColors.info,
                      ),
                    ).animate(delay: 240.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 6. Top Skills section
              _SectionHeader(title: l10n.topSkills),
              const SizedBox(height: 12),
              TopSkillsSection(
                skillXp: quests.skillXp,
                allSkills: skills.allSkills,
              ),

              const SizedBox(height: 20),

              // 7. Recent Achievements section
              _SectionHeader(title: l10n.recentAchievements),
              const SizedBox(height: 12),
              RecentAchievementsSection(
                unlockedAchievements: achievements.unlockedAchievements,
              ),

              const SizedBox(height: 28),

              // 8. Settings sections
              _SettingsSection(
                title: l10n.account,
                items: [
                  _SettingsTile(icon: LucideIcons.userCircle, label: l10n.editProfile, onTap: () => context.push('/profile/edit')),
                  _SettingsTile(icon: LucideIcons.shield, label: l10n.privacySettings, onTap: () => context.push('/profile/privacy')),
                  _SettingsTile(icon: LucideIcons.bell, label: l10n.notifications, onTap: () {}),
                ],
              ),
              const SizedBox(height: 20),
              _SettingsSection(
                title: l10n.preferences,
                items: [
                  _SettingsTile(icon: LucideIcons.languages, label: l10n.language, onTap: () => context.push('/profile/settings')),
                  _SettingsTile(icon: LucideIcons.palette, label: l10n.theme, onTap: () => context.push('/profile/settings')),
                  _SettingsTile(icon: LucideIcons.mapPin, label: l10n.locationSettings, onTap: () => context.push('/profile/settings')),
                ],
              ),
              // Dev Panel (admin only — tamir4king@gmail.com)
              if (SupabaseConfig.isConfigured &&
                  sb.Supabase.instance.client.auth.currentUser?.email ==
                      'tamir4king@gmail.com') ...[
                const SizedBox(height: 20),
                _SettingsSection(
                  title: 'Admin',
                  items: [
                    _SettingsTile(
                      icon: LucideIcons.code,
                      label: 'Dev Panel',
                      onTap: () => context.push('/dev-panel'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _SettingsSection(
                title: l10n.support,
                items: [
                  _SettingsTile(icon: LucideIcons.helpCircle, label: l10n.helpAndFaq, onTap: () {}),
                  _SettingsTile(icon: LucideIcons.messageSquare, label: l10n.feedback, onTap: () {}),
                  _SettingsTile(
                    icon: LucideIcons.logOut,
                    label: l10n.logOut,
                    isDestructive: true,
                    onTap: () {
                      ref.read(persistenceServiceProvider).clearAll();
                      ref.read(authProvider.notifier).signOut();
                      context.go('/auth');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── XP Card ──────────────────────────────────────────────────────────────────

class _XpCard extends StatelessWidget {
  final int level;
  final int totalXp;
  final int xpInLevel;
  final int xpNeeded;
  final int xpRemaining;

  const _XpCard({
    required this.level,
    required this.totalXp,
    required this.xpInLevel,
    required this.xpNeeded,
    required this.xpRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E),
            Color(0xFF0D9488),
            Color(0xFF115E59),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.levelN(level),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap,
                        size: 14, color: AppColors.xpGlow),
                    const SizedBox(width: 4),
                    AnimatedCounter(
                      value: totalXp,
                      suffix: ' XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          XpProgressBar(
            current: xpInLevel.clamp(0, xpNeeded),
            max: xpNeeded > 0 ? xpNeeded : 1,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.xpToNextLevel(xpRemaining.clamp(0, xpRemaining)),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final String? displayValue;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    this.displayValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 8),
          if (displayValue != null)
            Text(
              displayValue!,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            )
          else
            AnimatedCounter(
              value: value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
      ),
    );
  }
}

// ── Settings (kept from original) ────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsTile> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return ScaleTap(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, size: 20, color: color),
        title: Text(label, style: TextStyle(color: color, fontSize: 15)),
        trailing: Icon(
          isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
          size: 18,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
