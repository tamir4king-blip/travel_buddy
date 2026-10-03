import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/notification_provider.dart';
import 'package:travel_buddy_mobile/shared/services/notification_service.dart';
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';

class NearbyAchievementsState {
  final List<Achievement> nearby;
  final List<Achievement> newlyDiscovered;

  /// Achievements that were just revisited this cycle (for UI feedback).
  final List<Achievement> newRevisits;

  const NearbyAchievementsState({
    this.nearby = const [],
    this.newlyDiscovered = const [],
    this.newRevisits = const [],
  });

  bool get hasNearby => nearby.isNotEmpty;
  int get nearbyCount => nearby.length;
}

class NearbyAchievementsNotifier extends StateNotifier<NearbyAchievementsState> {
  NearbyAchievementsNotifier(this._ref) : super(const NearbyAchievementsState()) {
    _ref.listen(geolocationProvider, (_, geo) => _recompute(geo));
    _ref.listen(achievementsProvider, (_, __) => _recompute(_ref.read(geolocationProvider)));
    // Initial computation
    _recompute(_ref.read(geolocationProvider));
  }

  final Ref _ref;
  final Set<String> _previouslyNearby = {};

  Future<void> _recompute(GeolocationState geo) async {
    if (!geo.hasLocation) {
      state = const NearbyAchievementsState();
      return;
    }

    final achievements = _ref.read(achievementsProvider);

    // ── Unlockable achievements nearby (not yet unlocked) ──
    final nearby = achievements.allAchievements.where((a) {
      if (!a.hasGeofence) return false;
      if (a.isUnlocked) return false;
      return isWithinClaimArea(geo.latitude!, geo.longitude!, a);
    }).toList();

    final nearbyIds = nearby.map((a) => a.id).toSet();
    final newlyDiscovered = nearby
        .where((a) => !_previouslyNearby.contains(a.id))
        .toList();

    _previouslyNearby
      ..clear()
      ..addAll(nearbyIds);

    // Auto-mark newly discovered achievements as pending claims
    // and send phone notifications
    if (newlyDiscovered.isNotEmpty && geo.isLiveTracking) {
      final achievementsNotifier = _ref.read(achievementsProvider.notifier);
      final notificationsEnabled = _ref.read(notificationsEnabledProvider);
      NotificationService? notificationService;
      try {
        notificationService = _ref.read(notificationServiceProvider);
      } catch (e, st) {
        // Provider not yet available
        logError(e, st, context: 'nearby.notificationProvider');
      }

      for (final achievement in newlyDiscovered) {
        // Skip if already pending
        if (achievement.isPendingClaim) continue;

        final wasMarked = await achievementsNotifier.markPendingClaim(achievement.id);
        if (wasMarked && notificationsEnabled && notificationService != null) {
          final distance = geo.distanceTo(achievement.latitude!, achievement.longitude!);
          notificationService.showProximityNotification(
            id: achievement.hashCode,
            title: 'Trophy nearby: ${achievement.title}',
            body: '${distance.round()}m away - ${achievement.xpReward} XP! Open the app to claim it.',
          );
        }
      }
    }

    // ── Auto-revisit: already-unlocked achievements nearby ──
    final newRevisits = <Achievement>[];
    if (geo.isLiveTracking) {
      final achievementsNotifier = _ref.read(achievementsProvider.notifier);
      final notificationsEnabled = _ref.read(notificationsEnabledProvider);
      NotificationService? notificationService;
      try {
        notificationService = _ref.read(notificationServiceProvider);
      } catch (e, st) {
        // Provider not yet available
        logError(e, st, context: 'nearby.notificationProvider');
      }

      for (final a in achievements.allAchievements) {
        if (!a.isUnlocked) continue;
        if (!a.hasGeofence) continue;
        if (!isWithinClaimArea(geo.latitude!, geo.longitude!, a)) continue;

        final marked = await achievementsNotifier.recordRevisit(a.id);
        if (marked) {
          // Re-read to get the updated state
          final updated = _ref.read(achievementsProvider).allAchievements
              .firstWhere((x) => x.id == a.id);
          newRevisits.add(updated);

          if (notificationsEnabled && notificationService != null) {
            notificationService.showProximityNotification(
              id: a.hashCode + 10000,
              title: 'Revisit recorded: ${a.title}',
              body: 'Visit #${updated.visitCount} logged! Open the app to claim it.',
            );
          }
        }
      }
    }

    state = NearbyAchievementsState(
      nearby: nearby,
      newlyDiscovered: newlyDiscovered,
      newRevisits: newRevisits,
    );
  }

  void clearNewlyDiscovered() {
    state = NearbyAchievementsState(
      nearby: state.nearby,
      newRevisits: state.newRevisits,
    );
  }

  void clearNewRevisits() {
    state = NearbyAchievementsState(
      nearby: state.nearby,
      newlyDiscovered: state.newlyDiscovered,
    );
  }
}

final nearbyAchievementsProvider =
    StateNotifierProvider<NearbyAchievementsNotifier, NearbyAchievementsState>(
  (ref) => NearbyAchievementsNotifier(ref),
);
