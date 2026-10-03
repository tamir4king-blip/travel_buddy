/// Generates the Israel Explorer seed migration from the Dart catalog.
///
/// Usage:
///   dart run tool/generate_israel_seed_migration.dart
///
/// Writes supabase/migrations/20261004000000_seed_israel_explorer.sql:
/// achievement definitions (with geofences, so the remote catalog matches
/// the app), list completion bonuses, activity quests and master
/// achievements — everything the server-side XP triggers price from — plus
/// the revisit cooldown for Israel regions, cities and villages.
///
/// Pure Dart (no Flutter imports), like tool/generate_xp_seed_migration.dart.
library;

import 'dart:convert';
import 'dart:io';

import 'package:travel_buddy_mobile/shared/data/israel/israel_activity_quests.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_master_achievements.dart';

String q(String? s) => s == null ? 'null' : "'${s.replaceAll("'", "''")}'";

/// Tags as a jsonb array literal — production's `tags` column is jsonb.
String tagsJson(List<String> items) => '${q(jsonEncode(items))}::jsonb';

void main() {
  final achievements = israelAchievementRegistry;

  final buf = StringBuffer()
    ..writeln('-- ============================================================')
    ..writeln('-- Israel Explorer seeds — GENERATED FILE, DO NOT EDIT BY HAND.')
    ..writeln('-- Regenerate with: dart run tool/generate_israel_seed_migration.dart')
    ..writeln('-- Source of truth: lib/shared/data/israel/')
    ..writeln('-- ============================================================')
    ..writeln()
    // Production created achievement_definitions by hand with jsonb tags;
    // the repo migration declared text[]. Converge on jsonb so this seed
    // runs on both (the app reads either as a JSON list).
    ..writeln('do \$\$')
    ..writeln('begin')
    ..writeln('  if (select format_type(atttypid, atttypmod) from pg_attribute')
    ..writeln("      where attrelid = 'public.achievement_definitions'::regclass")
    ..writeln("        and attname = 'tags' and not attisdropped) = 'text[]' then")
    ..writeln('    alter table public.achievement_definitions')
    ..writeln("      alter column tags drop default,")
    ..writeln('      alter column tags type jsonb using to_jsonb(tags),')
    ..writeln("      alter column tags set default '[]'::jsonb;")
    ..writeln('  end if;')
    ..writeln('end \$\$;')
    ..writeln();

  // Achievements: insert-if-missing, like the main seed — dashboard edits
  // (polygons, adjusted radii) on existing rows stay authoritative.
  buf
    ..writeln('-- ${achievements.length} Israel place definitions (insert-if-missing)')
    ..writeln('insert into public.achievement_definitions '
        '(id, title, description, tier, xp_reward, latitude, longitude, '
        'claim_radius, collection_id, tags) values');
  buf.writeln(achievements
      .map((a) => '  (${q(a.id)}, ${q(a.title)}, ${q(a.description)}, '
          '${q(a.tier.name)}, ${a.xpReward}, ${a.latitude}, ${a.longitude}, '
          '${a.claimRadius}, ${q(a.collectionId)}, ${tagsJson(a.tags)})')
      .join(',\n'));
  buf
    ..writeln('on conflict (id) do nothing;')
    ..writeln();

  buf
    ..writeln('-- ${IsraelList.values.length} Israel list completion bonuses')
    ..writeln('insert into public.collection_definitions (id, name, bonus_xp) values');
  buf.writeln(IsraelList.values
      .map((l) => '  (${q(l.id)}, ${q(l.name)}, ${l.bonusXp})')
      .join(',\n'));
  buf
    ..writeln('on conflict (id) do update set name = excluded.name, bonus_xp = excluded.bonus_xp;')
    ..writeln();

  buf
    ..writeln('-- ${israelActivityQuests.length} Israel activity quests')
    ..writeln('insert into public.quest_definitions (id, title, xp_reward, max_completions, source) values');
  buf.writeln(israelActivityQuests
      .map((s) => "  (${q(s.id)}, ${q(s.title)}, ${s.xpReward}, "
          "${s.maxCompletions}, 'activity')")
      .join(',\n'));
  buf
    ..writeln('on conflict (id) do update set title = excluded.title, xp_reward = excluded.xp_reward, max_completions = excluded.max_completions, source = excluded.source;')
    ..writeln();

  buf
    ..writeln('-- ${israelMasterAchievements.length} Israel master achievements')
    ..writeln('insert into public.master_achievement_definitions (id, title, xp_reward) values');
  buf.writeln(israelMasterAchievements
      .map((m) => '  (${q(m.id)}, ${q(m.title)}, ${m.xpReward})')
      .join(',\n'));
  buf
    ..writeln('on conflict (id) do update set title = excluded.title, xp_reward = excluded.xp_reward;')
    ..writeln();

  // Mirror of AchievementsNotifier.cooldownFor: people live and commute in
  // regions, cities and villages, so those revisit weekly, not hourly.
  final extended = [
    'continents', 'europe', 'americas', 'africa', 'asia', 'south-america',
    'oceania', 'capitals',
    ...israelExtendedCooldownListIds,
  ];
  buf
    ..writeln('-- Revisit cooldown — adds the Israel regions, cities and villages')
    ..writeln('create or replace function public.revisit_cooldown(p_achievement_id text)')
    ..writeln('returns interval')
    ..writeln('language sql')
    ..writeln('stable')
    ..writeln('set search_path = public')
    ..writeln(r'as $$')
    ..writeln('  select case')
    ..writeln('    when (select collection_id')
    ..writeln('          from public.achievement_definitions')
    ..writeln('          where id = p_achievement_id)')
    ..writeln('         in (${extended.map(q).join(', ')})')
    ..writeln("      then interval '7 days'")
    ..writeln("    else interval '1 hour'")
    ..writeln('  end;')
    ..writeln(r'$$;')
    ..writeln()
    ..writeln('revoke execute on function public.revisit_cooldown(text) from public, anon, authenticated;');

  final out = File('supabase/migrations/20261004000000_seed_israel_explorer.sql');
  out.writeAsStringSync(buf.toString());
  stdout.writeln('Wrote ${out.path}: ${achievements.length} places, '
      '${IsraelList.values.length} lists, ${israelActivityQuests.length} '
      'activities, ${israelMasterAchievements.length} masters.');
}
