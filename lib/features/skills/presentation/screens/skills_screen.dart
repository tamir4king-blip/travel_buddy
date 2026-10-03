import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/data/quest_categories.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/skills_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

// Skills screen widgets - split out of this file as `part` libraries to keep
// each section focused. They share this files imports and private scope.
part '../widgets/screen_parts/skills_landing.dart';
part '../widgets/screen_parts/skill_items.dart';
part '../widgets/screen_parts/skills_toolbar.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

enum _ViewMode { categories, allSkills }

class _SkillsScreenState extends ConsumerState<SkillsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Selected super-category (null = landing page).
  QuestSuperCategory? _selectedCategory;
  _ViewMode _viewMode = _ViewMode.categories;
  int _gridColumns = 1;

  void _selectCategory(QuestSuperCategory sc) {
    setState(() => _selectedCategory = sc);
  }

  void _goBack() {
    setState(() => _selectedCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final skillsState = ref.watch(skillsProvider);
    final questsState = ref.watch(questsProvider);

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primaryLight,
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_selectedCategory != null) ...[
                      GestureDetector(
                        onTap: _goBack,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategory != null
                                ? _selectedCategory!.label(locale)
                                : l10n.navSkills,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          GradientText(
                            text: l10n.nSkills(skillsState.allSkills.length),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            gradient: AppGradients.gradientCool,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── View mode & grid toolbar ──
              if (_selectedCategory == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // View mode toggle
                      _ToolbarToggle(
                        options: const ['Categories', 'All Skills'],
                        selectedIndex: _viewMode.index,
                        onChanged: (i) => setState(() {
                          _viewMode = _ViewMode.values[i];
                        }),
                      ),
                      const Spacer(),
                      // Grid columns (only when showing all skills or inside a category)
                      if (_viewMode == _ViewMode.allSkills)
                        _GridColumnPicker(
                          columns: _gridColumns,
                          onChanged: (c) => setState(() => _gridColumns = c),
                        ),
                    ],
                  ),
                ),
              if (_selectedCategory != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _GridColumnPicker(
                        columns: _gridColumns,
                        onChanged: (c) => setState(() => _gridColumns = c),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // ── Content ──
              Expanded(
                child: _selectedCategory != null
                    ? _buildCategorySkills(skillsState, questsState, locale)
                    : _viewMode == _ViewMode.categories
                        ? _SkillsLandingPage(
                            skillsState: skillsState,
                            questsState: questsState,
                            locale: locale,
                            onCategorySelected: _selectCategory,
                          )
                        : _buildAllSkills(skillsState, questsState, locale),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySkills(
    SkillsState skillsState,
    QuestsState questsState,
    Locale locale,
  ) {
    final sc = _selectedCategory!;
    var skills = skillsState.allSkills
        .where((s) => s.categories.any(
            (cat) => sc.questCategories.contains(cat)))
        .toList();

    // Sort by XP (highest first), then alphabetical
    skills.sort((a, b) {
      final xpA = questsState.skillXp[a.id] ?? 0;
      final xpB = questsState.skillXp[b.id] ?? 0;
      if (xpA != xpB) return xpB.compareTo(xpA);
      return a.name.compareTo(b.name);
    });

    return _buildSkillsGrid(skills, questsState, locale);
  }

  Widget _buildAllSkills(
    SkillsState skillsState,
    QuestsState questsState,
    Locale locale,
  ) {
    final skills = List<SkillGroup>.from(skillsState.allSkills);
    skills.sort((a, b) {
      final xpA = questsState.skillXp[a.id] ?? 0;
      final xpB = questsState.skillXp[b.id] ?? 0;
      if (xpA != xpB) return xpB.compareTo(xpA);
      return a.name.compareTo(b.name);
    });
    return _buildSkillsGrid(skills, questsState, locale);
  }

  Widget _buildSkillsGrid(
    List<SkillGroup> skills,
    QuestsState questsState,
    Locale locale,
  ) {
    if (_gridColumns == 1) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: skills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final skill = skills[index];
                final xp = questsState.skillXp[skill.id] ?? 0;
                final level = _levelForSkill(skill, xp);
                final progress = _progressForSkill(skill, xp);
                return _SkillListItem(
                  skill: skill,
                  xp: xp,
                  level: level,
                  progress: progress,
                  locale: locale,
                  onTap: () => context.push('/skills/${skill.id}'),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (index * 60).clamp(0, 600)))
                    .slideY(begin: 0.05);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }

    // Grid layout for 2 or 3 columns
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridColumns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: _gridColumns == 2 ? 0.85 : 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              childCount: skills.length,
              (context, index) {
                final skill = skills[index];
                final xp = questsState.skillXp[skill.id] ?? 0;
                final level = _levelForSkill(skill, xp);
                final progress = _progressForSkill(skill, xp);
                return _SkillGridItem(
                  skill: skill,
                  xp: xp,
                  level: level,
                  progress: progress,
                  locale: locale,
                  onTap: () => context.push('/skills/${skill.id}'),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (index * 40).clamp(0, 400)))
                    .scale(begin: const Offset(0.95, 0.95));
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  int _levelForSkill(SkillGroup skill, int xp) {
    final level = (xp / skill.xpPerLevel).floor() + 1;
    return level.clamp(1, skill.maxLevel);
  }

  double _progressForSkill(SkillGroup skill, int xp) {
    if (skill.xpPerLevel == 0) return 0;
    return (xp % skill.xpPerLevel) / skill.xpPerLevel;
  }

}

