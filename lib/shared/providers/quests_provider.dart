import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/providers/auth_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';
import 'package:travel_buddy_mobile/shared/data/quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';
import 'package:travel_buddy_mobile/shared/utils/xp_rules.dart';

class QuestsState {
  final List<SideQuest> allQuests;
  final String? filterCategory;
  final QuestDifficulty? filterDifficulty;
  final Map<String, int> skillXp; // skillType -> xp
  final Map<String, int> skillLevels; // skillType -> level
  final int currentStreak;
  final DateTime? lastCompletionDate;

  const QuestsState({
    this.allQuests = const [],
    this.filterCategory,
    this.filterDifficulty,
    this.skillXp = const {},
    this.skillLevels = const {},
    this.currentStreak = 0,
    this.lastCompletionDate,
  });

  List<SideQuest> get filteredQuests {
    var list = allQuests;
    if (filterCategory != null) {
      list = list.where((q) => q.category == filterCategory).toList();
    }
    if (filterDifficulty != null) {
      list = list.where((q) => q.difficulty == filterDifficulty).toList();
    }
    return list;
  }

  int get completedCount => allQuests.where((q) => q.isCompleted).length;

  QuestsState copyWith({
    List<SideQuest>? allQuests,
    String? filterCategory,
    QuestDifficulty? filterDifficulty,
    Map<String, int>? skillXp,
    Map<String, int>? skillLevels,
    int? currentStreak,
    DateTime? lastCompletionDate,
    bool clearCategoryFilter = false,
    bool clearDifficultyFilter = false,
  }) {
    return QuestsState(
      allQuests: allQuests ?? this.allQuests,
      filterCategory:
          clearCategoryFilter ? null : (filterCategory ?? this.filterCategory),
      filterDifficulty: clearDifficultyFilter
          ? null
          : (filterDifficulty ?? this.filterDifficulty),
      skillXp: skillXp ?? this.skillXp,
      skillLevels: skillLevels ?? this.skillLevels,
      currentStreak: currentStreak ?? this.currentStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
    );
  }
}

class QuestsNotifier extends StateNotifier<QuestsState> {
  final Ref ref;

