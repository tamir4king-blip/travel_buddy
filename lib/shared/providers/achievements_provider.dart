import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';
import 'package:travel_buddy_mobile/shared/utils/achievement_merge.dart';
import 'package:travel_buddy_mobile/shared/utils/xp_rules.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/auth_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';
import 'package:travel_buddy_mobile/shared/data/travel_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/lakes_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/glaciers_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/deserts_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/local_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';
import 'package:travel_buddy_mobile/shared/providers/achievement_definitions_provider.dart';

/// Data class for retroactive achievement claims
class RetroactiveClaimData {
  final DateTime visitDate;
  final List<String> photos;
  final String? notes;

  const RetroactiveClaimData({
    required this.visitDate,
    this.photos = const [],
    this.notes,
  });
}

class AchievementsState {
  final List<Achievement> allAchievements;
  final List<Achievement> unlockedAchievements;
  final AchievementTier? filterTier;
  final String? filterCollection;
  final String searchQuery;
  final Set<String> completedCollections;

  const AchievementsState({
    this.allAchievements = const [],
    this.unlockedAchievements = const [],
    this.filterTier,
    this.filterCollection,
    this.searchQuery = '',
    this.completedCollections = const {},
  });

  List<Achievement> get filteredAchievements {
    var list = allAchievements;
    if (filterTier != null) {
      list = list.where((a) => a.tier == filterTier).toList();
    }
    if (filterCollection != null) {
      list = list.where((a) => a.collectionId == filterCollection).toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((a) =>
          a.title.toLowerCase().contains(query) ||
          a.description.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  int get totalUnlocked => unlockedAchievements.length;
  int get totalAchievements => allAchievements.length;

  AchievementsState copyWith({
    List<Achievement>? allAchievements,
    List<Achievement>? unlockedAchievements,
    AchievementTier? filterTier,
    String? filterCollection,
    String? searchQuery,
    Set<String>? completedCollections,
    bool clearTierFilter = false,
    bool clearCollectionFilter = false,
  }) {
    return AchievementsState(
      allAchievements: allAchievements ?? this.allAchievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      filterTier: clearTierFilter ? null : (filterTier ?? this.filterTier),
      filterCollection: clearCollectionFilter
          ? null
          : (filterCollection ?? this.filterCollection),
      searchQuery: searchQuery ?? this.searchQuery,
      completedCollections: completedCollections ?? this.completedCollections,
    );
  }
}

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final Ref ref;

  AchievementsNotifier(this.ref) : super(const AchievementsState()) {
    _loadAchievements();
    // Sync from Supabase in background after local load
    _syncFromRemote();

    // Re-sync when auth state changes (e.g. after login on a fresh install).
    // Without this, _syncFromRemote() silently returns if the user isn't
    // authenticated yet when the provider is first created.
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        _syncFromRemote();
      }
    });

