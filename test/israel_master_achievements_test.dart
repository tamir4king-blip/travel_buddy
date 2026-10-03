import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_master_achievements.dart';
import 'package:travel_buddy_mobile/shared/data/master_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/master_achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart'
    show achievementRegistry;
import 'package:travel_buddy_mobile/shared/utils/achievement_requirements.dart';

List<Achievement> unlock(Iterable<String> ids) {
  final set = ids.toSet();
  return [
    for (final a in achievementRegistry)
      set.contains(a.id) ? a.copyWith(isUnlocked: true) : a,
  ];
}

bool isMet(MasterAchievement m, List<Achievement> all) => m.requirements
    .every((r) => achievementRequirementProgress(r, all)?.$2 ?? false);

void main() {
  final registryIds = achievementRegistry.map((a) => a.id).toSet();
  final allTags = {for (final a in achievementRegistry) ...a.tags};

  test('Israel masters are registered, unique and translated', () {
    final ids = masterAchievementRegistry.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final m in israelMasterAchievements) {
      expect(ids, contains(m.id));
      expect(israelMasterHebrew[m.id], isNotNull, reason: m.id);
      expect(m.xpReward, MasterAchievement.xpForTier(m.tier), reason: m.id);
    }
  });

  test('every requirement points at real achievements, tags and lists', () {
    for (final m in israelMasterAchievements) {
      for (final r in m.requirements) {
        switch (r.type) {
          case MasterRequirementType.anyOfAchievements:
            final refs = r.targetId!.split(',').map((s) => s.trim()).toList();
            for (final id in refs) {
              expect(registryIds, contains(id), reason: '${m.id} → $id');
            }
            expect(r.targetValue, lessThanOrEqualTo(refs.length),
                reason: '${m.id} needs more than it lists');
          case MasterRequirementType.tagCount:
            expect(allTags, contains(r.targetId), reason: m.id);
            final available = achievementRegistry
                .where((a) => a.tags.contains(r.targetId))
                .length;
            expect(r.targetValue, lessThanOrEqualTo(available),
                reason: '${m.id} is impossible');
          case MasterRequirementType.collectionProgress:
          case MasterRequirementType.completeCollection:
            expect(israelListIds, contains(r.targetId), reason: m.id);
          case MasterRequirementType.israelRegionCount:
            expect(r.targetValue,
                lessThanOrEqualTo(IsraelRegion.values.length));
          default:
            fail('${m.id} uses unexpected type ${r.type}');
        }
      }
    }
  });

  test('From Metula to Eilat needs both ends', () {
    final m = israelMasterAchievements
        .firstWhere((m) => m.id == 'il-master-north-to-south');
    expect(isMet(m, unlock(['il-metula'])), isFalse);
    expect(isMet(m, unlock(['il-metula', 'il-eilat'])), isTrue);
  });

  test('Four Seas needs one place on each sea', () {
    final m =
        israelMasterAchievements.firstWhere((m) => m.id == 'il-master-four-seas');
    expect(isMet(m, unlock(['herzl-beach', 'il-tzemach-beach', 'il-coral-beach'])),
        isFalse);
    expect(
        isMet(
            m,
            unlock([
              'herzl-beach',
              'il-tzemach-beach',
              'il-dead-sea-float',
              'il-coral-beach',
            ])),
        isTrue);
  });

  test('region count and tag count progress', () {
    const regions = MasterRequirement(
      type: MasterRequirementType.israelRegionCount,
      targetValue: 4,
      description: '',
    );
    final all = unlock(['il-metula', 'il-masada', 'il-eilat', 'il-avdat']);
    final (p, met) = achievementRequirementProgress(regions, all)!;
    expect(met, isTrue);
    expect(p, 1.0);

    const desert = MasterRequirement(
      type: MasterRequirementType.tagCount,
      targetId: 'il-facet:desert',
      targetValue: 4,
      description: '',
    );
    final (dp, dmet) = achievementRequirementProgress(desert, all)!;
    expect(dmet, isFalse); // Metula and Eilat aren't desert regions
    expect(dp, closeTo(0.5, 1e-9));
  });

  test('non-achievement requirement types are left to the provider', () {
    const r = MasterRequirement(
      type: MasterRequirementType.userLevel,
      targetValue: 5,
      description: '',
    );
    expect(achievementRequirementProgress(r, const []), isNull);
  });
}