  QuestsNotifier(this.ref) : super(const QuestsState()) {
    _loadQuests();
    _syncFromRemote();

    // Re-sync when auth state changes (e.g. after login on a fresh install)
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        _syncFromRemote();
      }
    });
  }

  void _loadQuests() {
    final persistence = ref.read(persistenceServiceProvider);

    // Load saved data
    final savedCompletions = persistence.loadCompletedQuests();
    final savedSkillXp = persistence.loadSkillXp();
    final streakData = persistence.loadStreakData();

    // Use saved skill XP if available, otherwise start empty
    // Skills are earned by completing quests — no fake data
    final skillXp = savedSkillXp;

    // Calculate skill levels from XP
    final skillLevels = <String, int>{};
    for (final entry in skillXp.entries) {
      skillLevels[entry.key] = _calculateSkillLevel(entry.value, entry.key);
    }

    // Merge saved completions onto quest registry
    final mergedQuests = questRegistry.map((q) {
      final savedCount = savedCompletions[q.id];
      if (savedCount != null && savedCount > 0) {
        return q.copyWith(
          completionCount: savedCount,
          isCompleted: true,
        );
      }
      return q;
    }).toList();

    // Use saved streak if available, otherwise start at 0
    final streak = streakData.currentStreak;

    state = QuestsState(
      allQuests: mergedQuests,
      skillXp: skillXp,
      skillLevels: skillLevels,
      currentStreak: streak,
      lastCompletionDate: streakData.lastCompletionDate,
    );
  }

  void _persist() {
    _persistLocally();
    _syncToRemote();
  }

  void _persistLocally() {
    final persistence = ref.read(persistenceServiceProvider);

    // Save quest completions
    final completions = <String, int>{};
    for (final q in state.allQuests) {
      if (q.completionCount > 0) {
        completions[q.id] = q.completionCount;
      }
    }
    persistence.saveCompletedQuests(completions);
    persistence.saveSkillXp(state.skillXp);
    persistence.saveStreakData(state.currentStreak, state.lastCompletionDate);
  }

  /// Push quest completions, skill XP, and streak to Supabase.
  Future<void> _syncToRemote() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Upsert quest completions
      for (final q in state.allQuests) {
        if (q.completionCount > 0) {
          await client.from('user_quest_completions').upsert({
            'user_id': userId,
            'quest_id': q.id,
            'completion_count': q.completionCount,
          }, onConflict: 'user_id,quest_id');
        }
      }

      // Upsert skill XP
      for (final entry in state.skillXp.entries) {
        if (entry.value > 0) {
          await client.from('user_skill_xp').upsert({
            'user_id': userId,
            'skill_id': entry.key,
            'xp': entry.value,
          }, onConflict: 'user_id,skill_id');
        }
      }

      // Sync streak to profiles table
      await client.from('profiles').update({
        'current_streak': state.currentStreak,
        'last_completion_date': state.lastCompletionDate?.toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      // Local data is primary
      logError(e, st, context: 'quests.syncStreakToRemote', report: true);
    }
  }

  /// Pull quest completions, skill XP, and streak from Supabase and merge.
  Future<void> _syncFromRemote() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch quest completions
      final questRows = await client
          .from('user_quest_completions')
          .select()
          .eq('user_id', userId);

      // Fetch skill XP
      final skillRows = await client
          .from('user_skill_xp')
          .select()
          .eq('user_id', userId);

      // Fetch streak from profiles
      final profileRows = await client
          .from('profiles')
          .select('current_streak, last_completion_date')
          .eq('id', userId);

      if (questRows.isEmpty && skillRows.isEmpty) {
        // No remote data — push local state
        _syncToRemote();
        return;
      }

      // Build remote maps
      final remoteCompletions = <String, int>{};
      for (final row in questRows) {
        final id = row['quest_id'] as String?;
        final count = row['completion_count'] as int? ?? 0;
        if (id != null && count > 0) remoteCompletions[id] = count;
      }

      final remoteSkillXp = <String, int>{};
      for (final row in skillRows) {
        final id = row['skill_id'] as String?;
        final xp = row['xp'] as int? ?? 0;
        if (id != null && xp > 0) remoteSkillXp[id] = xp;
      }

      final remoteStreak = profileRows.isNotEmpty
          ? (profileRows.first['current_streak'] as int? ?? 0)
          : 0;
      final remoteLastDate = profileRows.isNotEmpty &&
              profileRows.first['last_completion_date'] != null
          ? DateTime.tryParse(
              profileRows.first['last_completion_date'] as String)
          : null;

      // Merge: take the higher value for each entry
      var changed = false;

      final mergedCompletions = Map<String, int>.from(_currentCompletions());
      for (final entry in remoteCompletions.entries) {
        final local = mergedCompletions[entry.key] ?? 0;
        if (entry.value > local) {
          mergedCompletions[entry.key] = entry.value;
          changed = true;
        }
      }

      final mergedSkillXp = Map<String, int>.from(state.skillXp);
      for (final entry in remoteSkillXp.entries) {
        final local = mergedSkillXp[entry.key] ?? 0;
        if (entry.value > local) {
          mergedSkillXp[entry.key] = entry.value;
          changed = true;
        }
      }

      final mergedStreak = remoteStreak > state.currentStreak
          ? remoteStreak
          : state.currentStreak;
      final mergedLastDate =
          _laterDate(state.lastCompletionDate, remoteLastDate);

      if (remoteStreak > state.currentStreak) changed = true;

      if (changed) {
        // Rebuild quest list with merged completions
        final mergedQuests = questRegistry.map((q) {
          final count = mergedCompletions[q.id];
          if (count != null && count > 0) {
            return q.copyWith(completionCount: count, isCompleted: true);
          }
          return q;
        }).toList();

        // Recalculate skill levels
        final mergedSkillLevels = <String, int>{};
        for (final entry in mergedSkillXp.entries) {
          mergedSkillLevels[entry.key] =
              _calculateSkillLevel(entry.value, entry.key);
        }

        state = state.copyWith(
          allQuests: mergedQuests,
          skillXp: mergedSkillXp,
          skillLevels: mergedSkillLevels,
          currentStreak: mergedStreak,
          lastCompletionDate: mergedLastDate,
        );
        _persistLocally();
      }

      // Push any locally-higher values to remote
      await _syncToRemote();

      // Server-side triggers may have just awarded XP for completions that
      // only existed locally — pull the authoritative total back down.
      await ref.read(userProfileProvider.notifier).reloadFromRemote();
    } catch (e, st) {
      // Local data is primary
      logError(e, st, context: 'quests.syncWithRemote', report: true);
    }
  }

  Map<String, int> _currentCompletions() {
    final completions = <String, int>{};
    for (final q in state.allQuests) {
      if (q.completionCount > 0) {
        completions[q.id] = q.completionCount;
      }
    }
    return completions;
  }

  static DateTime? _laterDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  void setCategoryFilter(String? category) {
    if (category == state.filterCategory) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(filterCategory: category);
    }
  }

  void setDifficultyFilter(QuestDifficulty? difficulty) {
    if (difficulty == state.filterDifficulty) {
      state = state.copyWith(clearDifficultyFilter: true);
    } else {
      state = state.copyWith(filterDifficulty: difficulty);
    }
  }

  bool completeQuest(String questId, {List<String>? photos}) {
    final index = state.allQuests.indexWhere((q) => q.id == questId);
    if (index == -1) return false;

    final quest = state.allQuests[index];
    if (quest.isCompleted && !quest.isRepeatable) return false;
    if (quest.isRepeatable && quest.completionCount >= quest.maxCompletions) {
      return false;
    }

    final newCount = quest.completionCount + 1;
    final completed = quest.copyWith(
      completionCount: newCount,
      isCompleted: true,
    );

    final updatedQuests = [...state.allQuests];
    updatedQuests[index] = completed;

    // Calculate XP with diminishing returns for repeats
    final xpEarned = XpRules.questXp(quest.xpReward, newCount);

    // 15% bonus on *skill* XP when photos are provided. Profile/total XP
    // stays unboosted so it matches the server-side award (the server
    // can't verify photos — see XpRules.withPhotoBonus).
    var skillXpEarned = xpEarned;
    if (photos != null && photos.isNotEmpty) {
      skillXpEarned = XpRules.withPhotoBonus(xpEarned);
    }

    // Update skill XP
    final updatedSkillXp = Map<String, int>.from(state.skillXp);
    final currentSkillXp = updatedSkillXp[quest.skillType] ?? 0;
    updatedSkillXp[quest.skillType] = currentSkillXp + skillXpEarned;

    // Update skill level
    final updatedSkillLevels = Map<String, int>.from(state.skillLevels);
    updatedSkillLevels[quest.skillType] =
        _calculateSkillLevel(updatedSkillXp[quest.skillType]!, quest.skillType);

    // Update streak
    final now = DateTime.now();
    final lastDate = state.lastCompletionDate;
    int newStreak = state.currentStreak;
    if (lastDate != null) {
      final diff = now.difference(lastDate).inDays;
      if (diff <= 1) {
        newStreak = state.currentStreak + 1;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    state = state.copyWith(
      allQuests: updatedQuests,
      skillXp: updatedSkillXp,
      skillLevels: updatedSkillLevels,
      currentStreak: newStreak,
      lastCompletionDate: now,
    );

    // Persist photos if provided
    if (photos != null && photos.isNotEmpty) {
      final persistence = ref.read(persistenceServiceProvider);
      final savedPhotos = persistence.loadQuestPhotos();
      savedPhotos[questId] = [...(savedPhotos[questId] ?? []), ...photos];
      persistence.saveQuestPhotos(savedPhotos);
    }

    // Award global XP
    ref.read(userProfileProvider.notifier).addXp(xpEarned);

    _persist();
    return true;
  }

  // ── Dev Panel Methods ──────────────────────────────────────────────────────

  void forceCompleteQuest(String id) {
    final index = state.allQuests.indexWhere((q) => q.id == id);
    if (index == -1) return;
    final quest = state.allQuests[index];
    if (quest.isCompleted) return;

    final completed = quest.copyWith(
      completionCount: 1,
      isCompleted: true,
    );
    final updatedQuests = [...state.allQuests];
    updatedQuests[index] = completed;

    // Update skill XP
    final updatedSkillXp = Map<String, int>.from(state.skillXp);
    final currentSkillXp = updatedSkillXp[quest.skillType] ?? 0;
    updatedSkillXp[quest.skillType] = currentSkillXp + quest.xpReward;

    final updatedSkillLevels = Map<String, int>.from(state.skillLevels);
    updatedSkillLevels[quest.skillType] =
        _calculateSkillLevel(updatedSkillXp[quest.skillType]!, quest.skillType);

    state = state.copyWith(
      allQuests: updatedQuests,
      skillXp: updatedSkillXp,
      skillLevels: updatedSkillLevels,
    );

    ref.read(userProfileProvider.notifier).addXp(quest.xpReward);
    _persist();
  }

  void uncompleteQuest(String id) {
    final index = state.allQuests.indexWhere((q) => q.id == id);
    if (index == -1) return;
    final quest = state.allQuests[index];
    if (!quest.isCompleted) return;

    final reset = quest.copyWith(
      completionCount: 0,
      isCompleted: false,
    );
    final updatedQuests = [...state.allQuests];
    updatedQuests[index] = reset;

    // Remove skill XP that was awarded
    final updatedSkillXp = Map<String, int>.from(state.skillXp);
    final currentSkillXp = updatedSkillXp[quest.skillType] ?? 0;
    updatedSkillXp[quest.skillType] = (currentSkillXp - quest.xpReward).clamp(0, currentSkillXp);

    final updatedSkillLevels = Map<String, int>.from(state.skillLevels);
    updatedSkillLevels[quest.skillType] =
        _calculateSkillLevel(updatedSkillXp[quest.skillType]!, quest.skillType);

    state = state.copyWith(
      allQuests: updatedQuests,
      skillXp: updatedSkillXp,
      skillLevels: updatedSkillLevels,
    );
    _persist();
  }

  void resetAllQuests() {
    final resetQuests = state.allQuests.map((q) {
      if (!q.isCompleted) return q;
      return q.copyWith(completionCount: 0, isCompleted: false);
    }).toList();

    state = state.copyWith(
      allQuests: resetQuests,
      skillXp: {},
      skillLevels: {},
      currentStreak: 0,
    );
    _persist();
  }

  int _calculateSkillLevel(int skillXp, String skillType) {
    final skill = getSkillById(skillType);
    final xpPerLevel = skill?.xpPerLevel ?? 500;
    final maxLevel = skill?.maxLevel ?? 50;
    final level = (skillXp / xpPerLevel).floor() + 1;
    return level.clamp(1, maxLevel);
  }
}

final questsProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>(
  (ref) => QuestsNotifier(ref),
);

// Note: questRegistry is now imported from quest_registry.dart
// Contains 150+ quests across 18 categories
