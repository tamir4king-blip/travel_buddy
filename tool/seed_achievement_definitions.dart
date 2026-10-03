/// Seed script: upserts all hardcoded achievement definitions into Supabase.
///
/// Usage:
///   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... dart run tool/seed_achievement_definitions.dart
///
/// This is idempotent — safe to re-run. Uses upsert (on conflict update).
/// Uses raw HTTP to avoid Flutter/dart:ui dependency.
library;

import 'dart:convert';
import 'dart:io';

import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/data/travel_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/local_achievement_registry.dart';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  if (url == null || key == null) {
    stderr.writeln('Error: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables.');
    exit(1);
  }

  final client = HttpClient();
  final registry = <Achievement>[
    ...localAchievementRegistry,
    ...travelAchievementRegistry,
  ];

  print('Seeding ${registry.length} achievement definitions (${localAchievementRegistry.length} local + ${travelAchievementRegistry.length} travel)...');

  // Batch upsert via Supabase REST API (PostgREST)
  final rows = registry.map((a) => {
    'id': a.id,
    'title': a.title,
    'description': a.description,
    'icon_name': a.iconName,
    'tier': a.tier.name,
    'xp_reward': a.xpReward,
    'latitude': a.latitude,
    'longitude': a.longitude,
    'claim_radius': a.claimRadius,
    'claim_polygon': a.claimPolygon,
    'collection_id': a.collectionId,
    'tags': a.tags,
    'is_active': true,
  }).toList();

  try {
    final uri = Uri.parse('$url/rest/v1/achievement_definitions');
    final request = await client.postUrl(uri);
    request.headers.set('apikey', key);
    request.headers.set('Authorization', 'Bearer $key');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Prefer', 'resolution=merge-duplicates');
    request.write(jsonEncode(rows));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('Done. Upserted ${registry.length} definitions.');
    } else {
      stderr.writeln('Failed (${response.statusCode}): $body');
    }
  } catch (e) {
    stderr.writeln('Error: $e');
  }

  client.close();
  exit(0);
}
