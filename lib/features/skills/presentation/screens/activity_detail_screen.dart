import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/data/quest_categories.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final String skillId;
  final String activityId;

  const ActivityDetailScreen({
    super.key,
    required this.skillId,
    required this.activityId,
  });

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  /// Resolved labels for all locations, keyed by index.
  final Map<int, String> _locationLabels = {};
  bool _locationsResolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveLocations());
  }

  Future<void> _resolveLocations() async {
    final quest = _quest;
    if (quest == null) return;
    final allLocs = quest.allLocations;
    if (allLocs.isEmpty) return;

    for (var i = 0; i < allLocs.length; i++) {
      final loc = allLocs[i];
      try {
        final placemarks =
            await placemarkFromCoordinates(loc.latitude, loc.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final city = p.locality ?? p.subAdministrativeArea ?? '';
          final country = p.country ?? '';
          _locationLabels[i] =
              city.isNotEmpty ? '$city, $country' : country;
        } else {
          _locationLabels[i] =
              '${loc.latitude.toStringAsFixed(3)}°, ${loc.longitude.toStringAsFixed(3)}°';
        }
      } catch (e, st) {
        // Geocoding failed (offline / rate-limited) — fall back to coords.
        logError(e, st, context: 'activityDetail.geocodeLocation');
        _locationLabels[i] =
            '${loc.latitude.toStringAsFixed(3)}°, ${loc.longitude.toStringAsFixed(3)}°';
      }
    }

    if (mounted) setState(() => _locationsResolved = true);
  }

  SideQuest? get _quest {
    final quests = ref.read(questsProvider).allQuests;
    try {
      return quests.firstWhere((q) => q.id == widget.activityId);
    } catch (_) {
      return null;
    }
  }

  SkillGroup? get _skill {
    try {
      return skillRegistry.firstWhere((s) => s.id == widget.skillId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final questsState = ref.watch(questsProvider);
    final quest = questsState.allQuests.where((q) => q.id == widget.activityId).firstOrNull;
    final skill = _skill;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    if (quest == null || skill == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Activity not found')),
      );
    }

    final gradientStart = _parseColor(skill.gradientStart);
    final gradientEnd = _parseColor(skill.gradientEnd);
    final diffColor = _difficultyColor(quest.difficulty);
    final superCat = getSuperCategoryForQuest(quest.category);
    final unlocked = quest.isUnlocked(
      skillLevels: questsState.skillLevels,
      allQuests: questsState.allQuests,
    );

    // Related activities: same category + same skillType, excluding self
    final relatedActivities = questsState.allQuests
        .where((q) => q.skillType == quest.skillType && q.id != quest.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 180,
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
                      gradientStart.withValues(alpha: 0.2),
                      gradientEnd.withValues(alpha: 0.06),
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
                      const SizedBox(height: 20),
                      // Category icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: (superCat?.color ?? gradientStart).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            superCat?.icon ?? LucideIcons.compass,
                            size: 28,
                            color: superCat?.color ?? gradientStart,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          RegistryL10n.questTitle(locale, quest.id, quest.title),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Pills row ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _DetailPill(
                        icon: LucideIcons.signal,
                        text: quest.difficulty.name,
                        color: diffColor,
                      ),
                      _DetailPill(
                        icon: LucideIcons.sparkles,
                        text: '+${quest.xpReward} XP',
                        color: AppColors.xpGreen,
                      ),
                      _DetailPill(
                        icon: _verificationIcon(quest.verification),
                        text: quest.verification.name,
                        color: AppColors.textSecondary,
                      ),
                      if (quest.isRepeatable)
                        _DetailPill(
                          icon: LucideIcons.repeat,
                          text: '${quest.completionCount}/${quest.maxCompletions}',
                          color: AppColors.primary,
                        ),
                      if (quest.isCompleted)
                        const _DetailPill(
                          icon: LucideIcons.checkCircle2,
                          text: 'Completed',
                          color: AppColors.success,
                        ),
                      if (!unlocked)
                        _DetailPill(
                          icon: LucideIcons.lock,
                          text: 'Locked',
                          color: AppColors.textMuted,
                        ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 20),

                  // ── Description ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      RegistryL10n.questDescription(locale, quest.id, quest.description),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

                  const SizedBox(height: 16),

                  // ── Locations ──
                  if (quest.allLocations.isNotEmpty) ...[
                    Text(
                      'Locations',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quest.allLocations.length} ${quest.allLocations.length == 1 ? 'place' : 'places'} available',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < quest.allLocations.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _locationsResolved
                                      ? (_locationLabels[i] ?? 'Loading…')
                                      : 'Loading…',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                              duration: 300.ms,
                              delay: Duration(milliseconds: 150 + i * 50),
                            ),
                      ),
                    const SizedBox(height: 8),
                  ],

                  // ── Linked skill ──
                  GestureDetector(
                    onTap: () => context.push('/skills/${skill.id}'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          GlowContainer(
                            glowColor: gradientStart,
                            borderRadius: 10,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [gradientStart, gradientEnd],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(skill.icon, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  RegistryL10n.skillName(locale, skill.id, skill.name),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Levels up this skill',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

                  const SizedBox(height: 16),

                  // ── Requirements ──
                  if (!unlocked) ...[
                    _buildRequirements(quest, questsState, locale, gradientStart),
                    const SizedBox(height: 16),
                  ],

                  // ── Complete button ──
                  if (unlocked && !quest.isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(questsProvider.notifier).completeQuest(quest.id);
                        },
                        icon: const Icon(LucideIcons.checkCircle2, size: 18),
                        label: Text(l10n.complete),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 250.ms),

                  if (unlocked && quest.isCompleted && quest.isRepeatable &&
                      quest.completionCount < quest.maxCompletions)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(questsProvider.notifier).completeQuest(quest.id);
                        },
                        icon: const Icon(LucideIcons.repeat, size: 18),
                        label: Text('Complete Again (${quest.completionCount}/${quest.maxCompletions})'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 250.ms),

                  const SizedBox(height: 24),

                  // ── Related Activities ──
                  if (relatedActivities.isNotEmpty) ...[
                    Text(
                      'Related Activities',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Other ${RegistryL10n.skillName(locale, skill.id, skill.name)} activities',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          // ── Related activities list ──
          if (relatedActivities.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: relatedActivities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final related = relatedActivities[i];
                  final rUnlocked = related.isUnlocked(
                    skillLevels: questsState.skillLevels,
                    allQuests: questsState.allQuests,
                  );
                  return _RelatedActivityTile(
                    quest: related,
                    locale: locale,
                    isUnlocked: rUnlocked,
                    onTap: () => context.pushReplacement(
                      '/skills/${widget.skillId}/activity/${related.id}',
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (i * 40).ms)
                      .slideY(begin: 0.03);
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildRequirements(SideQuest quest, QuestsState qs, Locale locale, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lock, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (quest.requiredSkillType != null && quest.requiredSkillLevel != null) ...[
            _requirementRow(
              'Reach level ${quest.requiredSkillLevel} in ${quest.requiredSkillType}',
              (qs.skillLevels[quest.requiredSkillType] ?? 0) >= quest.requiredSkillLevel!,
            ),
          ],
          for (final reqId in quest.requiredQuestIds)
            _requirementRow(
              'Complete: ${_questTitle(reqId, qs, locale)}',
              qs.allQuests.where((q) => q.id == reqId).firstOrNull?.isCompleted ?? false,
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _requirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 14,
            color: met ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: met ? AppColors.textSecondary : AppColors.textMuted,
                decoration: met ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _questTitle(String id, QuestsState qs, Locale locale) {
    final q = qs.allQuests.where((q) => q.id == id).firstOrNull;
    if (q == null) return id;
    return RegistryL10n.questTitle(locale, q.id, q.title);
  }

  static IconData _verificationIcon(VerificationMethod v) {
    return switch (v) {
      VerificationMethod.photo => LucideIcons.camera,
      VerificationMethod.manual => LucideIcons.handMetal,
      VerificationMethod.location => LucideIcons.mapPin,
      VerificationMethod.timeBased => LucideIcons.clock,
    };
  }

  static Color _difficultyColor(QuestDifficulty d) {
    return switch (d) {
      QuestDifficulty.easy => const Color(0xFF22C55E),
      QuestDifficulty.medium => const Color(0xFFF59E0B),
      QuestDifficulty.hard => const Color(0xFFEF4444),
      QuestDifficulty.legendary => const Color(0xFF8B5CF6),
    };
  }

  static Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

// ─── Detail pill ─────────────────────────────────────────────────────────────

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _DetailPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Related activity tile ───────────────────────────────────────────────────

class _RelatedActivityTile extends StatelessWidget {
  final SideQuest quest;
  final Locale locale;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _RelatedActivityTile({
    required this.quest,
    required this.locale,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(quest.difficulty);

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: quest.isCompleted
                ? AppColors.success.withValues(alpha: 0.25)
                : AppColors.bgCardLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              quest.isCompleted
                  ? LucideIcons.checkCircle2
                  : !isUnlocked
                      ? LucideIcons.lock
                      : LucideIcons.circle,
              size: 18,
              color: quest.isCompleted
                  ? AppColors.success
                  : AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RegistryL10n.questTitle(locale, quest.id, quest.title),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quest.difficulty.name,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: diffColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+${quest.xpReward} XP',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.xpGreen,
                        ),
                      ),
                      if (quest.latitude != null) ...[
                        const SizedBox(width: 6),
                        Icon(LucideIcons.mapPin, size: 10, color: AppColors.textMuted),
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
                size: 14,
                color: AppColors.textMuted,
              ),
          ],
        ),
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
