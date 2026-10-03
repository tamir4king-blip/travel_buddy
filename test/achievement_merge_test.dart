import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/utils/achievement_merge.dart';

Achievement makeAchievement({
  String id = 'test-spot',
  bool isUnlocked = false,
  DateTime? unlockedAt,
  int visitCount = 0,
  DateTime? lastVisitedAt,
  List<DateTime> revisitHistory = const [],
}) {
  return Achievement(
    id: id,
    title: 'Test Spot',
    description: 'A place for tests',
    tier: AchievementTier.bronze,
    xpReward: 10,
    isUnlocked: isUnlocked,
    unlockedAt: unlockedAt,
    visitCount: visitCount,
    lastVisitedAt: lastVisitedAt,
    revisitHistory: revisitHistory,
  );
}

void main() {
  final t1 = DateTime.utc(2026, 1, 1, 10);
  final t2 = DateTime.utc(2026, 2, 1, 10);
  final t3 = DateTime.utc(2026, 3, 1, 10);

  group('latestDate', () {
    test('handles nulls on either side', () {
      expect(latestDate(null, null), isNull);
      expect(latestDate(t1, null), t1);
      expect(latestDate(null, t2), t2);
    });

    test('returns the later of two dates', () {
      expect(latestDate(t1, t2), t2);
      expect(latestDate(t2, t1), t2);
      expect(latestDate(t1, t1), t1);
    });
  });

  group('unionTimestamps', () {
    test('merges, dedupes and sorts', () {
      final merged = unionTimestamps([t3, t1], [t2, t1]);
      expect(merged, [t1, t2, t3]);
    });

    test('is idempotent', () {
      final once = unionTimestamps([t1, t2], [t2, t3]);
      final twice = unionTimestamps(once, [t2, t3]);
      expect(twice, once);
    });

    test('handles empty inputs', () {
      expect(unionTimestamps([], []), isEmpty);
      expect(unionTimestamps([t1], []), [t1]);
    });
  });

  group('parseRevisitHistory', () {
    test('parses a list of ISO strings', () {
      final parsed =
          parseRevisitHistory([t1.toIso8601String(), t2.toIso8601String()]);
      expect(parsed, [t1, t2]);
    });

    test('skips malformed entries instead of throwing', () {
      final parsed =
          parseRevisitHistory(['not-a-date', t1.toIso8601String(), 42, null]);
      expect(parsed, [t1]);
    });

    test('non-list input yields an empty history', () {
      expect(parseRevisitHistory(null), isEmpty);
      expect(parseRevisitHistory('2026-01-01'), isEmpty);
    });
  });

  group('mergeRemoteRow — restore (locally locked)', () {
    test('restores full unlock state from the remote row', () {
      final local = makeAchievement();
      final merged = mergeRemoteRow(local, {
        'achievement_id': 'test-spot',
        'unlocked_at': t1.toIso8601String(),
        'visit_date': t1.toIso8601String(),
        'notes': 'lovely',
        'is_retroactive': true,
        'photos': ['https://example.com/p.jpg'],
        'visit_count': 3,
        'last_visited_at': t2.toIso8601String(),
        'revisit_history': [t1.toIso8601String(), t2.toIso8601String()],
      });

      expect(merged, isNotNull);
      expect(merged!.isUnlocked, isTrue);
      expect(merged.unlockedAt, t1);
      expect(merged.visitDate, t1);
      expect(merged.notes, 'lovely');
      expect(merged.isRetroactive, isTrue);
      expect(merged.photos, ['https://example.com/p.jpg']);
      expect(merged.visitCount, 3);
      expect(merged.lastVisitedAt, t2);
      expect(merged.revisitHistory, [t1, t2]);
    });

    test('tolerates a sparse remote row (old schema rows)', () {
      final local = makeAchievement();
      final merged = mergeRemoteRow(local, {'achievement_id': 'test-spot'});

      expect(merged, isNotNull);
      expect(merged!.isUnlocked, isTrue);
      expect(merged.visitCount, 0);
      expect(merged.revisitHistory, isEmpty);
      expect(merged.notes, isNull);
    });

    test('malformed remote dates do not throw', () {
      final local = makeAchievement();
      final merged = mergeRemoteRow(local, {
        'unlocked_at': 'garbage',
        'visit_date': 'also garbage',
        'revisit_history': ['nope'],
        'visit_count': 1,
      });

      expect(merged, isNotNull);
      expect(merged!.isUnlocked, isTrue);
      expect(merged.unlockedAt, isNull);
      expect(merged.revisitHistory, isEmpty);
    });
  });

  group('mergeRemoteRow — CRDT merge (locally unlocked)', () {
    test('returns null when remote adds nothing new', () {
      final local = makeAchievement(
        isUnlocked: true,
        visitCount: 3,
        lastVisitedAt: t2,
        revisitHistory: [t1, t2],
      );
      final merged = mergeRemoteRow(local, {
        'visit_count': 2,
        'last_visited_at': t1.toIso8601String(),
        'revisit_history': [t1.toIso8601String()],
      });

      expect(merged, isNull);
    });

    test('takes the max visit count', () {
      final local = makeAchievement(isUnlocked: true, visitCount: 2);
      final merged = mergeRemoteRow(local, {'visit_count': 5});

      expect(merged, isNotNull);
      expect(merged!.visitCount, 5);
    });

    test('takes the latest lastVisitedAt', () {
      final local =
          makeAchievement(isUnlocked: true, visitCount: 1, lastVisitedAt: t1);
      final merged = mergeRemoteRow(local, {
        'visit_count': 1,
        'last_visited_at': t3.toIso8601String(),
      });

      expect(merged, isNotNull);
      expect(merged!.lastVisitedAt, t3);
    });

    test('unions revisit histories', () {
      final local = makeAchievement(
        isUnlocked: true,
        visitCount: 2,
        revisitHistory: [t1],
      );
      final merged = mergeRemoteRow(local, {
        'visit_count': 2,
        'revisit_history': [t2.toIso8601String()],
      });

      expect(merged, isNotNull);
      expect(merged!.revisitHistory, [t1, t2]);
    });

    test('merge is idempotent — replaying the same row is a no-op', () {
      final local = makeAchievement(isUnlocked: true, visitCount: 1);
      final row = {
        'visit_count': 4,
        'last_visited_at': t2.toIso8601String(),
        'revisit_history': [t1.toIso8601String(), t2.toIso8601String()],
      };

      final once = mergeRemoteRow(local, row);
      expect(once, isNotNull);
      expect(mergeRemoteRow(once!, row), isNull);
    });

    test('does not regress unlock metadata on merge', () {
      final local = makeAchievement(
        isUnlocked: true,
        unlockedAt: t1,
        visitCount: 1,
      );
      final merged = mergeRemoteRow(local, {'visit_count': 2});

      expect(merged, isNotNull);
      expect(merged!.isUnlocked, isTrue);
      expect(merged.unlockedAt, t1);
    });
  });
}
