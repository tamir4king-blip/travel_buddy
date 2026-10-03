import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quest_chain_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/skills_provider.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';
import 'package:travel_buddy_mobile/shared/widgets/directional_icon.dart';
import 'package:travel_buddy_mobile/shared/widgets/xp_progress_bar.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/widgets/achievement_detail_sheet.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/zone_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/zone_content_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/achievement_unlock_popup.dart';

// Home screen widgets — split out of this file as `part` libraries to keep each
// section focused. They share this file's imports and private scope.
part '../widgets/home_profile_section.dart';
part '../widgets/home_stats_section.dart';
part '../widgets/home_collections_section.dart';
part '../widgets/home_zone_card.dart';
part '../widgets/home_zone_detail_sheet.dart';
part '../widgets/home_pending_claims.dart';

class HomeScreen extends ConsumerStatefulWidget {
  /// When non-null, the dashboard is embedded in the draggable home map
  /// sheet: scrolling is driven by the sheet's controller and the screen
  /// skips its own SafeArea/background chrome.
  final ScrollController? sheetScrollController;

  const HomeScreen({super.key, this.sheetScrollController});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final AnimationController _staggerController;

  // Interval-based animations for each section
  late final Animation<double> _profileFade;
  late final Animation<Offset> _profileSlide;
  late final Animation<double> _adventureFade;
  late final Animation<Offset> _adventureSlide;
  late final Animation<double> _collectionsFade;
  late final Animation<Offset> _collectionsSlide;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _profileFade = _buildFade(0.0, 0.35);
    _profileSlide = _buildSlide(0.0, 0.35);
    _adventureFade = _buildFade(0.25, 0.60);
    _adventureSlide = _buildSlide(0.25, 0.60);
    _collectionsFade = _buildFade(0.45, 0.80);
    _collectionsSlide = _buildSlide(0.45, 0.80);

    _staggerController.forward();
  }

  Animation<double> _buildFade(double begin, double end) {
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _buildSlide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);

    final skills = ref.watch(skillsProvider);
    final gridCols = ResponsiveLayout.gridColumns(context, mobile: 2, tablet: 3, desktop: 4);
    final isComplete = achievements.completedCollections;

    final scrollView = CustomScrollView(
      controller: widget.sheetScrollController,
      slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Unified Profile Unit ──
                      FadeTransition(
                        opacity: _profileFade,
                        child: SlideTransition(
                          position: _profileSlide,
                          child: _ProfileUnit(
                            user: user,
                            currentTotalLevel: quests.skillLevels.values.fold(0, (a, b) => a + b),
                            maxTotalLevel: skillRegistry.fold<int>(0, (sum, g) => sum + g.maxLevel),
                            unlockedAchievements: achievements.totalUnlocked,
                            totalAchievements: achievements.totalAchievements,
                            completedQuests: quests.completedCount,
                            totalQuests: quests.allQuests.length,
                            streakDays: quests.currentStreak,
                            onAvatarTap: () => context.go('/profile'),
                            onSkillsTap: () => context.go('/skills'),
                            onAchievementsTap: () => context.go('/achievements'),
                            onQuestsTap: () => context.go('/quests'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Pending Trophy Claims ──
                      _HomePendingClaims(),

                      const SizedBox(height: 12),

                      // ── Pending Quest Chain Claims ──
                      const _HomeQuestChainClaims(),

                      const SizedBox(height: 20),

                      // ── Nearby Zone Card ──
                      const _NearbyZoneCard(),

                      const SizedBox(height: 20),

                      // ── Your Stats Section ──
                      FadeTransition(
                        opacity: _adventureFade,
                        child: SlideTransition(
                          position: _adventureSlide,
                          child: _StatsSection(
                            quests: quests,
                            skills: skills,
                            achievements: achievements,
                            onSkillsTap: () => context.go('/skills'),
                            onAchievementsTap: () => context.go('/achievements'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Collections Section ──
                      FadeTransition(
                        opacity: _collectionsFade,
                        child: SlideTransition(
                          position: _collectionsSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(title: l10n.yourCollections),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _collectionsFade,
                  child: SlideTransition(
                    position: _collectionsSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CollectionsTabSection(
                        achievements: achievements,
                        completedCollections: isComplete,
                        gridCols: gridCols,
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );

    // Embedded in the home map sheet — the sheet provides the surface and
    // drives scrolling; AnimatedBackground would just paint over it.
    if (widget.sheetScrollController != null) {
      return ResponsiveLayout(child: scrollView);
    }

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primary,
          child: scrollView,
        ),
      ),
    );
  }
}
