import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/area_colors.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';
import 'package:travel_buddy_mobile/shared/data/quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';

// Unified filter sheet sub-widgets - split out of this file as `part`
// libraries. They share this files imports and private scope.
part 'screen_parts/filter_section_widgets.dart';
part 'screen_parts/filter_chip_grid.dart';
part 'screen_parts/filter_achievement_groups.dart';

const _categoryIcons = <String, String>{
  'adventure': '\u{1F3D4}\uFE0F',
  'camping': '\u26FA',
  'cooking': '\u{1F468}\u200D\u{1F373}',
  'cultural': '\u{1F3DB}\uFE0F',
  'extreme': '\u{1FA82}',
  'fishing': '\u{1F3A3}',
  'food-drink': '\u{1F35C}',
  'hiking': '\u{1F97E}',
  'nightlife': '\u{1F389}',
  'photography': '\u{1F4F8}',
  'shopping': '\u{1F6CD}\uFE0F',
  'skiing': '\u26F7\uFE0F',
  'social': '\u{1F91D}',
  'transportation': '\u{1F682}',
  'urban': '\u{1F3D9}\uFE0F',
  'water-sports': '\u{1F3C4}',
  'wellness': '\u{1F9D8}',
  'wildlife': '\u{1F98B}',
};

const _rarities = [
  ('common', 'Common', Color(0xFF22C55E)),
  ('rare', 'Rare', Color(0xFF3B82F6)),
  ('epic', 'Epic', Color(0xFF9333EA)),
  ('legendary', 'Legendary', Color(0xFFEAB308)),
];

/// Achievement collections that represent individual countries. Used by
/// the "Countries" quick filter to toggle them as a group.
const _kCountryCollectionIds = <String>[
  'europe',
  'africa',
  'asia',
  'americas',
  'south-america',
  'oceania',
];

/// Toggle a whole group of achievement collections at once — if all are
/// selected, remove them; otherwise add all of them.
void _toggleCollectionGroup(
  MapFilterNotifier notifier,
  MapFilterState filter,
  List<String> ids,
) {
  final current = Set<String>.from(filter.selectedAchievementCollections);
  final allIn = ids.every(current.contains);
  if (allIn) {
    current.removeAll(ids);
  } else {
    current.addAll(ids);
  }
  notifier.setAchievementCollections(current);
}

/// Unified filter sheet showing all map filter categories in one scrollable view.
class UnifiedFilterSheet extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const UnifiedFilterSheet({super.key, this.onClose});

  @override
  ConsumerState<UnifiedFilterSheet> createState() => _UnifiedFilterSheetState();
}

