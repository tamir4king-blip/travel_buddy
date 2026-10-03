import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_activity_quests.dart';
import 'package:travel_buddy_mobile/shared/data/quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';

void main() {
  test('Israel activities are registered with unique ids', () {
    final ids = questRegistry.map((q) => q.id).toList();
    for (final q in israelActivityQuests) {
      expect(ids.where((id) => id == q.id), hasLength(1), reason: q.id);
      expect(q.id, startsWith('il-q-'));
    }
  });

  test('skills, categories, prerequisites and Hebrew are valid', () {
    final skillIds = skillRegistry.map((s) => s.id).toSet();
    final categories = questRegistry
        .where((q) => !q.id.startsWith('il-q-'))
        .map((q) => q.category)
        .toSet();
    final questIds = questRegistry.map((q) => q.id).toSet();

    for (final q in israelActivityQuests) {
      expect(skillIds, contains(q.skillType), reason: q.id);
      expect(categories, contains(q.category), reason: q.id);
      for (final req in q.requiredQuestIds) {
        expect(questIds, contains(req), reason: q.id);
      }
      expect(israelQuestHebrew[q.id], isNotNull, reason: q.id);
      for (final loc in q.allLocations) {
        expect(loc.latitude, inInclusiveRange(29.45, 33.35), reason: q.id);
        expect(loc.longitude, inInclusiveRange(34.25, 35.90), reason: q.id);
      }
    }
  });
}
