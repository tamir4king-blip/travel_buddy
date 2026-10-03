/// Pure helpers for the Supabase `achievement_definitions` cache.
///
/// Shared by `AchievementDefinitionsNotifier` (main isolate) and the
/// background proximity checker, which has no Riverpod container and reads
/// the cached JSON straight from SharedPreferences.
library;

import 'dart:convert';

import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// SharedPreferences key holding the cached Supabase definitions JSON
/// (written by `PersistenceService.saveAchievementDefinitions`).
const achievementDefinitionsCacheKey = 'achievement_definitions';

/// Merge: remote definitions override hardcoded by id; remote-only
/// definitions are appended.
List<Achievement> mergeDefinitions(
  List<Achievement> hardcoded,
  List<Achievement> remote,
) {
  final remoteMap = {for (final a in remote) a.id: a};
  final merged = hardcoded.map((a) {
    final r = remoteMap.remove(a.id);
    if (r == null) return a;
    // Remote overrides definition fields but keeps hardcoded defaults for
    // fields that might not be in Supabase (e.g. tags fallback)
    return Achievement(
      id: r.id,
      title: r.title,
      description: r.description,
      iconName: r.iconName ?? a.iconName,
      tier: r.tier,
      xpReward: r.xpReward,
      latitude: r.latitude ?? a.latitude,
      longitude: r.longitude ?? a.longitude,
      claimRadius: r.claimRadius ?? a.claimRadius,
      claimPolygon: r.claimPolygon,
      collectionId: r.collectionId ?? a.collectionId,
      tags: r.tags.isNotEmpty ? r.tags : a.tags,
    );
  }).toList();

  // Add any new achievements that exist in Supabase but not hardcoded
  merged.addAll(remoteMap.values);
  return merged;
}

List<Achievement> parseDefinitions(String json) {
  final list = jsonDecode(json) as List<dynamic>;
  return list.map((e) {
    final row = e as Map<String, dynamic>;

    List<List<double>>? polygon;
    final rawPolygon = row['claim_polygon'];
    if (rawPolygon is List && rawPolygon.isNotEmpty) {
      polygon = rawPolygon
          .map<List<double>>(
              (p) => (p as List).map<double>((v) => (v as num).toDouble()).toList())
          .toList();
    }

    return Achievement(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      iconName: row['icon_name'] as String?,
      tier: AchievementTier.values.byName(row['tier'] as String),
      xpReward: row['xp_reward'] as int,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      claimRadius: (row['claim_radius'] as num?)?.toDouble(),
      claimPolygon: polygon,
      collectionId: row['collection_id'] as String?,
      tags: (row['tags'] as List?)?.cast<String>() ?? const [],
    );
  }).toList();
}

String serializeDefinitions(List<Achievement> definitions) {
  return jsonEncode(definitions.map((a) => {
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
  }).toList());
}
