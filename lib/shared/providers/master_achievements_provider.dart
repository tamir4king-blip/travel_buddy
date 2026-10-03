import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/models/master_achievement.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:travel_buddy_mobile/shared/data/master_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/auth_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';

class MasterAchievementsState {
  final List<MasterAchievement> allMasterAchievements;
  final List<MasterAchievement> unlockedMasterAchievements;
  final MasterTier? filterTier;

  const MasterAchievementsState({
    this.allMasterAchievements = const [],
    this.unlockedMasterAchievements = const [],
    this.filterTier,
  });

  List<MasterAchievement> get filteredMasterAchievements {
    if (filterTier == null) return allMasterAchievements;
    return allMasterAchievements.where((m) => m.tier == filterTier).toList();
  }

  int get totalUnlocked => unlockedMasterAchievements.length;
  int get totalMasterAchievements => allMasterAchievements.length;

  MasterAchievementsState copyWith({
    List<MasterAchievement>? allMasterAchievements,
    List<MasterAchievement>? unlockedMasterAchievements,
    MasterTier? filterTier,
    bool clearTierFilter = false,
  }) {
    return MasterAchievementsState(
      allMasterAchievements: allMasterAchievements ?? this.allMasterAchievements,
      unlockedMasterAchievements: unlockedMasterAchievements ?? this.unlockedMasterAchievements,
      filterTier: clearTierFilter ? null : (filterTier ?? this.filterTier),
    );
  }
}

class MasterAchievementsNotifier extends StateNotifier<MasterAchievementsState> {
  final Ref ref;

