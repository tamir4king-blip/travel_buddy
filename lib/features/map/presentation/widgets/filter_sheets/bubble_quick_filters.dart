import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';
import 'package:travel_buddy_mobile/shared/data/quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';

/// Compact card listing the quick filter groups (Achievements, Geographical,
/// Quests, Skills, Activities). Each row has a toggle checkbox showing
/// whether the group has any active filters; tapping the row expands a
/// side panel with the group's individual sub-filters.
class BubbleQuickFilters extends ConsumerStatefulWidget {
  final VoidCallback onOpenAdvanced;
  final VoidCallback onClose;

  const BubbleQuickFilters({
    super.key,
    required this.onOpenAdvanced,
    required this.onClose,
  });

  @override
  ConsumerState<BubbleQuickFilters> createState() =>
      _BubbleQuickFiltersState();
}

class _BubbleQuickFiltersState extends ConsumerState<BubbleQuickFilters> {
  String? _expandedId;

  void _toggleExpanded(String id) {
    HapticFeedback.selectionClick();
    setState(() => _expandedId = _expandedId == id ? null : id);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(mapFilterProvider);
    final notifier = ref.read(mapFilterProvider.notifier);

    final bubbles = <_BubbleSpec>[
      _BubbleSpec(
        id: 'achievements',
        icon: LucideIcons.trophy,
        label: 'Achievements',
        color: AppColors.gold,
        items: _achievementsItems(filter, notifier),
        onClearAll: notifier.clearAchievementFilters,
      ),
      _BubbleSpec(
        id: 'geographical',
        icon: LucideIcons.globe,
        label: 'Geographical',
        color: const Color(0xFFE0A800),
        items: _geographicalItems(filter, notifier),
        onClearAll: () {
          // Clear only the geographical collection ids while preserving
          // any other selected achievement collections.
          final geoIds = _geographicalIds.toSet();
          final remaining = filter.selectedAchievementCollections
              .where((id) => !geoIds.contains(id))
              .toSet();
          notifier.setAchievementCollections(remaining);
        },
      ),
      _BubbleSpec(
        id: 'quests',
        icon: LucideIcons.scroll,
        label: 'Quests',
        color: const Color(0xFF9333EA),
        items: _questsItems(filter, notifier),
        onClearAll: notifier.clearQuestFilters,
      ),
      _BubbleSpec(
        id: 'skills',
        icon: LucideIcons.sparkles,
        label: 'Skills',
        color: AppColors.info,
        items: _skillsItems(filter, notifier),
        onClearAll: () => notifier.clearActivityFilters(),
      ),
      _BubbleSpec(
        id: 'activities',
        icon: LucideIcons.swords,
        label: 'Activities',
        color: AppColors.success,
        items: _activitiesItems(filter, notifier),
        onClearAll: () => notifier.clearActivityFilters(),
      ),
    ];

    final expandedSpec = _expandedId == null
        ? null
        : bubbles.firstWhere(
            (b) => b.id == _expandedId,
            orElse: () => bubbles.first,
          );

    return GestureDetector(
      onTap: () {}, // absorb taps inside the column
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Left: a single compact card with all the quick filter rows.
            // Bottom edge sits the Advanced settings pill — the side panel
            // is anchored top:0/bottom:0 so it spans exactly that height.
            SizedBox(
              width: _bubbleColumnWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textMuted.withValues(alpha: 0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < bubbles.length; i++) ...[
                          _QuickFilterRow(
                            spec: bubbles[i],
                            expanded: _expandedId == bubbles[i].id,
                            onTap: () => _toggleExpanded(bubbles[i].id),
                          ),
                          if (i < bubbles.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.12),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AdvancedSettingsPill(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onOpenAdvanced();
                    },
                  ),
                ],
              ),
            ),
            // Right: side panel showing the expanded group's sub-filters.
            // Bounded to the column's height (top:0/bottom:0) so the list
            // scrolls internally instead of taking over the screen.
            if (expandedSpec != null)
              Positioned(
                top: 0,
                bottom: 0,
                left: _bubbleColumnWidth + 8,
                right: 0,
                child: _SidePanel(
                  spec: expandedSpec,
                  onClose: () => setState(() => _expandedId = null),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const double _bubbleColumnWidth = 168;

  // ── Item builders ──

  // Non-geographical achievement collections (themes, landmarks, etc.).
  static const _achievementIds = <String>[
    'national-parks', 'holy-sites', 'seas', 'lakes', 'glaciers',
    'deserts', 'mountains', 'volcanoes', 'capitals', 'ancient-sites',
    'ski-resorts', 'tourist-destinations',
  ];

  // Geographical / region-based collections (continents and the meta-set).
  static const _geographicalIds = <String>[
    'europe', 'asia', 'africa', 'americas', 'south-america',
    'oceania', 'continents',
  ];

  List<_SubItem> _achievementsItems(
      MapFilterState filter, MapFilterNotifier notifier) {
    return _achievementIds.map((id) {
      final info = getCollectionInfo(id);
      return _SubItem(
        id: id,
        label: info != null ? '${info.icon} ${info.name}' : id,
        active: filter.selectedAchievementCollections.contains(id),
        onTap: () {
          HapticFeedback.selectionClick();
          notifier.toggleAchievementCollection(id);
        },
      );
    }).toList();
  }

  List<_SubItem> _geographicalItems(
      MapFilterState filter, MapFilterNotifier notifier) {
    return _geographicalIds.map((id) {
      final info = getCollectionInfo(id);
      return _SubItem(
        id: id,
        label: info != null ? '${info.icon} ${info.name}' : id,
        active: filter.selectedAchievementCollections.contains(id),
        onTap: () {
          HapticFeedback.selectionClick();
          notifier.toggleAchievementCollection(id);
        },
      );
    }).toList();
  }

  List<_SubItem> _questsItems(
      MapFilterState filter, MapFilterNotifier notifier) {
    const rarities = [
      ('common', '🟢 Common'),
      ('rare', '🔵 Rare'),
      ('epic', '🟣 Epic'),
      ('legendary', '🟡 Legendary'),
    ];
    return rarities.map((r) {
      final (id, label) = r;
      return _SubItem(
        id: id,
        label: label,
        active: filter.selectedQuestChainRarities.contains(id),
        onTap: () {
          HapticFeedback.selectionClick();
          notifier.toggleQuestChainRarity(id);
        },
      );
    }).toList();
  }

  List<_SubItem> _skillsItems(
      MapFilterState filter, MapFilterNotifier notifier) {
    return skillRegistry.map((s) {
      return _SubItem(
        id: s.id,
        label: '${s.icon} ${s.name}',
        active: filter.selectedSkillIds.contains(s.id),
        onTap: () {
          HapticFeedback.selectionClick();
          notifier.toggleSkillId(s.id);
        },
      );
    }).toList();
  }

  List<_SubItem> _activitiesItems(
      MapFilterState filter, MapFilterNotifier notifier) {
    const categoryIcons = <String, String>{
      'adventure': '🏔️',
      'camping': '⛺',
      'cooking': '👨‍🍳',
      'cultural': '🏛️',
      'extreme': '🪂',
      'fishing': '🎣',
      'food-drink': '🍜',
      'hiking': '🥾',
      'nightlife': '🎉',
      'photography': '📸',
      'shopping': '🛍️',
      'skiing': '⛷️',
      'social': '🤝',
      'transportation': '🚂',
      'urban': '🏙️',
      'water-sports': '🏄',
      'wellness': '🧘',
      'wildlife': '🦋',
    };
    return getAllCategories().map((cat) {
      final icon = categoryIcons[cat] ?? '📍';
      final label = cat.replaceAll('-', ' ');
      return _SubItem(
        id: cat,
        label: '$icon ${label[0].toUpperCase()}${label.substring(1)}',
        active: filter.selectedQuestCategories.contains(cat),
        onTap: () {
          HapticFeedback.selectionClick();
          notifier.toggleQuestCategory(cat);
        },
      );
    }).toList();
  }
}

class _BubbleSpec {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final List<_SubItem> items;
  final VoidCallback onClearAll;
  const _BubbleSpec({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.items,
    required this.onClearAll,
  });
}

class _SubItem {
  final String id;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SubItem({
    required this.id,
    required this.label,
    required this.active,
    required this.onTap,
  });
}

/// Single row inside the compact quick-filter card. Toggle checkbox on
/// the left mirrors the sub-item style (filled when the group has any
/// active filters; tapping it clears the group). Tapping the rest of
/// the row expands the side panel with the group's sub-filters.
class _QuickFilterRow extends StatelessWidget {
  final _BubbleSpec spec;
  final bool expanded;
  final VoidCallback onTap;

  const _QuickFilterRow({
    required this.spec,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = spec.items.where((i) => i.active).length;
    final isOn = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: expanded
            ? spec.color.withValues(alpha: 0.10)
            : Colors.transparent,
        child: Row(
          children: [
            // Toggle checkbox — same shape/size as the sub-item rows.
            // Tapping it clears all selections in this group when active.
            GestureDetector(
              onTap: isOn
                  ? () {
                      HapticFeedback.selectionClick();
                      spec.onClearAll();
                    }
                  : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: isOn ? spec.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isOn
                        ? spec.color
                        : AppColors.textMuted.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: isOn
                    ? const Icon(LucideIcons.check,
                        size: 11, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 9),
            Icon(spec.icon, size: 13, color: spec.color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                spec.label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: spec.color,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: expanded ? -0.25 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                LucideIcons.chevronRight,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side panel rendered to the right of the bubble column. Same height as
/// the column (anchored top:0/bottom:0); sub-items scroll internally.
class _SidePanel extends StatelessWidget {
  final _BubbleSpec spec;
  final VoidCallback onClose;

  const _SidePanel({required this.spec, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: spec.color.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 6, 6),
            child: Row(
              children: [
                Icon(spec.icon, size: 12, color: spec.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    spec.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: spec.color,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Plain X close — no encircling background.
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onClose();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: spec.color.withValues(alpha: 0.22),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  vertical: 2, horizontal: 8),
              itemCount: spec.items.length,
              itemBuilder: (_, i) =>
                  _SubItemRow(item: spec.items[i], color: spec.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubItemRow extends StatelessWidget {
  final _SubItem item;
  final Color color;

  const _SubItemRow({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: item.active ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: item.active
                      ? color
                      : AppColors.textMuted.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: item.active
                  ? const Icon(LucideIcons.check,
                      size: 11, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight:
                      item.active ? FontWeight.w700 : FontWeight.w600,
                  color: item.active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedSettingsPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AdvancedSettingsPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.slidersHorizontal,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Advanced settings',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight,
                size: 13, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
