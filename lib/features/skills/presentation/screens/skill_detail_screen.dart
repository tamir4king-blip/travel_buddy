import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

class SkillDetailScreen extends ConsumerStatefulWidget {
  final String skillId;
  const SkillDetailScreen({super.key, required this.skillId});

  @override
  ConsumerState<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends ConsumerState<SkillDetailScreen> {
  /// Zone labels keyed by cluster index.
  final Map<int, String> _zoneLabels = {};
  bool _labelsLoaded = false;

  SkillGroup? get _skill {
    try {
      return skillRegistry.firstWhere((s) => s.id == widget.skillId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Kick off reverse-geocoding after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveZoneLabels());
  }

  // ── Zone clustering ────────────────────────────────────────────────────────

  /// A quest paired with a specific location point.
  /// One quest can produce multiple entries if it has multiple locations.
  static List<({SideQuest quest, double lat, double lng})> _expandLocations(
      List<SideQuest> quests) {
    final points = <({SideQuest quest, double lat, double lng})>[];
    for (final q in quests) {
      final locs = q.allLocations;
      if (locs.isEmpty) {
        // No location at all — will go to "Anywhere" cluster.
        continue;
      }
      for (final loc in locs) {
        points.add((quest: q, lat: loc.latitude, lng: loc.longitude));
      }
    }
    return points;
  }

  /// Groups quests by geographic proximity (50 km threshold).
  /// An activity with multiple locations appears in multiple clusters.
  /// Returns clusters of unique quests + a centroid per cluster.
  static List<_ZoneCluster> _clusterByZone(List<SideQuest> quests) {
    final points = _expandLocations(quests);
    final noCoords = quests.where((q) => q.allLocations.isEmpty).toList();

    const thresholdMeters = 50000.0; // 50 km
    final clusters = <_ZoneCluster>[];
    final assigned = <int>{};

    for (var i = 0; i < points.length; i++) {
      if (assigned.contains(i)) continue;
      final clusterPts = [points[i]];
      assigned.add(i);

      for (var j = i + 1; j < points.length; j++) {
        if (assigned.contains(j)) continue;
        final dist = Geolocator.distanceBetween(
          points[i].lat, points[i].lng,
          points[j].lat, points[j].lng,
        );
        if (dist <= thresholdMeters) {
          clusterPts.add(points[j]);
          assigned.add(j);
        }
      }

      // Deduplicate quests within the cluster
      final seen = <String>{};
      final uniqueQuests = <SideQuest>[];
      for (final pt in clusterPts) {
        if (seen.add(pt.quest.id)) uniqueQuests.add(pt.quest);
      }

      // Compute centroid
      final lat = clusterPts.map((p) => p.lat).reduce((a, b) => a + b) /
          clusterPts.length;
      final lng = clusterPts.map((p) => p.lng).reduce((a, b) => a + b) /
          clusterPts.length;

      clusters.add(_ZoneCluster(
        quests: uniqueQuests,
        centroid: (lat, lng),
        hasCoords: true,
      ));
    }

    if (noCoords.isNotEmpty) {
      clusters.add(_ZoneCluster(
        quests: noCoords,
        centroid: null,
        hasCoords: false,
      ));
    }
    return clusters;
  }

  Future<void> _resolveZoneLabels() async {
    final skill = _skill;
    if (skill == null) return;
    final quests = ref.read(questsProvider).allQuests
        .where((q) => q.skillType == skill.id)
        .toList();
    final clusters = _clusterByZone(quests);

    for (var i = 0; i < clusters.length; i++) {
      final c = clusters[i].centroid;
      if (c == null) {
        _zoneLabels[i] = 'Anywhere';
        continue;
      }
      try {
        final placemarks = await placemarkFromCoordinates(c.$1, c.$2);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final city = p.locality ?? p.subAdministrativeArea ?? '';
          final country = p.country ?? '';
          _zoneLabels[i] = city.isNotEmpty ? '$city, $country' : country;
        } else {
          _zoneLabels[i] = '${c.$1.toStringAsFixed(1)}°, ${c.$2.toStringAsFixed(1)}°';
        }
      } catch (e, st) {
        // Geocoding failed (offline / rate-limited) — fall back to coords.
        logError(e, st, context: 'skillDetail.geocodeZone');
        _zoneLabels[i] = '${c.$1.toStringAsFixed(1)}°, ${c.$2.toStringAsFixed(1)}°';
      }
    }

    if (mounted) setState(() => _labelsLoaded = true);
  }

  // ── Zone marker colours (one per zone, cycling) ────────────────────────────

  static const _zoneColors = [
    Color(0xFF0EA5E9), // sky
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // emerald
    Color(0xFFF43F5E), // rose
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFEC4899), // pink
  ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final skill = _skill;
    if (skill == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Skill not found')),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final questsState = ref.watch(questsProvider);
    final xp = questsState.skillXp[skill.id] ?? 0;
    final level = _levelForSkill(skill, xp);
    final progress = _progressForSkill(skill, xp);
    final xpInLevel = xp % skill.xpPerLevel;
    final gradientStart = _parseColor(skill.gradientStart);
    final gradientEnd = _parseColor(skill.gradientEnd);

    // Related quests for this skill
    final relatedQuests = questsState.allQuests
        .where((q) => q.skillType == skill.id)
        .toList();
    final completedCount = relatedQuests.where((q) => q.isCompleted).length;
    final clusters = _clusterByZone(relatedQuests);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientStart.withValues(alpha: 0.25),
                      gradientEnd.withValues(alpha: 0.08),
                      AppColors.bgDark,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      GlowContainer(
                        glowColor: gradientStart,
                        borderRadius: 22,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [gradientStart, gradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(skill.icon, style: const TextStyle(fontSize: 34)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        RegistryL10n.skillName(locale, skill.id, skill.name),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Level + XP row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: gradientStart.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.lvN(level),
                              style: TextStyle(
                                color: gradientStart,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$xpInLevel / ${skill.xpPerLevel} XP',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: SizedBox(
                          height: 6,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth * progress;
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.bgCardLight.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: 700.ms,
                                    curve: Curves.easeOutCubic,
                                    width: w,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stats summary ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  _StatChip(
                    icon: LucideIcons.compass,
                    label: 'Activities',
                    value: '${relatedQuests.length}',
                    color: gradientStart,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    icon: LucideIcons.checkCircle2,
                    label: 'Completed',
                    value: '$completedCount',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    icon: LucideIcons.mapPin,
                    label: 'Zones',
                    value: '${clusters.length}',
                    color: _zoneColors[0],
                  ),
                ],
              ),
            ),
          ),

          // ── Zone sections ──
          ...List.generate(clusters.length, (zoneIdx) {
            final cluster = clusters[zoneIdx];
            final zoneColor = _zoneColors[zoneIdx % _zoneColors.length];
            final label = _labelsLoaded
                ? (_zoneLabels[zoneIdx] ?? 'Zone ${zoneIdx + 1}')
                : 'Loading…';
            final hasCoords = cluster.hasCoords;

            return SliverMainAxisGroup(
              slivers: [
                // Zone header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: zoneColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: zoneColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          hasCoords ? LucideIcons.mapPin : LucideIcons.globe,
                          size: 16,
                          color: zoneColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: zoneColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: zoneColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${cluster.quests.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: zoneColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: (zoneIdx * 80).ms),
                ),
                // Activity cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: cluster.quests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final quest = cluster.quests[i];
                      final unlocked = quest.isUnlocked(
                        skillLevels: questsState.skillLevels,
                        allQuests: questsState.allQuests,
                      );
                      return _ActivityCard(
                        quest: quest,
                        locale: locale,
                        zoneColor: zoneColor,
                        isUnlocked: unlocked,
                        onTap: () => context.push(
                          '/skills/${widget.skillId}/activity/${quest.id}',
                        ),
                      )
                          .animate()
                          .fadeIn(
                            duration: 350.ms,
                            delay: Duration(milliseconds: (zoneIdx * 80 + i * 50).clamp(0, 600)),
                          )
                          .slideY(begin: 0.04);
                    },
                  ),
                ),
              ],
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
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

  static Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

// ─── Zone cluster ────────────────────────────────────────────────────────────

class _ZoneCluster {
  final List<SideQuest> quests;
  final (double, double)? centroid;
  final bool hasCoords;

  const _ZoneCluster({
    required this.quests,
    required this.centroid,
    required this.hasCoords,
  });
}

// ─── Stat chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: color,
            )),
            Text(label, style: const TextStyle(
              fontSize: 11, color: AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Activity card ───────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final SideQuest quest;
  final Locale locale;
  final Color zoneColor;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.quest,
    required this.locale,
    required this.zoneColor,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(quest.difficulty);

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: quest.isCompleted
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.bgCardLight.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            // Zone color bar
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: zoneColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Status icon
            _statusIcon(),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RegistryL10n.questTitle(locale, quest.id, quest.title),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _pill(quest.difficulty.name, diffColor),
                      const SizedBox(width: 6),
                      _pill('+${quest.xpReward} XP', AppColors.xpGreen),
                      if (quest.isRepeatable) ...[
                        const SizedBox(width: 6),
                        _pill('${quest.completionCount}/${quest.maxCompletions}', AppColors.textMuted),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isUnlocked)
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? LucideIcons.chevronLeft
                    : LucideIcons.chevronRight,
                size: 16,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon() {
    if (!isUnlocked) {
      return Icon(LucideIcons.lock, size: 20, color: AppColors.textMuted.withValues(alpha: 0.5));
    }
    if (quest.isCompleted) {
      return const Icon(LucideIcons.checkCircle2, size: 20, color: AppColors.success);
    }
    return Icon(LucideIcons.circle, size: 20, color: AppColors.textMuted.withValues(alpha: 0.4));
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  static Color _difficultyColor(QuestDifficulty d) {
    return switch (d) {
      QuestDifficulty.easy => const Color(0xFF22C55E),
      QuestDifficulty.medium => const Color(0xFFF59E0B),
      QuestDifficulty.hard => const Color(0xFFEF4444),
      QuestDifficulty.legendary => const Color(0xFF8B5CF6),
    };
  }
}
