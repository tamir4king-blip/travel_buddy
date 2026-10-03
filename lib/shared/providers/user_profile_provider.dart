import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:travel_buddy_mobile/shared/providers/auth_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/profile_sync_provider.dart';
import 'package:travel_buddy_mobile/shared/utils/xp_rules.dart';

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref ref;

  UserProfileNotifier(this.ref, UserProfile initial) : super(initial) {
    _loadFromPersistence();
    _loadFromRemote();
  }

  void _loadFromPersistence() {
    final persistence = ref.read(persistenceServiceProvider);
    final saved = persistence.loadUserProfile();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> _loadFromRemote() async {
    try {
      final syncService = ref.read(profileSyncServiceProvider);
      if (syncService == null) return;

      final remote = await syncService.loadProfileFromRemote();
      if (remote == null) return;

      // Server wins for XP/level/premium: total_xp is computed by database
      // triggers from synced achievement/quest rows, and clients can no
      // longer write those columns. A temporarily lower remote value just
      // means local claims haven't synced yet — they'll be re-awarded
      // server-side once the rows arrive, and the next reload converges.
      state = state.copyWith(
        displayName: remote.displayName,
        username: remote.username,
        bio: remote.bio,
        avatarUrl: remote.avatarUrl,
        totalXp: remote.totalXp,
        level: remote.level,
        isPublic: remote.isPublic,
        isPremium: remote.isPremium,
      );
      _persistLocally();
    } catch (e, st) {
      // Local persistence is primary
      logError(e, st, context: 'userProfile.syncFromRemote', report: true);
    }
  }

  void _persistLocally() {
    final persistence = ref.read(persistenceServiceProvider);
    persistence.saveUserProfile(state);
  }

  void _persist() {
    _persistLocally();
    _syncToRemote();
  }

  Future<void> _syncToRemote() async {
    try {
      final syncService = ref.read(profileSyncServiceProvider);
      if (syncService == null) return;
      // Fire-and-forget
      syncService.syncProfileToRemote(state);
    } catch (e, st) {
      logError(e, st, context: 'userProfile.syncToRemote', report: true);
    }
  }

  /// Optimistic local XP award. The server independently re-derives the
  /// authoritative total from synced rows; [reloadFromRemote] reconciles.
  void addXp(int amount) {
    final newXp = state.totalXp + amount;
    final newLevel = XpRules.levelForXp(newXp);
    state = state.copyWith(totalXp: newXp, level: newLevel);
    _persist();
  }

  /// Re-pull the server-authoritative profile (XP/level). Called after
  /// remote syncs that may have triggered server-side XP awards.
  Future<void> reloadFromRemote() => _loadFromRemote();

  void updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
  }) {
    state = state.copyWith(
      displayName: displayName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      isPublic: isPublic,
    );
    _persist();
  }

  static int xpForLevel(int level) => XpRules.xpForLevel(level);

  static int xpToNextLevel(int totalXp, int currentLevel) =>
      XpRules.xpToNextLevel(totalXp, currentLevel);
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final authState = ref.watch(authProvider);
  return UserProfileNotifier(ref, authState.user ?? UserProfile.demo);
});
