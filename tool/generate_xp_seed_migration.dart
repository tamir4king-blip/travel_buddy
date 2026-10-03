/// Generates the XP-definition seed migration from the Dart registries.
///
/// Usage:
///   dart run tool/generate_xp_seed_migration.dart
///
/// Writes supabase/migrations/20260610000001_seed_xp_definitions.sql.
/// Re-run whenever a registry's ids or XP values change, then apply the
/// migration (`supabase db push`). The output is deterministic, so the
/// generated file can be reviewed in git like any hand-written migration.
///
/// Pure Dart (no Flutter imports) — same approach as
/// tool/seed_achievement_definitions.dart.
library;

import 'dart:io';

import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';
import 'package:travel_buddy_mobile/shared/data/deserts_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/glaciers_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/lakes_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/local_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/master_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/story_quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/travel_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

String q(String? s) => s == null ? 'null' : "'${s.replaceAll("'", "''")}'";

void main() {
  final achievements = <Achievement>[
    ...localAchievementRegistry,
    ...travelAchievementRegistry,
    ...lakesAchievementRegistry,
    ...glaciersAchievementRegistry,
    ...desertsAchievementRegistry,
  ];

  final buf = StringBuffer()
    ..writeln('-- ============================================================')
    ..writeln('-- XP definition seeds — GENERATED FILE, DO NOT EDIT BY HAND.')
    ..writeln('-- Regenerate with: dart run tool/generate_xp_seed_migration.dart')
    ..writeln('-- Source of truth: lib/shared/data/*_registry.dart')
    ..writeln('-- ============================================================')
    ..writeln();

  // Achievements: fill gaps only. Production rows may carry dashboard edits
  // (polygons, photos, adjusted XP) — those stay authoritative.
  buf
    ..writeln('-- ${achievements.length} achievement definitions (insert-if-missing)')
    ..writeln('insert into public.achievement_definitions (id, title, description, tier, xp_reward, collection_id) values');
  buf.writeln(achievements
      .map((a) =>
          '  (${q(a.id)}, ${q(a.title)}, ${q(a.description)}, ${q(a.tier.name)}, ${a.xpReward}, ${q(a.collectionId)})')
      .join(',\n'));
  buf
    ..writeln('on conflict (id) do nothing;')
    ..writeln();

  // Quests: registry-owned tables — overwrite on conflict.
  final rawQuests = [
    for (final s in questRegistry)
      (id: s.id, title: s.title, xp: s.xpReward, max: s.maxCompletions, source: 'activity'),
    for (final c in storyQuestRegistry)
      (id: c.id, title: c.title, xp: c.xpReward, max: 1, source: 'story'),
  ];
  // Dedupe by id (first wins — matches the client's indexWhere lookups).
  // Duplicate ids are registry bugs; surface them loudly.
  final seenQuestIds = <String>{};
  final quests = [
    for (final r in rawQuests)
      if (seenQuestIds.add(r.id))
        r
      else
        ...(() {
          stderr.writeln('WARNING: duplicate quest id "${r.id}" skipped — fix the registry!');
          return <({String id, String title, int xp, int max, String source})>[];
        }()),
  ];
  buf
    ..writeln('-- ${quests.length} quest definitions (${questRegistry.length} activities + ${storyQuestRegistry.length} story chains)')
    ..writeln('insert into public.quest_definitions (id, title, xp_reward, max_completions, source) values');
  buf.writeln(quests
      .map((r) => '  (${q(r.id)}, ${q(r.title)}, ${r.xp}, ${r.max}, ${q(r.source)})')
      .join(',\n'));
  buf
    ..writeln('on conflict (id) do update set title = excluded.title, xp_reward = excluded.xp_reward, max_completions = excluded.max_completions, source = excluded.source;')
    ..writeln();

  buf
    ..writeln('-- ${masterAchievementRegistry.length} master achievement definitions')
    ..writeln('insert into public.master_achievement_definitions (id, title, xp_reward) values');
  buf.writeln(masterAchievementRegistry
      .map((m) => '  (${q(m.id)}, ${q(m.title)}, ${m.xpReward})')
      .join(',\n'));
  buf
    ..writeln('on conflict (id) do update set title = excluded.title, xp_reward = excluded.xp_reward;')
    ..writeln();

  buf
    ..writeln('-- ${collectionRegistry.length} collection completion bonuses')
    ..writeln('insert into public.collection_definitions (id, name, bonus_xp) values');
  buf.writeln(collectionRegistry
      .map((c) => '  (${q(c.id)}, ${q(c.name)}, ${c.bonusXp})')
      .join(',\n'));
  buf.writeln('on conflict (id) do update set name = excluded.name, bonus_xp = excluded.bonus_xp;');

  final out = File('supabase/migrations/20260610000001_seed_xp_definitions.sql');
  out.writeAsStringSync(buf.toString());
  stdout.writeln('Wrote ${out.path}: ${achievements.length} achievements, '
      '${quests.length} quests, ${masterAchievementRegistry.length} masters, '
      '${collectionRegistry.length} collections.');
}
