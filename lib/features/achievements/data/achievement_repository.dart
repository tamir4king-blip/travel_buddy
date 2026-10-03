import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_buddy_mobile/shared/models/achievement_detail.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';

class AchievementRepository {
  final SupabaseClient _client;

  /// In-memory cache to avoid re-fetching during the same session.
  final Map<String, AchievementDetail> _cache = {};

  AchievementRepository(this._client);

  /// Fetches rich detail for a single achievement by [id].
  /// Returns cached data if available, otherwise fetches from Supabase.
  /// Returns `null` if not found or on network error (graceful fallback).
  Future<AchievementDetail?> getDetail(String id) async {
    if (_cache.containsKey(id)) return _cache[id];

    try {
      final data = await _client
          .from('achievements')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;

      final detail = AchievementDetail.fromJson(data);
      _cache[id] = detail;
      return detail;
    } catch (e, st) {
      // Graceful fallback — show local data only
      logError(e, st, context: 'achievementRepository.getDetail', report: true);
      return null;
    }
  }

  /// Fetches rich details for all achievements in a [collectionId].
  /// Useful for pre-loading a collection view.
  Future<List<AchievementDetail>> getByCollection(String collectionId) async {
    try {
      final data = await _client
          .from('achievements')
          .select()
          .eq('collection_id', collectionId);

      final details = <AchievementDetail>[];
      for (final row in data) {
        final detail = AchievementDetail.fromJson(row);
        _cache[detail.id] = detail;
        details.add(detail);
      }
      return details;
    } catch (e, st) {
      logError(e, st, context: 'achievementRepository.getByCollection',
          report: true);
      return [];
    }
  }

  /// Returns the cached detail if available (synchronous, no network call).
  AchievementDetail? getCached(String id) => _cache[id];

  /// Clears the in-memory cache.
  void clearCache() => _cache.clear();
}

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AchievementRepository(client);
});
