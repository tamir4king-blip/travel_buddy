/// Progress for master-achievement requirements that depend only on which
/// achievements are unlocked. Pure Dart, shared by the provider and tests.
library;

import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/master_achievement.dart';

/// Returns `(progress 0..1, met)` for achievement-based requirement types,
/// or null when [req] depends on something else (quests, levels, streaks).
(double, bool)? achievementRequirementProgress(
  MasterRequirement req,
  Iterable<Achievement> all,
) {
  final target = req.targetValue < 1 ? 1 : req.targetValue;
  (double, bool) count(int n) => ((n / target).clamp(0.0, 1.0), n >= target);

  switch (req.type) {
    case MasterRequirementType.collectionProgress:
      return count(all
          .where((a) => a.isUnlocked && a.collectionId == req.targetId)
          .length);

    case MasterRequirementType.anyOfAchievements:
      final ids = (req.targetId ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      return count(all.where((a) => a.isUnlocked && ids.contains(a.id)).length);

    case MasterRequirementType.tagCount:
      return count(all
          .where((a) => a.isUnlocked && a.tags.contains(req.targetId))
          .length);

    case MasterRequirementType.israelRegionCount:
      final regions = <IsraelRegion>{};
      for (final a in all) {
        if (!a.isUnlocked) continue;
        final r = IsraelRegion.fromTags(a.tags);
        if (r != null) regions.add(r);
      }
      return count(regions.length);

    case MasterRequirementType.completeCollection:
    case MasterRequirementType.skillLevel:
    case MasterRequirementType.questCount:
    case MasterRequirementType.userLevel:
    case MasterRequirementType.achievementCount:
    case MasterRequirementType.questCategory:
    case MasterRequirementType.streakDays:
      return null;
  }
}
