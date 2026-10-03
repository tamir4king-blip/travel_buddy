import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';

class LeaderboardResult {
  final List<LeaderboardEntryData> entries;
  final int totalParticipants;
  final String? error;

  const LeaderboardResult({
    required this.entries,
    required this.totalParticipants,
    this.error,
  });
}

class LeaderboardEntryData {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXp;
  final int level;

  const LeaderboardEntryData({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.level,
  });
}

class LeaderboardService {
  final SupabaseClient _client;

  LeaderboardService(this._client);

  /// Fetches the leaderboard from the `profiles` table.
  ///
  /// All time ranges currently return the same total_xp ranking.
  /// Weekly/monthly filtering requires an `xp_snapshots` table:
  /// ```sql
  /// CREATE TABLE xp_snapshots (
  ///   user_id UUID REFERENCES profiles(id),
  ///   snapshot_date DATE NOT NULL,
  ///   total_xp INT NOT NULL,
  ///   PRIMARY KEY (user_id, snapshot_date)
  /// );
  /// ```
  Future<LeaderboardResult> fetchLeaderboard({
    required int limit,
  }) async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, display_name, avatar_url, total_xp, level')
          .eq('is_public', true)
          .order('total_xp', ascending: false)
          .limit(limit);

      final entries = (data as List)
          .map((row) => LeaderboardEntryData(
                userId: row['id'] as String,
                displayName: row['display_name'] as String? ?? 'Traveler',
                avatarUrl: row['avatar_url'] as String?,
                totalXp: row['total_xp'] as int? ?? 0,
                level: row['level'] as int? ?? 1,
              ))
          .toList();

      // Get total count of public profiles
      final countResponse = await _client
          .from('profiles')
          .select('id')
          .eq('is_public', true)
          .count(CountOption.exact);

      return LeaderboardResult(
        entries: entries,
        totalParticipants: countResponse.count,
      );
    } catch (e) {
      return LeaderboardResult(
        entries: [],
        totalParticipants: 0,
        error: e.toString(),
      );
    }
  }

  /// Returns the rank of the current user (1-based).
  /// Counts how many public profiles have more XP than the current user.
  Future<int?> fetchCurrentUserRank() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      // Get current user's XP
      final userData = await _client
          .from('profiles')
          .select('total_xp')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return null;
      final userXp = userData['total_xp'] as int? ?? 0;

      // Count profiles with higher XP
      final higherCount = await _client
          .from('profiles')
          .select('id')
          .eq('is_public', true)
          .gt('total_xp', userXp)
          .count(CountOption.exact);

      return higherCount.count + 1;
    } catch (e, st) {
      logError(e, st, context: 'leaderboard.userRank', report: true);
      return null;
    }
  }
}
