part of '../unified_filter_sheet.dart';

/// Organizes the ~17 achievement collections into four expandable groups:
/// Local, Themed, Countries, Global. Each group header shows its name,
/// icon, and how many filters are currently active inside it.
class _AchievementFilterGroups extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _AchievementFilterGroups({
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_AchievementFilterGroups> createState() =>
      _AchievementFilterGroupsState();
}

class _AchievementFilterGroupsState extends State<_AchievementFilterGroups> {
  String? _expanded; // group id currently expanded

  static const _groups = <_FilterGroup>[
    _FilterGroup(
      id: 'local',
      label: 'Local',
      icon: LucideIcons.landmark,
      collectionIds: ['landmarks', 'beaches', 'parks', 'culture'],
    ),
    _FilterGroup(
      id: 'themed',
      label: 'Themed',
      icon: LucideIcons.star,
      collectionIds: [
        'national-parks', 'ski-resorts', 'capitals',
        'ancient-sites', 'holy-sites', 'seas', 'lakes', 'mountains',
        'volcanoes', 'glaciers', 'deserts', 'tourist-destinations',
      ],
    ),
    _FilterGroup(
      id: 'countries',
      label: 'Countries',
      icon: LucideIcons.flag,
      collectionIds: [
        'europe', 'asia', 'africa', 'americas', 'south-america', 'oceania',
      ],
    ),
    _FilterGroup(
      id: 'global',
      label: 'Global',
      icon: LucideIcons.globe,
      collectionIds: ['continents', 'zones'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final group in _groups) ...[
            _buildGroup(group),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildGroup(_FilterGroup group) {
    final isExpanded = _expanded == group.id;
    final activeCount =
        group.collectionIds.where(widget.selected.contains).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = isExpanded ? null : group.id);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: activeCount > 0
                    ? AppColors.gold.withValues(alpha: 0.10)
                    : AppColors.bgCardLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(10),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(10),
                ),
                border: Border.all(
                  color: activeCount > 0
                      ? AppColors.gold.withValues(alpha: 0.3)
                      : AppColors.bgCardLight.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(group.icon,
                      size: 14,
                      color: activeCount > 0
                          ? AppColors.gold
                          : AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          // Collapsible body
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 160),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.bgCardLight.withValues(alpha: 0.25),
                border: Border.all(
                  color: AppColors.bgCardLight.withValues(alpha: 0.4),
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: group.collectionIds.map((id) {
                  final info = getCollectionInfo(id);
                  if (info == null) return const SizedBox.shrink();
                  final selected = widget.selected.contains(id);
                  return GestureDetector(
                    onTap: () => widget.onToggle(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.gold.withValues(alpha: 0.5)
                              : AppColors.textMuted.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            Icon(LucideIcons.check,
                                size: 11, color: AppColors.gold),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${info.icon} ${info.name}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _FilterGroup {
  final String id;
  final String label;
  final IconData icon;
  final List<String> collectionIds;
  const _FilterGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.collectionIds,
  });
}

/// Per-collection "Display groups" toggles. Only collections that have at
/// least one unlocked polygon-backed achievement are shown, so the list
/// stays meaningful. Collapsible via a chevron on the header row.
class _UnlockedAreaCollectionToggles extends ConsumerWidget {
  final Set<String> selected;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final void Function(String collectionId) onToggle;
  final VoidCallback? onClearAll;

  const _UnlockedAreaCollectionToggles({
    required this.selected,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onToggle,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);

    final counts = <String, int>{};
    for (final a in achievements.allAchievements) {
      if (!a.isUnlocked) continue;
      if (!a.hasPolygon) continue;
      final cid = a.collectionId;
      if (cid == null) continue;
      counts[cid] = (counts[cid] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    final collections = collectionRegistry
        .where((c) => counts.containsKey(c.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(LucideIcons.layers,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Display groups',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (selected.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${selected.length}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (onClearAll != null) ...[
                  GestureDetector(
                    onTap: onClearAll,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
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
          if (!expanded) const SizedBox(height: 4),
          if (expanded) const SizedBox(height: 8),
          if (expanded)
            Column(
            children: collections.map((c) {
              final isOn = selected.contains(c.id);
              final count = counts[c.id] ?? 0;
              final accent = colorForCollection(c.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => onToggle(c.id),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn
                          ? accent.withValues(alpha: 0.14)
                          : AppColors.bgCardLight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOn
                            ? accent.withValues(alpha: 0.5)
                            : AppColors.bgCardLight.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: isOn ? 0.9 : 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(c.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isOn ? FontWeight.w700 : FontWeight.w600,
                              color: isOn
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isOn,
                          onChanged: (_) => onToggle(c.id),
                          activeThumbColor: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