class _UnifiedFilterSheetState extends ConsumerState<UnifiedFilterSheet> {
  // The advanced sheet now opens directly from the bubble column's
  // "Advanced settings" entry, so the detailed sections expand by default.
  bool _advancedExpanded = true;
  bool _achievementsExpanded = false;
  bool _activitiesExpanded = false;
  bool _questsExpanded = false;
  bool _groupsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(mapFilterProvider);
    final notifier = ref.read(mapFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header: title + Reset all + X close ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 10, 4),
          child: Row(
            children: [
              const Icon(LucideIcons.slidersHorizontal,
                  size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              const Text(
                'Map Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (filter.hasActiveFilters)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.resetAll();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reset all',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onClose?.call();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgCardLight.withValues(alpha: 0.5),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Quick filters: 2-column grid (advanced sheet keeps the
        // common toggles handy alongside the detailed sections below). ──
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
          child: _QuickFilterGrid(
            rows: [
              _QuickFilterRowData(
                icon: LucideIcons.unlock,
                label: 'Only unlocked',
                color: AppColors.success,
                active: filter.showOnlyUnlocked,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleShowOnlyUnlocked();
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.flag,
                label: 'Countries',
                color: AppColors.gold,
                active: _kCountryCollectionIds
                    .every(filter.selectedAchievementCollections.contains),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _toggleCollectionGroup(
                      notifier, filter, _kCountryCollectionIds);
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.globe,
                label: 'Continents',
                color: AppColors.gold,
                active: filter.selectedAchievementCollections
                    .contains('continents'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('continents');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.trees,
                label: 'National parks',
                color: AppColors.success,
                active: filter.selectedAchievementCollections
                    .contains('national-parks'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('national-parks');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.church,
                label: 'Holy sites',
                color: const Color(0xFFB07A2E),
                active: filter.selectedAchievementCollections
                    .contains('holy-sites'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('holy-sites');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.waves,
                label: 'Seas',
                color: const Color(0xFF0277BD),
                active: filter.selectedAchievementCollections
                    .contains('seas'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('seas');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.droplet,
                label: 'Lakes',
                color: const Color(0xFF1E88E5),
                active: filter.selectedAchievementCollections
                    .contains('lakes'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('lakes');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.snowflake,
                label: 'Glaciers & Ice',
                color: const Color(0xFF80DEEA),
                active: filter.selectedAchievementCollections
                    .contains('glaciers'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('glaciers');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.sun,
                label: 'Deserts',
                color: const Color(0xFFE6A85C),
                active: filter.selectedAchievementCollections
                    .contains('deserts'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('deserts');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.scroll,
                label: 'Quests',
                color: const Color(0xFF9333EA),
                active: filter.showQuestChains,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleQuestChains();
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.sparkles,
                label: 'Skills',
                color: AppColors.info,
                active: filter.showSkills,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleSkills();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 2),
        _sectionDivider(),

        // ── "Advanced filters" disclosure ──
        // Collapsed by default — the quick filter column above covers the
        // common cases. Tap to reveal the detailed Achievements /
        // Activities / Quests sections.
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _advancedExpanded = !_advancedExpanded);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                Icon(LucideIcons.slidersHorizontal,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Advanced filters',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _advancedExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_advancedExpanded) ...[
        // ── Achievements Section ──
        _SectionHeader(
          icon: LucideIcons.trophy,
          label: 'Achievements',
          color: AppColors.gold,
          visible: filter.showAchievements,
          filterCount: filter.selectedAchievementCollections.length,
          onToggleVisibility: () {
            HapticFeedback.selectionClick();
            notifier.toggleAchievements();
          },
          onClear: filter.selectedAchievementCollections.isNotEmpty
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.clearAchievementFilters();
                }
              : null,
          expanded: _achievementsExpanded,
          onToggleExpanded: () {
            HapticFeedback.selectionClick();
            setState(() => _achievementsExpanded = !_achievementsExpanded);
          },
        ),
        if (_achievementsExpanded && filter.showAchievements)
          _AchievementFilterGroups(
            selected: filter.selectedAchievementCollections,
            onToggle: (id) {
              HapticFeedback.selectionClick();
              notifier.toggleAchievementCollection(id);
            },
          ),

        // Per-collection "Display groups" toggles — collapsible, one row
        // per collection that has at least one unlocked polygon-backed
        // member. Each enabled collection draws every member polygon
        // individually (no merging/hulling).
        if (_achievementsExpanded && filter.showAchievements)
          _UnlockedAreaCollectionToggles(
            selected: filter.unlockedAreaCollections,
            expanded: _groupsExpanded,
            onToggleExpanded: () {
              HapticFeedback.selectionClick();
              setState(() => _groupsExpanded = !_groupsExpanded);
            },
            onToggle: (id) {
              HapticFeedback.selectionClick();
              notifier.toggleUnlockedAreaCollection(id);
            },
            onClearAll: filter.unlockedAreaCollections.isNotEmpty
                ? () {
                    HapticFeedback.selectionClick();
                    notifier.clearUnlockedAreaCollections();
                  }
                : null,
          ),

        _sectionDivider(),

        // ── Activities Section ──
        _SectionHeader(
          icon: LucideIcons.swords,
          label: 'Activities',
          color: AppColors.success,
          visible: filter.showQuests,
          filterCount: filter.selectedQuestCategories.length,
          onToggleVisibility: () {
            HapticFeedback.selectionClick();
            notifier.toggleQuests();
          },
          onClear: filter.selectedQuestCategories.isNotEmpty
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.clearActivityFilters();
                }
              : null,
          expanded: _activitiesExpanded,
          onToggleExpanded: () {
            HapticFeedback.selectionClick();
            setState(() => _activitiesExpanded = !_activitiesExpanded);
          },
        ),
        if (_activitiesExpanded && filter.showQuests) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          _ChipGrid(
            items: getAllCategories().map((cat) {
              final icon = _categoryIcons[cat] ?? '\u{1F4CD}';
              final label = cat.replaceAll('-', ' ');
              return _ChipData(
                id: cat,
                label: '$icon ${label[0].toUpperCase()}${label.substring(1)}',
                selected: filter.selectedQuestCategories.contains(cat),
              );
            }).toList(),
            color: AppColors.success,
            onTap: (id) {
              HapticFeedback.selectionClick();
              notifier.toggleQuestCategory(id);
            },
          ),
          // Skills merged into Activities — only shown when Activities is
          // expanded AND skills are visible.
          if (filter.showSkills) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles,
                      size: 12, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (filter.selectedSkillIds.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${filter.selectedSkillIds.length}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _ChipGrid(
              items: skillRegistry
                  .map((s) => _ChipData(
                        id: s.id,
                        label: '${s.icon} ${s.name}',
                        selected: filter.selectedSkillIds.contains(s.id),
                      ))
                  .toList(),
              color: AppColors.info,
              onTap: (id) {
                HapticFeedback.selectionClick();
                notifier.toggleSkillId(id);
              },
            ),
          ],
        ],

        _sectionDivider(),

        // ── Quests Section ──
        _SectionHeader(
          icon: LucideIcons.scroll,
          label: 'Quests',
          color: const Color(0xFF9333EA),
          visible: filter.showQuestChains,
          filterCount: filter.selectedQuestChainRarities.length,
          onToggleVisibility: () {
            HapticFeedback.selectionClick();
            notifier.toggleQuestChains();
          },
          onClear: filter.selectedQuestChainRarities.isNotEmpty
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.clearQuestFilters();
                }
              : null,
          expanded: _questsExpanded,
          onToggleExpanded: () {
            HapticFeedback.selectionClick();
            setState(() => _questsExpanded = !_questsExpanded);
          },
        ),
        if (_questsExpanded && filter.showQuestChains)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: _rarities.map((r) {
                final (id, label, color) = r;
                final isSelected =
                    filter.selectedQuestChainRarities.contains(id);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: id != 'legendary' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        notifier.toggleQuestChainRarity(id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : AppColors.bgCardLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? color.withValues(alpha: 0.5)
                                : AppColors.textMuted.withValues(alpha: 0.15),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -2,
                                    right: -10,
                                    child: Icon(LucideIcons.check,
                                        size: 10, color: color),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ], // end of _advancedExpanded block

        const SizedBox(height: 8),
      ],
    );
  }

  static Widget _sectionDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Divider(
          color: AppColors.textMuted.withValues(alpha: 0.12),
          height: 1,
        ),
      );
}