  MasterAchievementsNotifier(this.ref) : super(const MasterAchievementsState()) {
    _loadMasterAchievements();
    _syncFromRemote();
    _listenToChanges();

    // Re-sync when auth state changes (e.g. after login on a fresh install)
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        _syncFromRemote();
      }
    });
  }

  void _loadMasterAchievements() {
    final persistence = ref.read(persistenceServiceProvider);
    final savedIds = persistence.loadMasterAchievementIds();

    // Mark previously unlocked masters
    final withSaved = masterAchievementRegistry.map((m) {
      if (savedIds.contains(m.id)) {
        return m.copyWith(isUnlocked: true, progress: 1.0);
      }
      return m;
    }).toList();

    final achievements = _calculateProgress(withSaved);
    state = MasterAchievementsState(
      allMasterAchievements: achievements,
      unlockedMasterAchievements: achievements.where((m) => m.isUnlocked).toList(),
    );
  }

  void _persist() {
    final persistence = ref.read(persistenceServiceProvider);
    final unlockedIds = state.unlockedMasterAchievements.map((m) => m.id).toSet();
    persistence.saveMasterAchievementIds(unlockedIds);
    _syncMasterIdsToRemote(unlockedIds);
  }

  /// Push each unlocked master achievement to the user_master_achievements table.
  Future<void> _syncMasterIdsToRemote(Set<String> ids) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      for (final id in ids) {
        await client.from('user_master_achievements').upsert({
          'user_id': userId,
          'master_achievement_id': id,
        }, onConflict: 'user_id,master_achievement_id');
      }
    } catch (e, st) {
      logError(e, st, context: 'masterAchievements.syncToRemote',
          report: true);
    }
  }

  /// Pull master achievement IDs from Supabase.
  Future<void> _syncFromRemote() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final rows = await client
          .from('user_master_achievements')
          .select('master_achievement_id')
          .eq('user_id', userId);

      if (rows.isEmpty) return;

      final remoteIds = rows
          .map((r) => r['master_achievement_id'] as String)
          .toSet();

      final localIds = state.unlockedMasterAchievements.map((m) => m.id).toSet();
      final newIds = remoteIds.difference(localIds);
      if (newIds.isEmpty) return;

      // Merge remote IDs into local state
      final allIds = localIds.union(remoteIds);
      final updated = masterAchievementRegistry.map((m) {
        if (allIds.contains(m.id)) {
          return m.copyWith(isUnlocked: true, progress: 1.0);
        }
        return m;
      }).toList();

      final achievements = _calculateProgress(updated);
      state = state.copyWith(
        allMasterAchievements: achievements,
        unlockedMasterAchievements: achievements.where((m) => m.isUnlocked).toList(),
      );

      // Persist merged state locally
      final persistence = ref.read(persistenceServiceProvider);
      persistence.saveMasterAchievementIds(allIds);
    } catch (e, st) {
      logError(e, st, context: 'masterAchievements.syncFromRemote',
          report: true);
    }
  }

  void _listenToChanges() {
    // Listen to achievements provider changes
    ref.listen(achievementsProvider, (_, __) => _checkAndUpdateProgress());
    // Listen to quests provider changes
    ref.listen(questsProvider, (_, __) => _checkAndUpdateProgress());
    // Listen to user profile changes
    ref.listen(userProfileProvider, (_, __) => _checkAndUpdateProgress());
  }

  void _checkAndUpdateProgress() {
    final updated = _calculateProgress(state.allMasterAchievements);

    // Check for newly unlocked achievements
    final newlyUnlocked = <MasterAchievement>[];
    for (int i = 0; i < updated.length; i++) {
      if (updated[i].isUnlocked && !state.allMasterAchievements[i].isUnlocked) {
        newlyUnlocked.add(updated[i]);
      }
    }

    state = state.copyWith(
      allMasterAchievements: updated,
      unlockedMasterAchievements: updated.where((m) => m.isUnlocked).toList(),
    );

    // Award XP for newly unlocked master achievements
    for (final master in newlyUnlocked) {
      ref.read(userProfileProvider.notifier).addXp(master.xpReward);
    }

    if (newlyUnlocked.isNotEmpty) {
      _persist();
    }
  }

  List<MasterAchievement> _calculateProgress(List<MasterAchievement> masters) {
    final achievementsState = ref.read(achievementsProvider);
    final questsState = ref.read(questsProvider);
    final userProfile = ref.read(userProfileProvider);

    return masters.map((master) {
      if (master.isUnlocked) return master;

      double totalProgress = 0.0;
      int metRequirements = 0;

      for (final req in master.requirements) {
        final (progress, met) = _checkRequirement(
          req,
          achievementsState,
          questsState,
          userProfile,
        );
        totalProgress += progress;
        if (met) metRequirements++;
      }

      final avgProgress = master.requirements.isEmpty
          ? 0.0
          : totalProgress / master.requirements.length;

      final allMet = metRequirements == master.requirements.length;

      if (allMet && !master.isUnlocked) {
        return master.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          progress: 1.0,
        );
      }

      return master.copyWith(progress: avgProgress);
    }).toList();
  }

  (double progress, bool met) _checkRequirement(
    MasterRequirement req,
    AchievementsState achievementsState,
    QuestsState questsState,
    UserProfile userProfile,
  ) {
    switch (req.type) {
      case MasterRequirementType.completeCollection:
        final collectionAchievements = achievementsState.allAchievements
            .where((a) => a.collectionId == req.targetId)
            .toList();
        if (collectionAchievements.isEmpty) return (0.0, false);

        final unlocked = collectionAchievements.where((a) => a.isUnlocked).length;
        final progress = unlocked / collectionAchievements.length;
        return (progress, unlocked == collectionAchievements.length);

      case MasterRequirementType.skillLevel:
        if (req.targetId == '_multi_10') {
          // Special case: 10 skills at level 10
          final skillsAtLevel = questsState.skillLevels.values
              .where((level) => level >= 10)
              .length;
          final progress = skillsAtLevel / 10;
          return (progress.clamp(0.0, 1.0), skillsAtLevel >= 10);
        }

        final currentLevel = questsState.skillLevels[req.targetId] ?? 0;
        final progress = currentLevel / req.targetValue;
        return (progress.clamp(0.0, 1.0), currentLevel >= req.targetValue);

      case MasterRequirementType.questCount:
        final completed = questsState.completedCount;
        final progress = completed / req.targetValue;
        return (progress.clamp(0.0, 1.0), completed >= req.targetValue);

      case MasterRequirementType.userLevel:
        final progress = userProfile.level / req.targetValue;
        return (progress.clamp(0.0, 1.0), userProfile.level >= req.targetValue);

      case MasterRequirementType.achievementCount:
        final unlocked = achievementsState.totalUnlocked;
        final progress = unlocked / req.targetValue;
        return (progress.clamp(0.0, 1.0), unlocked >= req.targetValue);

      case MasterRequirementType.questCategory:
        final categoryQuests = questsState.allQuests
            .where((q) => q.category == req.targetId && q.isCompleted)
            .length;
        final progress = categoryQuests / req.targetValue;
        return (progress.clamp(0.0, 1.0), categoryQuests >= req.targetValue);

      case MasterRequirementType.streakDays:
        final streak = questsState.currentStreak;
        final progress = streak / req.targetValue;
        return (progress.clamp(0.0, 1.0), streak >= req.targetValue);
    }
  }

  void setTierFilter(MasterTier? tier) {
    if (tier == state.filterTier) {
      state = state.copyWith(clearTierFilter: true);
    } else {
      state = state.copyWith(filterTier: tier);
    }
  }

  void refresh() {
    _checkAndUpdateProgress();
  }
}

final masterAchievementsProvider =
    StateNotifierProvider<MasterAchievementsNotifier, MasterAchievementsState>(
  (ref) => MasterAchievementsNotifier(ref),
);
