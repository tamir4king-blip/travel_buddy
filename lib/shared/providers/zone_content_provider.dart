import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quest_chain_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';

/// Radius (in meters) used to find nearby quests and achievements.
/// 100 km covers a city-sized zone.
const _zoneRadiusMeters = 100000.0;

/// A nearby item with its distance from the user.
class NearbyItem<T> {
  final T item;

  /// Distance in meters from the user.
  final double distanceMeters;

  const NearbyItem({required this.item, required this.distanceMeters});
}

class ZoneContentState {
  // ── Trophies ──

  /// All travel achievements in the zone (locked + unlocked).
  final int totalTravelTrophies;

  /// Travel achievements already unlocked in the zone.
  final int unlockedTravelTrophies;

  /// All activities in the zone (first-time trophy per activity).
  final int totalActivityTrophies;

  /// Activities already completed at least once (trophy earned).
  final int earnedActivityTrophies;

  // ── Activities ──

  /// All skill activities in the zone that can still be done.
  final int totalActivities;

  /// Activities the user has completed at least once.
  final int completedActivities;

  /// All activities in the zone (including fully maxed ones), for total count.
  final int totalActivitiesInZone;

  // ── Nearby item lists (sorted by distance) ──

  /// Achievements in the zone with distances.
  final List<NearbyItem<Achievement>> nearbyAchievements;

  /// Activities in the zone with distances.
  final List<NearbyItem<SideQuest>> nearbyActivities;

  /// Active story quests that have steps targeting items in this zone.
  final List<Quest> nearbyQuests;

  const ZoneContentState({
    this.totalTravelTrophies = 0,
    this.unlockedTravelTrophies = 0,
    this.totalActivityTrophies = 0,
    this.earnedActivityTrophies = 0,
    this.totalActivities = 0,
    this.completedActivities = 0,
    this.totalActivitiesInZone = 0,
    this.nearbyAchievements = const [],
    this.nearbyActivities = const [],
    this.nearbyQuests = const [],
  });

  /// Total trophies in the zone (travel + activity first-time).
  int get totalTrophies => totalTravelTrophies + totalActivityTrophies;

  /// Trophies already earned.
  int get earnedTrophies => unlockedTravelTrophies + earnedActivityTrophies;

  /// Trophies remaining.
  int get remainingTrophies => totalTrophies - earnedTrophies;

  /// Trophy progress 0.0–1.0.
  double get trophyProgress =>
      totalTrophies > 0 ? earnedTrophies / totalTrophies : 0.0;

  /// Activity progress 0.0–1.0 (based on at-least-once completion).
  double get activityProgress =>
      totalActivitiesInZone > 0
          ? completedActivities / totalActivitiesInZone
          : 0.0;

  /// Overall zone progress (average of trophy + activity progress).
  double get overallProgress {
    var count = 0;
    var sum = 0.0;
    if (totalTrophies > 0) {
      sum += trophyProgress;
      count++;
    }
    if (totalActivitiesInZone > 0) {
      sum += activityProgress;
      count++;
    }
    return count > 0 ? sum / count : 0.0;
  }

  bool get isEmpty => totalTrophies == 0 && totalActivitiesInZone == 0;
}

class ZoneContentNotifier extends StateNotifier<ZoneContentState> {
  final Ref _ref;

  ZoneContentNotifier(this._ref) : super(const ZoneContentState()) {
    _ref.listen(geolocationProvider, (_, __) => _recompute());
    _ref.listen(achievementsProvider, (_, __) => _recompute());
    _ref.listen(questsProvider, (_, __) => _recompute());
    _ref.listen(questChainProvider, (_, __) => _recompute());
    _recompute();
  }

  void _recompute() {
    final geo = _ref.read(geolocationProvider);
    if (!geo.hasLocation) {
      state = const ZoneContentState();
      return;
    }

    final userLat = geo.latitude!;
    final userLng = geo.longitude!;

    // ── Travel achievements in zone (all, including unlocked) ──
    final allAchievements = _ref.read(achievementsProvider).allAchievements;
    var totalTravel = 0;
    var unlockedTravel = 0;
    final nearbyAchievements = <NearbyItem<Achievement>>[];

    for (final a in allAchievements) {
      if (a.latitude == null || a.longitude == null) continue;
      final distance = Geolocator.distanceBetween(
          userLat, userLng, a.latitude!, a.longitude!);
      final inZone =
          distance <= _zoneRadiusMeters || distance <= (a.claimRadius ?? 0);
      if (!inZone) continue;
      totalTravel++;
      if (a.isUnlocked) unlockedTravel++;
      nearbyAchievements.add(NearbyItem(item: a, distanceMeters: distance));
    }

    nearbyAchievements.sort((a, b) =>
        a.distanceMeters.compareTo(b.distanceMeters));

    // ── Activities in zone ──
    final questState = _ref.read(questsProvider);
    var totalActivityTrophies = 0;
    var earnedActivityTrophies = 0;
    var totalActivities = 0; // can still do
    var completedActivities = 0; // done at least once
    var totalActivitiesInZone = 0; // all in zone
    final nearbyActivities = <NearbyItem<SideQuest>>[];

    for (final q in questState.allQuests) {
      final distance = _questDistance(q, userLat, userLng);
      if (distance == null || distance > _zoneRadiusMeters) continue;

      totalActivitiesInZone++;
      totalActivityTrophies++; // each activity = one possible first-time trophy

      if (q.completionCount > 0) {
        earnedActivityTrophies++;
        completedActivities++;
      }

      final canDo = !q.isCompleted ||
          (q.isRepeatable && q.completionCount < q.maxCompletions);
      if (canDo) totalActivities++;

      nearbyActivities.add(NearbyItem(item: q, distanceMeters: distance));
    }

    nearbyActivities.sort((a, b) =>
        a.distanceMeters.compareTo(b.distanceMeters));

    // ── Story quests with steps in zone ──
    final nearbyAchievementIds =
        nearbyAchievements.map((n) => n.item.id).toSet();
    final nearbyActivityIds =
        nearbyActivities.map((n) => n.item.id).toSet();

    final chainState = _ref.read(questChainProvider);
    final nearbyQuests = <Quest>[];
    for (final quest in chainState.activeQuests) {
      final hasStepInZone = quest.steps.any((step) {
        if (step.isCompleted) return false;
        return (step.type == QuestStepType.achievement &&
                nearbyAchievementIds.contains(step.targetId)) ||
            (step.type == QuestStepType.activity &&
                nearbyActivityIds.contains(step.targetId));
      });
      if (hasStepInZone) nearbyQuests.add(quest);
    }

    state = ZoneContentState(
      totalTravelTrophies: totalTravel,
      unlockedTravelTrophies: unlockedTravel,
      totalActivityTrophies: totalActivityTrophies,
      earnedActivityTrophies: earnedActivityTrophies,
      totalActivities: totalActivities,
      completedActivities: completedActivities,
      totalActivitiesInZone: totalActivitiesInZone,
      nearbyAchievements: nearbyAchievements,
      nearbyActivities: nearbyActivities,
      nearbyQuests: nearbyQuests,
    );
  }

  double? _questDistance(SideQuest q, double userLat, double userLng) {
    if (q.latitude == null || q.longitude == null) return null;
    return Geolocator.distanceBetween(
        userLat, userLng, q.latitude!, q.longitude!);
  }
}

final zoneContentProvider =
    StateNotifierProvider<ZoneContentNotifier, ZoneContentState>(
  (ref) => ZoneContentNotifier(ref),
);
