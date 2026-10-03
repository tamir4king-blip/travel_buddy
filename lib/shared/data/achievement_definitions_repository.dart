import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

class AchievementDefinitionsRepository {
  final SupabaseClient _client;

  AchievementDefinitionsRepository(this._client);

  /// Fetches all active achievement definitions from Supabase.
  Future<List<Achievement>> fetchAll() async {
    final data = await _client
        .from('achievement_definitions')
        .select()
        .eq('is_active', true);

    return data.map(_fromRow).toList();
  }

  /// Pushes a polygon update for a single achievement. Optionally also
  /// updates the pin location (latitude/longitude) — typically the polygon's
  /// centroid so the marker sits inside the claim area.
  Future<void> savePolygon(
    String achievementId,
    List<List<double>>? polygon, {
    double? centerLat,
    double? centerLng,
  }) async {
    final update = <String, dynamic>{'claim_polygon': polygon};
    if (centerLat != null) update['latitude'] = centerLat;
    if (centerLng != null) update['longitude'] = centerLng;
    await _client
        .from('achievement_definitions')
        .update(update)
        .eq('id', achievementId);
  }

  /// Pushes a radius update for a single achievement.
  Future<void> saveRadius(String achievementId, double? radius) async {
    await _client.from('achievement_definitions').update({
      'claim_radius': radius,
      'claim_polygon': null,
    }).eq('id', achievementId);
  }

  /// Upserts an achievement definition (used by seed script / dev panel).
  Future<void> upsert(Achievement achievement) async {
    await _client.from('achievement_definitions').upsert({
      'id': achievement.id,
      'title': achievement.title,
      'description': achievement.description,
      'icon_name': achievement.iconName,
      'tier': achievement.tier.name,
      'xp_reward': achievement.xpReward,
      'latitude': achievement.latitude,
      'longitude': achievement.longitude,
      'claim_radius': achievement.claimRadius,
      'claim_polygon': achievement.claimPolygon,
      'collection_id': achievement.collectionId,
      'tags': achievement.tags,
      'is_active': true,
    });
  }

  /// Fetches the change history for a specific achievement, newest first.
  /// Returns raw row maps; callers should parse as needed.
  Future<List<Map<String, dynamic>>> fetchHistory(String achievementId) async {
    final data = await _client
        .from('achievement_definition_history')
        .select()
        .eq('achievement_id', achievementId)
        .order('changed_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetches the most recent N changes across all achievements (for an
  /// "everything that changed lately" feed).
  Future<List<Map<String, dynamic>>> fetchRecentHistory({int limit = 50}) async {
    final data = await _client
        .from('achievement_definition_history')
        .select()
        .order('changed_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  static Achievement _fromRow(Map<String, dynamic> row) {
    List<List<double>>? polygon;
    final rawPolygon = row['claim_polygon'];
    if (rawPolygon is List && rawPolygon.isNotEmpty) {
      polygon = rawPolygon
          .map<List<double>>((p) => (p as List).map<double>((v) => (v as num).toDouble()).toList())
          .toList();
    }

    return Achievement(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
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
  }
}
