import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievement_definitions_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';

class AchievementEditorScreen extends ConsumerStatefulWidget {
  const AchievementEditorScreen({super.key});

  @override
  ConsumerState<AchievementEditorScreen> createState() =>
      _AchievementEditorScreenState();
}

class _AchievementEditorScreenState
    extends ConsumerState<AchievementEditorScreen> {
  String _search = '';
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider);
    final filtered = achievements.allAchievements.where((a) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return a.title.toLowerCase().contains(q) ||
          a.id.toLowerCase().contains(q) ||
          (a.collectionId?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement Editor',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(achievementsProvider.notifier).unlockAll();
            },
            child: const Text('Unlock All',
                style: TextStyle(color: AppColors.success, fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              ref.read(achievementsProvider.notifier).lockAll();
            },
            child: const Text('Lock All',
                style: TextStyle(color: AppColors.error, fontSize: 12)),
          ),
          IconButton(
            onPressed: () {
              ref.read(achievementDefinitionsProvider.notifier).refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing definitions...')),
              );
            },
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            tooltip: 'Sync from Supabase',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search achievements...',
                prefixIcon: Icon(LucideIcons.search, size: 18),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${achievements.totalUnlocked}/${achievements.totalAchievements} unlocked',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final a = filtered[index];
                final isExpanded = _expandedId == a.id;
                return _AchievementTile(
                  achievement: a,
                  isExpanded: isExpanded,
                  onToggle: () => setState(() {
                    _expandedId = isExpanded ? null : a.id;
                  }),
                  onForceUnlock: () =>
                      ref.read(achievementsProvider.notifier).forceUnlock(a.id),
                  onForceLock: () =>
                      ref.read(achievementsProvider.notifier).forceLock(a.id),
                  onRadiusChanged: (r) => ref
                      .read(achievementsProvider.notifier)
                      .updateAchievementRadius(a.id, r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatefulWidget {
  final Achievement achievement;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onForceUnlock;
  final VoidCallback onForceLock;
  final ValueChanged<double> onRadiusChanged;

  const _AchievementTile({
    required this.achievement,
    required this.isExpanded,
    required this.onToggle,
    required this.onForceUnlock,
    required this.onForceLock,
    required this.onRadiusChanged,
  });

  @override
  State<_AchievementTile> createState() => _AchievementTileState();
}

class _AchievementTileState extends State<_AchievementTile> {
  late double _radius;

  @override
  void initState() {
    super.initState();
    _radius = widget.achievement.claimRadius ?? 200;
  }

  @override
  void didUpdateWidget(_AchievementTile old) {
    super.didUpdateWidget(old);
    if (old.achievement.claimRadius != widget.achievement.claimRadius) {
      _radius = widget.achievement.claimRadius ?? 200;
    }
  }

  Color get _tierColor => switch (widget.achievement.tier) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platinum => AppColors.platinum,
      };

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: a.isUnlocked
            ? Border.all(color: AppColors.success.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tierColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                          '${a.tier.name} • ${a.xpReward} XP • ${a.hasPolygon ? "polygon (${a.claimPolygon!.length}pts)" : "${a.claimRadius?.toInt() ?? 0}m"}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (a.isUnlocked)
                    const Icon(LucideIcons.checkCircle,
                        size: 16, color: AppColors.success)
                  else
                    const Icon(LucideIcons.lock,
                        size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Icon(
                    widget.isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (widget.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.bgCardLight),
                  const SizedBox(height: 12),
                  // Claim radius slider
                  Row(
                    children: [
                      const Text('Radius:',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _radius,
                          min: 50,
                          max: 1000,
                          divisions: 19,
                          label: '${_radius.toInt()}m',
                          onChanged: (v) => setState(() => _radius = v),
                          onChangeEnd: widget.onRadiusChanged,
                        ),
                      ),
                      Text('${_radius.toInt()}m',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Info row
                  Text(
                    'ID: ${a.id}\nCollection: ${a.collectionId ?? "none"}\nCoords: ${a.latitude?.toStringAsFixed(4)}, ${a.longitude?.toStringAsFixed(4)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              a.isUnlocked ? null : widget.onForceUnlock,
                          icon: const Icon(LucideIcons.unlock, size: 14),
                          label: const Text('Force Claim',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            disabledBackgroundColor:
                                AppColors.bgCardLight,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              a.isUnlocked ? widget.onForceLock : null,
                          icon: const Icon(LucideIcons.lock, size: 14),
                          label: const Text('Force Unclaim',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            disabledBackgroundColor:
                                AppColors.bgCardLight,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (a.latitude != null && a.longitude != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/dev-panel/polygon-editor'),
                        icon: Icon(LucideIcons.hexagon, size: 14),
                        label: Text(
                          a.hasPolygon
                              ? 'Edit Polygon (${a.claimPolygon!.length} vertices)'
                              : 'Draw Polygon',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
