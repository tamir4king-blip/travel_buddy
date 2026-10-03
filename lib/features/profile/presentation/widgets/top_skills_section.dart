import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';

class TopSkillsSection extends StatelessWidget {
  final Map<String, int> skillXp;
  final List<SkillGroup> allSkills;

  const TopSkillsSection({
    super.key,
    required this.skillXp,
    required this.allSkills,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Filter to skills that have XP and sort descending
    final entries = skillXp.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top6 = entries.take(6).toList();

    if (top6.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          l10n.noSkillsYet,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < top6.length; i++)
          _SkillRow(
            skillId: top6[i].key,
            xp: top6[i].value,
            allSkills: allSkills,
          )
              .animate(delay: (i * 60).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String skillId;
  final int xp;
  final List<SkillGroup> allSkills;

  const _SkillRow({
    required this.skillId,
    required this.xp,
    required this.allSkills,
  });

  SkillGroup? get _skill {
    try {
      return allSkills.firstWhere((s) => s.id == skillId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = _skill;
    if (skill == null) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context);
    final level = (xp / skill.xpPerLevel).floor() + 1;
    final clampedLevel = level.clamp(1, skill.maxLevel);
    final progressInLevel = (xp % skill.xpPerLevel) / skill.xpPerLevel;

    final gradientStart = _parseHex(skill.gradientStart);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(skill.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      RegistryL10n.skillName(locale, skill.id, skill.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: gradientStart.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lv $clampedLevel',
                        style: TextStyle(
                          color: gradientStart,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value: progressInLevel,
                      backgroundColor:
                          AppColors.bgCardLight.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(
                        gradientStart,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _parseHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}
