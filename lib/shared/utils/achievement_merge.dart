/// Pure merge rules for reconciling local achievement state with the
/// remote `user_achievements` rows from Supabase.
///
/// Extracted from `AchievementsNotifier._syncFromRemote` so the logic can be
/// unit tested (see `test/achievement_merge_test.dart`). The merge is
/// CRDT-style: counts take the max, timestamps take the latest, and revisit
/// histories take the deduplicated union — so replaying a sync is always safe.
library;

import 'package:travel_buddy_mobile/shared/models/achievement.dart';

DateTime? latestDate(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}

/// Union of two timestamp lists, deduplicated by millisecond and sorted.
List<DateTime> unionTimestamps(List<DateTime> a, List<DateTime> b) {
  final seen = <int>{};
  final out = <DateTime>[];
  for (final d in [...a, ...b]) {
    if (seen.add(d.millisecondsSinceEpoch)) out.add(d);
  }
  out.sort();
  return out;
}

/// Parse a `revisit_history` column value, skipping malformed entries so one
/// bad timestamp can't abort an entire sync.
List<DateTime> parseRevisitHistory(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((d) => d is String ? DateTime.tryParse(d) : null)
      .whereType<DateTime>()
      .toList();
}

/// Reconcile one local achievement with its remote `user_achievements` row.
///
/// Returns the merged achievement, or `null` when nothing changed:
/// - Locally locked + remote row exists → restore the full unlock state
///   (e.g. after a reinstall or on a second device).
/// - Locally unlocked → merge revisit data field-by-field (max count,
///   latest visit, union history).
Achievement? mergeRemoteRow(Achievement local, Map<String, dynamic> remote) {
  final remoteVisitCount = remote['visit_count'] as int? ?? 0;
  final remoteLastVisitedAt = remote['last_visited_at'] is String
      ? DateTime.tryParse(remote['last_visited_at'] as String)
      : null;
  final remoteRevisitHistory = parseRevisitHistory(remote['revisit_history']);

  if (!local.isUnlocked) {
    return local.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.tryParse(remote['unlocked_at'] as String? ?? ''),
      visitDate: remote['visit_date'] is String
          ? DateTime.tryParse(remote['visit_date'] as String)
          : null,
      notes: remote['notes'] as String?,
      isRetroactive: remote['is_retroactive'] as bool? ?? false,
      photos: (remote['photos'] as List<dynamic>?)?.cast<String>() ?? const [],
      visitCount: remoteVisitCount,
      lastVisitedAt: remoteLastVisitedAt,
      revisitHistory: remoteRevisitHistory,
    );
  }

  final mergedCount =
      remoteVisitCount > local.visitCount ? remoteVisitCount : local.visitCount;
  final mergedLastVisited = latestDate(local.lastVisitedAt, remoteLastVisitedAt);
  final mergedHistory =
      unionTimestamps(local.revisitHistory, remoteRevisitHistory);

  // The union always contains every local entry, so an equal length means
  // nothing new arrived from the remote side.
  if (mergedCount == local.visitCount &&
      mergedLastVisited == local.lastVisitedAt &&
      mergedHistory.length == local.revisitHistory.length) {
    return null;
  }

  return local.copyWith(
    visitCount: mergedCount,
    lastVisitedAt: mergedLastVisited,
    revisitHistory: mergedHistory,
  );
}
