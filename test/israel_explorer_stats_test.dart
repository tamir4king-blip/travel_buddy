import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/utils/israel_explorer_stats.dart';

/// The Israel registry with [ids] unlocked (optionally with visit counts).
List<Achievement> withUnlocked(Map<String, int> ids) => [
      for (final a in israelAchievementRegistry)
        ids.containsKey(a.id)
            ? a.copyWith(isUnlocked: true, visitCount: ids[a.id])
            : a,
    ];

void main() {
  test('nothing unlocked → empty profile, newcomer rank', () {
    final stats = IsraelExplorerStats.fromAchievements(israelAchievementRegistry);
    expect(stats.visited, 0);
    expect(stats.total, israelPlaces.length);
    expect(stats.dna, isEmpty);
    expect(stats.archetype('en'), isNull);
    expect(stats.regionsVisited, 0);
    expect(stats.rank, ExplorerRank.newcomer);
    expect(stats.spanKm, isNull);
  });

  test('a desert-heavy traveler becomes a Desert Wanderer', () {
    final stats = IsraelExplorerStats.fromAchievements(withUnlocked({
      'il-masada': 1,
      'il-makhtesh-ramon': 1,
      'il-ein-avdat': 1,
      'il-avdat': 1,
      'il-timna': 1,
      'il-tel-aviv': 1,
    }));

    expect(stats.visited, 6);
    expect(stats.primaryFacet, IsraelFacet.desert);
    expect(stats.archetype('en'), startsWith('Desert Wanderer'));
    expect(stats.archetype('he'), startsWith('נווד/ת מדבר'));
    expect(stats.rank, ExplorerRank.wanderer);
    expect(stats.regionCounts.keys,
        containsAll([IsraelRegion.deadSea, IsraelRegion.negevHighlands]));
    // Shares add up to 1.
    final sum = stats.dna.fold<double>(0, (s, f) => s + f.share);
    expect(sum, closeTo(1, 1e-9));
  });

  test('extremes span from Metula to Eilat, ignoring region geofences', () {
    final stats = IsraelExplorerStats.fromAchievements(withUnlocked({
      'il-metula': 1,
      'il-coral-beach': 1,
      'il-region-golan': 1, // wide geofence — must not count as an extreme
      'il-jerusalem': 3,
    }));

    expect(stats.northernmost!.id, 'il-metula');
    expect(stats.southernmost!.id, 'il-coral-beach');
    expect(stats.spanKm, inInclusiveRange(400, 440));
    expect(stats.mostRevisited!.id, 'il-jerusalem');
  });

  test('list progress and rarest finds', () {
    final stats = IsraelExplorerStats.fromAchievements(withUnlocked({
      'il-tel-aviv': 1,
      'il-haifa': 1,
      'il-masada': 1, // platinum
      'il-acre-old-city': 1, // platinum
    }));

    final cities =
        stats.lists.firstWhere((l) => l.list == IsraelList.cities);
    expect(cities.unlocked, 2);
    expect(cities.total, israelPlaces.where((p) => p.list == IsraelList.cities).length);
    expect(cities.isComplete, isFalse);

    expect(stats.rarest.first.tier, AchievementTier.platinum);
    expect(stats.rarest.map((a) => a.id),
        containsAll(['il-masada', 'il-acre-old-city']));
  });

  test('rank thresholds', () {
    expect(ExplorerRank.forPlaces(0), ExplorerRank.newcomer);
    expect(ExplorerRank.forPlaces(4), ExplorerRank.newcomer);
    expect(ExplorerRank.forPlaces(5), ExplorerRank.wanderer);
    expect(ExplorerRank.forPlaces(50), ExplorerRank.trailblazer);
    expect(ExplorerRank.forPlaces(1000), ExplorerRank.legend);
    expect(ExplorerRank.legend.next, isNull);
    expect(ExplorerRank.newcomer.next, ExplorerRank.wanderer);
  });

  test('non-Israel achievements are ignored', () {
    final other = const Achievement(
      id: 'europe-france', title: 'France', description: '',
      tier: AchievementTier.silver, xpReward: 20, isUnlocked: true,
      collectionId: 'europe',
    );
    final stats = IsraelExplorerStats.fromAchievements(
        [...israelAchievementRegistry, other]);
    expect(stats.visited, 0);
  });
}