    // React to achievement definition updates (e.g. when Supabase fetch
    // completes and new polygons/radii arrive). Rebuild state using the new
    // definitions while preserving per-user unlock + revisit state.
    ref.listen<List<Achievement>>(achievementDefinitionsProvider,
        (prev, next) {
      if (identical(prev, next)) return;
      _rebuildWithDefinitions(next);
    });
  }

  /// Swap in new definitions (polygons, radii, titles from Supabase) while
  /// keeping the current per-user state (unlocked, visitCount, etc.).
  void _rebuildWithDefinitions(List<Achievement> newDefinitions) {
    final savedById = {for (final a in state.allAchievements) a.id: a};

    final rebuilt = newDefinitions.map((def) {
      final saved = savedById[def.id];
      if (saved == null) return def;
      return Achievement(
        id: def.id,
        title: def.title,
        description: def.description,
        iconName: def.iconName,
        tier: def.tier,
        xpReward: def.xpReward,
        latitude: def.latitude,
        longitude: def.longitude,
        claimRadius: def.claimRadius,
        claimPolygon: def.claimPolygon,
        collectionId: def.collectionId,
        tags: def.tags,
        // Preserve user state
        isUnlocked: saved.isUnlocked,
        unlockedAt: saved.unlockedAt,
        visitDate: saved.visitDate,
        photos: saved.photos,
        notes: saved.notes,
        isRetroactive: saved.isRetroactive,
        isPendingClaim: saved.isPendingClaim,
        pendingClaimAt: saved.pendingClaimAt,
        visitCount: saved.visitCount,
        lastVisitedAt: saved.lastVisitedAt,
        isPendingRevisit: saved.isPendingRevisit,
        revisitHistory: saved.revisitHistory,
      );
    }).toList();

    state = state.copyWith(
      allAchievements: rebuilt,
      unlockedAchievements: rebuilt.where((a) => a.isUnlocked).toList(),
    );
  }

  void _loadAchievements() {
    try {
      final persistence = ref.read(persistenceServiceProvider);
      final savedAchievements = persistence.loadUnlockedAchievements();
      final savedCollections = persistence.loadCompletedCollections();
      final pendingClaims = persistence.loadPendingClaims();

      // Use definitions provider (merges Supabase + hardcoded)
      final registry = ref.read(achievementDefinitionsProvider);

      // Build a map of saved data by id
      final savedMap = <String, Map<String, dynamic>>{};
      for (final json in savedAchievements) {
        final id = json['id'] as String?;
        if (id != null) savedMap[id] = json;
      }

      // Merge saved state onto registry
      final merged = registry.map((a) {
        var achievement = a;
        final saved = savedMap[a.id];
        if (saved != null) {
          achievement = Achievement.fromJsonOverlay(a, saved);
        }
        // Restore pending claim state
        final pendingAt = pendingClaims[a.id];
        if (pendingAt != null && !achievement.isUnlocked) {
          achievement = achievement.copyWith(
            isPendingClaim: true,
            pendingClaimAt: DateTime.parse(pendingAt),
          );
        }
        return achievement;
      }).toList();

      state = AchievementsState(
        allAchievements: merged,
        unlockedAchievements: merged.where((a) => a.isUnlocked).toList(),
        completedCollections: savedCollections,
      );
    } catch (e, st) {
      // If persistence data is corrupted, load fresh from registry
      logError(e, st, context: 'achievements.loadFromStorage', report: true);
      state = AchievementsState(
        allAchievements: achievementRegistry,
        unlockedAchievements: const [],
        completedCollections: const {},
      );
    }
  }

  /// Fetches unlocked achievements from Supabase and merges with local state.
  /// Remote achievements that aren't in local state are added (e.g. from another device).
  /// Local achievements that aren't in remote are synced up.
  Future<void> _syncFromRemote() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Send revisits recorded offline first, so the rows pulled below
      // already reflect the server's verdict on them.
      await _flushRevisitQueue();

      final rows = await client
          .from('user_achievements')
          .select()
          .eq('user_id', userId);

      if (rows.isEmpty) {
        // No remote data — push local unlocked achievements to Supabase,
        // then pull back the profile the server-side XP triggers updated.
        await _syncAllToRemote();
        await ref.read(userProfileProvider.notifier).reloadFromRemote();
        return;
      }

      // Build a map of remote unlocked achievements by achievement_id
      final remoteMap = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final id = row['achievement_id'] as String?;
        if (id != null) remoteMap[id] = row;
      }

      // Merge: if remote has an achievement unlocked that local doesn't, unlock it locally
      var changed = false;
      final updatedAll = [...state.allAchievements];
      final updatedUnlocked = [...state.unlockedAchievements];

      for (var i = 0; i < updatedAll.length; i++) {
        final a = updatedAll[i];
        final remote = remoteMap[a.id];
        if (remote == null) continue;

        final merged = mergeRemoteRow(a, remote);
        if (merged == null) continue;

        updatedAll[i] = merged;
        if (!a.isUnlocked) {
          // Remote says unlocked but local doesn't — restored full state
          updatedUnlocked.add(merged);
        } else {
          final unlockedIdx = updatedUnlocked.indexWhere((u) => u.id == a.id);
          if (unlockedIdx != -1) updatedUnlocked[unlockedIdx] = merged;
        }
        changed = true;
      }

      // Also fetch completed collections from remote
      final collectionRows = await client
          .from('user_completed_collections')
          .select('collection_id')
          .eq('user_id', userId);
      final remoteCollections = collectionRows
          .map((r) => r['collection_id'] as String)
          .toSet();

      // Recompute completed collections by checking all distinct collection IDs
      final completedCollections = <String>{
        ...state.completedCollections,
        ...remoteCollections,
      };
      final allCollectionIds = updatedAll
          .map((a) => a.collectionId)
          .whereType<String>()
          .toSet();
      for (final collectionId in allCollectionIds) {
        if (!completedCollections.contains(collectionId)) {
          final all = updatedAll.where((a) => a.collectionId == collectionId);
          if (all.isNotEmpty && all.every((a) => a.isUnlocked)) {
            completedCollections.add(collectionId);
          }
        }
      }

      if (changed || completedCollections.length > state.completedCollections.length) {
        state = state.copyWith(
          allAchievements: updatedAll,
          unlockedAchievements: updatedUnlocked,
          completedCollections: completedCollections,
        );
        await _persistLocally();
      }

      // Push local state back to remote. After the CRDT merge above, local
      // holds the winning value for each field. Pushing everything ensures:
      //   - unlocks made offline are synced up
      //   - revisit counts/history made offline are synced up
      //   - remote stays authoritative for cross-device restore
      await _syncAllToRemote();

      // Server-side triggers may have just awarded XP for rows that only
      // existed locally — pull the authoritative total back down.
      await ref.read(userProfileProvider.notifier).reloadFromRemote();
    } catch (e, st) {
      // Local data is primary, retry on next sync
      logError(e, st, context: 'achievements.syncWithRemote', report: true);
    }
  }

  /// Push all locally unlocked achievements to Supabase in one batched
  /// upsert (instead of a round trip per achievement).
  Future<void> _syncAllToRemote() async {
    if (!SupabaseConfig.isConfigured) return;
    if (state.unlockedAchievements.isEmpty) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final rows = state.unlockedAchievements
          .map((a) => _remoteRow(userId, a))
          .toList();

      await client
          .from('user_achievements')
          .upsert(rows, onConflict: 'user_id,achievement_id');
    } catch (e, st) {
      // Will retry on next sync
      logError(e, st, context: 'achievements.syncAllToRemote', report: true);
    }
  }

  /// Upsert a single achievement to the user_achievements table.
  Future<void> _upsertAchievementToRemote(Achievement a) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client
          .from('user_achievements')
          .upsert(_remoteRow(userId, a), onConflict: 'user_id,achievement_id');
    } catch (e, st) {
      // Will retry on next sync
      logError(e, st, context: 'achievements.upsertToRemote', report: true);
    }
  }

  /// The `user_achievements` columns clients may write.
  ///
  /// visit_count, last_visited_at and revisit_history are owned by the
  /// revisit RPCs — the server's column grants reject them here. The column
  /// defaults handle the initial unlock row (visit_count = 1, others empty).
  ///
  /// Timestamps go out as UTC: a local DateTime serializes without an
  /// offset, which Postgres would read as UTC and shift by the device's
  /// timezone (breaking the server-side revisit cooldown anchor).
  static Map<String, dynamic> _remoteRow(String userId, Achievement a) => {
        'user_id': userId,
        'achievement_id': a.id,
        'unlocked_at': a.unlockedAt?.toUtc().toIso8601String(),
        'visit_date': a.visitDate?.toUtc().toIso8601String(),
        'notes': a.notes,
        'is_retroactive': a.isRetroactive,
        'photos': a.photos,
      };

  /// Save to local persistence only (no remote sync).
  Future<void> _persistLocally() async {
    final persistence = ref.read(persistenceServiceProvider);
    final unlockedJsons = state.unlockedAchievements
        .map((a) => a.toJson())
        .toList();
    await persistence.saveUnlockedAchievements(unlockedJsons);
    await persistence.saveCompletedCollections(state.completedCollections);

    final pendingClaims = <String, String>{};
    for (final a in state.allAchievements) {
      if (a.isPendingClaim && !a.isUnlocked && a.pendingClaimAt != null) {
        pendingClaims[a.id] = a.pendingClaimAt!.toIso8601String();
      }
    }
    await persistence.savePendingClaims(pendingClaims);
  }

  /// Persists locally and optionally syncs a specific achievement to Supabase.
  Future<void> _persist({Achievement? syncToRemote, String? newlyCompletedCollection}) async {
    await _persistLocally();

    if (syncToRemote != null && syncToRemote.isUnlocked) {
      _upsertAchievementToRemote(syncToRemote);
    }
    if (newlyCompletedCollection != null) {
      _upsertCompletedCollectionToRemote(newlyCompletedCollection);
    }
  }

  /// Upsert a completed collection to the user_completed_collections table.
  Future<void> _upsertCompletedCollectionToRemote(String collectionId) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('user_completed_collections').upsert({
        'user_id': userId,
        'collection_id': collectionId,
      }, onConflict: 'user_id,collection_id');
    } catch (e, st) {
      logError(e, st,
          context: 'achievements.upsertCompletedCollection', report: true);
    }
  }

  /// Mark an achievement as pending claim (detected nearby via background tracking).
  /// Returns true if newly marked as pending.
  Future<bool> markPendingClaim(String achievementId) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked || achievement.isPendingClaim) return false;

    final pending = achievement.copyWith(
      isPendingClaim: true,
      pendingClaimAt: DateTime.now(),
    );

    final updatedAll = [...state.allAchievements];
    updatedAll[index] = pending;

    state = state.copyWith(allAchievements: updatedAll);
    await _persist();
    return true;
  }

  /// Confirm a pending claim — fully unlock the achievement.
  Future<bool> confirmPendingClaim(String achievementId) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked) return false;

    final now = DateTime.now();
    final unlocked = achievement.copyWith(
      isUnlocked: true,
      unlockedAt: now,
      // The user was physically there when the claim was detected, which
      // may be hours before they tapped confirm.
      visitDate: achievement.pendingClaimAt ?? now,
      isPendingClaim: false,
      clearPendingClaimAt: true,
      visitCount: 1,
      lastVisitedAt: now,
    );

    final updatedAll = [...state.allAchievements];
    updatedAll[index] = unlocked;

    // Check for collection completion
    final collectionId = achievement.collectionId;
    var completedCollections = Set<String>.from(state.completedCollections);
    String? newlyCompletedCollection;

    if (collectionId != null && !completedCollections.contains(collectionId)) {
      final collectionAchievements =
          updatedAll.where((a) => a.collectionId == collectionId).toList();
      final allUnlocked = collectionAchievements.every((a) => a.isUnlocked);
      if (allUnlocked) {
        completedCollections.add(collectionId);
        newlyCompletedCollection = collectionId;
      }
    }

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: [...state.unlockedAchievements, unlocked],
      completedCollections: completedCollections,
    );

    // Award XP
    ref.read(userProfileProvider.notifier).addXp(achievement.xpReward);

    // Award collection bonus XP if newly completed
    if (newlyCompletedCollection != null) {
      _lastCompletedCollection = newlyCompletedCollection;
      final bonusXp = _collectionBonusXp(newlyCompletedCollection);
      if (bonusXp > 0) {
        ref.read(userProfileProvider.notifier).addXp(bonusXp);
      }
    }

    await _persist(syncToRemote: unlocked, newlyCompletedCollection: newlyCompletedCollection);
    return true;
  }

  /// Reload pending claims AND revisit updates from SharedPreferences
  /// (e.g. after the background service has written new entries while the
  /// app was suspended). Merges higher visit counts, latest lastVisitedAt,
  /// and any new revisit history entries back into state, then validates
  /// the new revisits with Supabase so the server matches.
  Future<void> refreshFromStorage() async {
    final persistence = ref.read(persistenceServiceProvider);
    await persistence.reload();

    final pendingClaims = persistence.loadPendingClaims();
    final savedUnlocked = persistence.loadUnlockedAchievements();
    final savedMap = <String, Map<String, dynamic>>{};
    for (final json in savedUnlocked) {
      final id = json['id'] as String?;
      if (id != null) savedMap[id] = json;
    }

    var changed = false;
    final updatedAll = [...state.allAchievements];
    final updatedUnlocked = [...state.unlockedAchievements];
    // Revisit timestamps the background service recorded that the main
    // isolate hasn't seen yet, per achievement id.
    final backgroundRevisits = <String, List<DateTime>>{};

    for (var i = 0; i < updatedAll.length; i++) {
      final a = updatedAll[i];

      // 1) Pending claim from background
      final pendingAt = pendingClaims[a.id];
      if (pendingAt != null && !a.isUnlocked && !a.isPendingClaim) {
        updatedAll[i] = a.copyWith(
          isPendingClaim: true,
          pendingClaimAt: DateTime.parse(pendingAt),
        );
        changed = true;
      }

      // 2) Revisit data from background — merge if storage has newer values
      if (a.isUnlocked) {
        final saved = savedMap[a.id];
        if (saved == null) continue;

        final savedCount = saved['visitCount'] as int? ?? 0;
        final savedLastVisited = saved['lastVisitedAt'] != null
            ? DateTime.tryParse(saved['lastVisitedAt'] as String)
            : null;
        final savedHistory = (saved['revisitHistory'] as List<dynamic>?)
                ?.map((d) => DateTime.parse(d as String))
                .toList() ??
            const <DateTime>[];
        final savedPendingRevisit = saved['isPendingRevisit'] as bool? ?? false;

        final needsUpdate = savedCount > a.visitCount ||
            (savedLastVisited != null &&
                (a.lastVisitedAt == null ||
                    savedLastVisited.isAfter(a.lastVisitedAt!))) ||
            savedHistory.length > a.revisitHistory.length ||
            (savedPendingRevisit && !a.isPendingRevisit);

        if (needsUpdate) {
          final newEntries = savedHistory
              .where((d) => !a.revisitHistory.any((h) => h.isAtSameMomentAs(d)))
              .toList();
          if (newEntries.isNotEmpty) backgroundRevisits[a.id] = newEntries;

          final merged = updatedAll[i].copyWith(
            visitCount:
                savedCount > updatedAll[i].visitCount ? savedCount : null,
            lastVisitedAt: savedLastVisited != null &&
                    (updatedAll[i].lastVisitedAt == null ||
                        savedLastVisited.isAfter(updatedAll[i].lastVisitedAt!))
                ? savedLastVisited
                : null,
            revisitHistory: savedHistory.length > updatedAll[i].revisitHistory.length
                ? savedHistory
                : null,
            isPendingRevisit: savedPendingRevisit ? true : null,
          );
          updatedAll[i] = merged;
          final ui =
              updatedUnlocked.indexWhere((u) => u.id == a.id);
          if (ui != -1) updatedUnlocked[ui] = merged;
          changed = true;
        }
      }
    }

    if (changed) {
      state = state.copyWith(
        allAchievements: updatedAll,
        unlockedAchievements: updatedUnlocked,
      );
      // Persist the merged state locally so we don't drift from background
      await _persistLocally();

      // Queue each background-recorded revisit (with its real timestamp) for
      // server validation. The server accepts or rejects each one by its own
      // cooldown, so direct SharedPreferences edits can't inflate counts.
      for (final entry in backgroundRevisits.entries) {
        await _queueRevisitSync(entry.key, entry.value);
      }
    }

    // Also retries anything left from an earlier offline session.
    await _flushRevisitQueue();
  }

  // ── Server revisit sync ────────────────────────────────────────────────────

  /// Revisits recorded without server confirmation (offline GPS revisits and
  /// background-service revisits), queued until `register_revisit` decides.
  Future<void> _queueRevisitSync(String achievementId, List<DateTime> at) async {
    if (at.isEmpty) return;
    final persistence = ref.read(persistenceServiceProvider);
    final queue = persistence.loadPendingRevisitSync();
    queue[achievementId] = [
      ...?queue[achievementId],
      ...at.map((d) => d.toUtc().toIso8601String()),
    ];
    await persistence.savePendingRevisitSync(queue);
  }

  bool _flushingRevisits = false;

  /// Replay queued revisits through `register_revisit`, oldest first. Each
  /// entry leaves the queue once the server has answered (accept or
  /// reject); a network error stops the flush and keeps the rest for the
  /// next sync.
  Future<void> _flushRevisitQueue() async {
    if (_flushingRevisits || !SupabaseConfig.isConfigured) return;
    final client = ref.read(supabaseClientProvider);
    if (client.auth.currentUser?.id == null) return;

    _flushingRevisits = true;
    final persistence = ref.read(persistenceServiceProvider);
    try {
      final queue = persistence.loadPendingRevisitSync();
      for (final id in queue.keys.toList()) {
        final pending = [...queue[id]!]..sort();
        while (pending.isNotEmpty) {
          final response = await client.rpc('register_revisit',
              params: {'ach_id': id, 'visited_at': pending.first});
          pending.removeAt(0);
          if (pending.isEmpty) {
            queue.remove(id);
          } else {
            queue[id] = [...pending];
          }
          await persistence.savePendingRevisitSync(queue);
          await _reconcileRevisit(id, response);
        }
      }
    } catch (e, st) {
      // Network error — remaining entries retry on next sync/resume.
      logError(e, st, context: 'achievements.flushRevisitQueue', report: true);
    } finally {
      _flushingRevisits = false;
    }
  }

  /// Overwrite the local revisit fields with the server's values from a
  /// revisit RPC response (for both accept and reject — the server is the
  /// source of truth). Returns whether the server accepted the change.
  Future<bool> _reconcileRevisit(String achievementId, Object? response,
      {bool markPendingRevisit = false}) async {
    if (response is! Map) return false;
    final accepted = response['accepted'] as bool? ?? false;
    final serverCount = (response['visit_count'] as num?)?.toInt();
    if (serverCount == null) return accepted;

    final idx = state.allAchievements.indexWhere((x) => x.id == achievementId);
    if (idx == -1) return accepted;

    final reconciled = state.allAchievements[idx].copyWith(
      visitCount: serverCount,
      lastVisitedAt: response['last_visited_at'] is String
          ? DateTime.tryParse(response['last_visited_at'] as String)
          : null,
      revisitHistory: response.containsKey('revisit_history')
          ? parseRevisitHistory(response['revisit_history'])
          : null,
      isPendingRevisit: accepted && markPendingRevisit ? true : null,
    );
    _commitAchievement(idx, reconciled);
    await _persistLocally();
    return accepted;
  }

  /// Get all achievements with pending claims.
  List<Achievement> get pendingClaims =>
      state.allAchievements.where((a) => a.isPendingClaim && !a.isUnlocked).toList();

  void setTierFilter(AchievementTier? tier) {
    if (tier == state.filterTier) {
      state = state.copyWith(clearTierFilter: true);
    } else {
      state = state.copyWith(filterTier: tier);
    }
  }

  void setCollectionFilter(String? collectionId) {
    if (collectionId == state.filterCollection) {
      state = state.copyWith(clearCollectionFilter: true);
    } else {
      state = state.copyWith(filterCollection: collectionId);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> claimAchievement(String achievementId, {RetroactiveClaimData? retroactiveData, double? userLat, double? userLng}) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked) return false;

    final isRetroactive = retroactiveData != null;

    // Location-gated validation for achievements with coordinates
    // Skip for retroactive claims (they have date-based validation)
    if (!isRetroactive &&
        achievement.hasGeofence &&
        userLat != null &&
        userLng != null) {
      if (!isWithinClaimArea(userLat, userLng, achievement)) return false;
    }

    final claimDate = DateTime.now();

    final unlocked = achievement.copyWith(
      isUnlocked: true,
      unlockedAt: claimDate,
      visitDate: isRetroactive ? retroactiveData.visitDate : claimDate,
      photos: isRetroactive ? retroactiveData.photos : const [],
      notes: isRetroactive ? retroactiveData.notes : null,
      isRetroactive: isRetroactive,
      visitCount: 1,
      lastVisitedAt: claimDate,
    );

    final updatedAll = [...state.allAchievements];
    updatedAll[index] = unlocked;

    // Check for collection completion
    final collectionId = achievement.collectionId;
    var completedCollections = Set<String>.from(state.completedCollections);
    String? newlyCompletedCollection;

    if (collectionId != null && !completedCollections.contains(collectionId)) {
      final collectionAchievements =
          updatedAll.where((a) => a.collectionId == collectionId).toList();
      final allUnlocked = collectionAchievements.every((a) => a.isUnlocked);
      if (allUnlocked) {
        completedCollections.add(collectionId);
        newlyCompletedCollection = collectionId;
      }
    }

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: [...state.unlockedAchievements, unlocked],
      completedCollections: completedCollections,
    );

    // Award XP (slightly reduced for retroactive claims)
    final xpAwarded =
        XpRules.achievementXp(achievement.xpReward, isRetroactive: isRetroactive);
    ref.read(userProfileProvider.notifier).addXp(xpAwarded);

    // Award collection bonus XP if newly completed
    if (newlyCompletedCollection != null) {
      _lastCompletedCollection = newlyCompletedCollection;
      final bonusXp = _collectionBonusXp(newlyCompletedCollection);
      if (bonusXp > 0) {
        ref.read(userProfileProvider.notifier).addXp(bonusXp);
      }
    }

    await _persist(syncToRemote: unlocked, newlyCompletedCollection: newlyCompletedCollection);
    return true;
  }

  /// Returns the newly completed collection ID if the last claim completed one, else null.
  String? get lastCompletedCollection => _lastCompletedCollection;
  String? _lastCompletedCollection;

  /// Call after showing the celebration dialog to clear.
  void clearLastCompletedCollection() {
    _lastCompletedCollection = null;
  }

  /// Default revisit cooldown — 1 hour between repeat claims.
  static const revisitCooldown = Duration(hours: 1);

  /// Extended cooldown for continent and country achievements — 1 week.
  static const extendedRevisitCooldown = Duration(days: 7);

  /// Collection IDs that require the extended 1-week revisit cooldown
  /// (continent-type and country-type achievements).
  static const _extendedCooldownCollections = {
    'continents',      // continent-level
    'europe',          // European countries
    'americas',        // American destinations
    'africa',          // African countries
    'asia',            // Asian countries
    'south-america',   // South American countries
    'oceania',         // Oceania countries
    'capitals',        // World capitals (country-level)
  };

  /// Returns the revisit cooldown for a given achievement based on its type.
  static Duration cooldownFor(Achievement achievement) {
    if (achievement.collectionId != null &&
        _extendedCooldownCollections.contains(achievement.collectionId)) {
      return extendedRevisitCooldown;
    }
    return revisitCooldown;
  }

  /// Record a revisit for an already-unlocked achievement.
  /// Goes through the `register_revisit` Supabase RPC so the cooldown is
  /// enforced server-side (prevents modded clients from farming revisits).
  ///
  /// Flow:
  ///   1. Local sanity check — skip if already pending or within client-side
  ///      cooldown window (fast path, avoids unnecessary RPC calls).
  ///   2. Call RPC. Server checks its own `last_visited_at` and the
  ///      achievement's collection type to decide.
  ///   3. Accepted → reconcile local state with server's visit_count + history.
  ///   4. Rejected (cooldown or unknown) → reconcile without incrementing.
  ///   5. Network error → mark optimistic update locally; next sync replays.
  ///
  /// Returns true if the server accepted the revisit (or, when offline, if
  /// the local optimistic update was applied).
  Future<bool> recordRevisit(String achievementId) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (!achievement.isUnlocked) return false;
    // Already pending acknowledgment — don't log again
    if (achievement.isPendingRevisit) return false;

    // Client-side cooldown — purely an optimistic UX hint. Server is the
    // source of truth; a modded client that bypasses this still gets rejected
    // by the RPC.
    final now = DateTime.now();
    final cooldown = cooldownFor(achievement);
    final anchor = achievement.lastVisitedAt ?? achievement.unlockedAt;
    if (anchor != null && now.difference(anchor) < cooldown) {
      return false;
    }

    // Server-authoritative call — but we don't optimistically update state
    // first, because if the server rejects, we'd have to roll back. Instead,
    // update state only after we hear back (or on offline fallback).
    if (SupabaseConfig.isConfigured) {
      try {
        final client = ref.read(supabaseClientProvider);
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          // Older queued revisits go first so the server sees them in order.
          await _flushRevisitQueue();
          final response = await client.rpc(
            'register_revisit',
            params: {'ach_id': achievementId},
          );

          if (response is Map) {
            // Rejected → reconciled with server values but not marked as a
            // pending revisit. This also corrects any stale local counts.
            return _reconcileRevisit(achievementId, response,
                markPendingRevisit: true);
          }
        }
      } catch (e, st) {
        // Fall through to offline optimistic path
        logError(e, st, context: 'achievements.registerRevisitRpc',
            report: true);
      }
    }

    // Offline / RPC unavailable — optimistic local update, queued so the
    // server validates it (with this timestamp) on the next sync.
    final optimistic = achievement.copyWith(
      visitCount: achievement.visitCount + 1,
      lastVisitedAt: now,
      isPendingRevisit: true,
      revisitHistory: [...achievement.revisitHistory, now],
    );
    _commitAchievement(index, optimistic);
    await _persistLocally();
    await _queueRevisitSync(achievementId, [now]);
    return true;
  }

  /// Helper: replace the achievement at [index] in both allAchievements and
  /// unlockedAchievements, then push the new state.
  void _commitAchievement(int index, Achievement updated) {
    final updatedAll = [...state.allAchievements];
    updatedAll[index] = updated;

    final unlockedIdx =
        state.unlockedAchievements.indexWhere((u) => u.id == updated.id);
    final updatedUnlocked = [...state.unlockedAchievements];
    if (unlockedIdx != -1) updatedUnlocked[unlockedIdx] = updated;

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: updatedUnlocked,
    );
  }

  /// Add a retroactive revisit — appends [visitedAt] to the history and
  /// increments the visit count. Unlike `recordRevisit`, this skips the RPC
  /// cooldown (user is admitting a past visit, not claiming a current one).
  /// Synced through the `add_retroactive_revisit` RPC; offline it stays
  /// local-only.
  Future<bool> addRetroactiveRevisit(String achievementId, DateTime visitedAt) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;
    final a = state.allAchievements[index];
    if (!a.isUnlocked) return false;

    final newHistory = [...a.revisitHistory, visitedAt]..sort();
    final updated = a.copyWith(
      visitCount: a.visitCount + 1,
      revisitHistory: newHistory,
    );
    _commitAchievement(index, updated);
    await _persistLocally();

    await _callRevisitRpc(achievementId, 'add_retroactive_revisit', {
      'visited_at': visitedAt.toUtc().toIso8601String(),
    });
    return true;
  }

  /// Run a diary-edit revisit RPC and adopt the server's state when it
  /// accepts. A rejection or network error keeps the local edit.
  Future<void> _callRevisitRpc(
      String achievementId, String fn, Map<String, dynamic> params) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      if (client.auth.currentUser?.id == null) return;

      final response = await client
          .rpc(fn, params: {'ach_id': achievementId, ...params});
      if (response is Map && (response['accepted'] as bool? ?? false)) {
        await _reconcileRevisit(achievementId, response);
      }
    } catch (e, st) {
      logError(e, st, context: 'achievements.$fn', report: true);
    }
  }

  /// Update a specific entry in the revisit history — used by the edit
  /// icon on each visit row in the UI. Synced through `edit_revisit_entry`.
  Future<void> updateRevisitEntry(
      String achievementId, int index, DateTime newDate) async {
    final ai =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (ai == -1) return;
    final a = state.allAchievements[ai];
    if (!a.isUnlocked) return;
    if (index < 0 || index >= a.revisitHistory.length) return;

    final oldDate = a.revisitHistory[index];
    final newHistory = [...a.revisitHistory];
    newHistory[index] = newDate;
    newHistory.sort();

    final updated = a.copyWith(revisitHistory: newHistory);
    _commitAchievement(ai, updated);
    await _persistLocally();

    await _callRevisitRpc(achievementId, 'edit_revisit_entry', {
      'old_at': oldDate.toUtc().toIso8601String(),
      'new_at': newDate.toUtc().toIso8601String(),
    });
  }

  /// Append a photo URL to an already-unlocked achievement.
  Future<void> addPhoto(String achievementId, String photoUrl) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return;
    final a = state.allAchievements[index];
    if (!a.isUnlocked) return;

    final updated = a.copyWith(photos: [...a.photos, photoUrl]);
    _commitAchievement(index, updated);
    await _persist(syncToRemote: updated);
  }

  /// Replace the notes on an already-unlocked achievement.
  Future<void> setNotes(String achievementId, String? notes) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return;
    final a = state.allAchievements[index];
    if (!a.isUnlocked) return;

    final updated = a.copyWith(notes: notes);
    _commitAchievement(index, updated);
    await _persist(syncToRemote: updated);
  }

  /// Update visit details (date / notes / photos) for an already-unlocked
  /// achievement. Syncs to Supabase so server stays authoritative on these
  /// user-owned fields.
  Future<void> updateVisitDetails(
    String achievementId, {
    DateTime? visitDate,
    String? notes,
    List<String>? photos,
  }) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return;
    final a = state.allAchievements[index];
    if (!a.isUnlocked) return;

    final updated = a.copyWith(
      visitDate: visitDate ?? a.visitDate,
      notes: notes,
      photos: photos ?? a.photos,
    );

    final updatedAll = [...state.allAchievements];
    updatedAll[index] = updated;
    final ui = state.unlockedAchievements.indexWhere((u) => u.id == achievementId);
    final updatedUnlocked = [...state.unlockedAchievements];
    if (ui != -1) updatedUnlocked[ui] = updated;

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: updatedUnlocked,
    );
    await _persist(syncToRemote: updated);
  }

  /// Acknowledge a pending revisit — clears the pending flag.
  /// The revisit data is already recorded; this just dismisses it from the UI.
  Future<bool> acknowledgeRevisit(String achievementId) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (!achievement.isPendingRevisit) return false;

    final updated = achievement.copyWith(isPendingRevisit: false);

    final updatedAll = [...state.allAchievements];
    updatedAll[index] = updated;

    state = state.copyWith(allAchievements: updatedAll);
    await _persist();
    return true;
  }

  // ── Dev Panel Methods ──────────────────────────────────────────────────────

  Future<void> forceUnlock(String id) async {
    final index = state.allAchievements.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked) return;

    final unlocked = achievement.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    final updatedAll = [...state.allAchievements];
    updatedAll[index] = unlocked;

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: [...state.unlockedAchievements, unlocked],
    );
    ref.read(userProfileProvider.notifier).addXp(achievement.xpReward);
    await _persist(syncToRemote: unlocked);
  }

  Future<void> forceLock(String id) async {
    final index = state.allAchievements.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final achievement = state.allAchievements[index];
    if (!achievement.isUnlocked) return;

    final locked = achievement.copyWith(
      isUnlocked: false,
      unlockedAt: null,
    );
    final updatedAll = [...state.allAchievements];
    updatedAll[index] = locked;

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements:
          state.unlockedAchievements.where((a) => a.id != id).toList(),
    );
    await _persist();
  }

  Future<void> unlockAll() async {
    final now = DateTime.now();
    final updatedAll = state.allAchievements.map((a) {
      if (a.isUnlocked) return a;
      return a.copyWith(isUnlocked: true, unlockedAt: now);
    }).toList();

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: updatedAll.where((a) => a.isUnlocked).toList(),
    );
    await _persist();
  }

  Future<void> lockAll() async {
    final updatedAll = state.allAchievements.map((a) {
      if (!a.isUnlocked) return a;
      return a.copyWith(isUnlocked: false, unlockedAt: null);
    }).toList();

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: [],
      completedCollections: {},
    );
    await _persist();
  }

  Future<void> updateAchievementRadius(String id, double newRadius) async {
    final index = state.allAchievements.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final updated = state.allAchievements[index].copyWith(claimRadius: newRadius);
    final updatedAll = [...state.allAchievements];
    updatedAll[index] = updated;

    // Also update in unlocked list if present
    final unlockedIndex = state.unlockedAchievements.indexWhere((a) => a.id == id);
    final updatedUnlocked = [...state.unlockedAchievements];
    if (unlockedIndex != -1) {
      updatedUnlocked[unlockedIndex] = updated;
    }

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: updatedUnlocked,
    );
    await _persist();
  }

  int _collectionBonusXp(String collectionId) {
    final info = getCollectionInfo(collectionId);
    return info?.bonusXp ?? XpRules.defaultCollectionBonus;
  }
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>(
  (ref) => AchievementsNotifier(ref),
);

// Combined achievement registry: local Netanya + travel + lakes + glaciers
// + deserts.
final achievementRegistry = <Achievement>[
  ...localAchievementRegistry,
  ...travelAchievementRegistry,
  ...lakesAchievementRegistry,
  ...glaciersAchievementRegistry,
  ...desertsAchievementRegistry,
];
