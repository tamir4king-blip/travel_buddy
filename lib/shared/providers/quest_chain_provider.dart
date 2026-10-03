import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/data/story_quest_registry.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';

class QuestChainState {
  final List<Quest> allQuests;

  const QuestChainState({this.allQuests = const []});

  List<Quest> get activeQuests =>
      allQuests.where((q) => q.isStarted && !q.isCompleted).toList();

  /// Quests that are completed but not yet claimed by the user.
  List<Quest> get claimableQuests =>
      allQuests.where((q) => q.isClaimable).toList();

  List<Quest> get completedQuests =>
      allQuests.where((q) => q.isClaimed).toList();

  List<Quest> get availableQuests =>
      allQuests.where((q) => !q.isStarted && !q.isCompleted).toList();

  int get totalCompleted => completedQuests.length;

  QuestChainState copyWith({List<Quest>? allQuests}) {
    return QuestChainState(allQuests: allQuests ?? this.allQuests);
  }
}

class QuestChainNotifier extends StateNotifier<QuestChainState> {
  final Ref _ref;

  QuestChainNotifier(this._ref) : super(const QuestChainState()) {
    _load();
    // Listen for activity completions and achievement unlocks to auto-advance.
    _ref.listen(questsProvider, (_, __) => _recomputeSteps());
    _ref.listen(achievementsProvider, (_, __) => _recomputeSteps());
  }

  // ── Persistence key ──────────────────────────────────────────────────────

  void _load() {
    final persistence = _ref.read(persistenceServiceProvider);
    final raw = persistence.loadQuestChains();
    final saved = <String, Map<String, dynamic>>{};
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        saved[entry.key] = entry.value as Map<String, dynamic>;
      }
    }

    // Merge saved progress onto registry quests.
    final merged = storyQuestRegistry.map((q) {
      final data = saved[q.id];
      if (data == null) return q;

      final savedSteps = data['steps'] as Map<String, dynamic>? ?? {};
      final updatedSteps = q.steps.map((step) {
        final stepData = savedSteps[step.id] as Map<String, dynamic>?;
        if (stepData == null) return step;
        return QuestStep.fromJson(stepData, step);
      }).toList();

      return q.copyWith(
        steps: updatedSteps,
        isCompleted: data['isCompleted'] as bool? ?? false,
        completedAt: data['completedAt'] != null
            ? DateTime.tryParse(data['completedAt'] as String)
            : null,
        isClaimed: data['isClaimed'] as bool? ?? false,
        isStarted: data['isStarted'] as bool? ?? false,
      );
    }).toList();

    state = QuestChainState(allQuests: merged);

    // Run initial step check.
    _recomputeSteps();
  }

  void _persist() {
    final persistence = _ref.read(persistenceServiceProvider);
    final data = <String, dynamic>{};
    for (final q in state.allQuests) {
      if (q.isStarted || q.isCompleted) {
        data[q.id] = q.toJson();
      }
    }
    persistence.saveQuestChains(jsonEncode(data));
  }

  // ── Auto-advance steps ─────────────────────────────────────────────────

  void _recomputeSteps() {
    final activities = _ref.read(questsProvider);
    final achievements = _ref.read(achievementsProvider);
    var changed = false;

    final updated = state.allQuests.map((quest) {
      if (!quest.isStarted || quest.isCompleted) return quest;

      var stepsChanged = false;
      final newSteps = quest.steps.map((step) {
        if (step.isCompleted) return step;

        final done = _isStepFulfilled(step, activities, achievements);
        if (done) {
          stepsChanged = true;
          return step.copyWith(isCompleted: true);
        }
        return step;
      }).toList();

      if (!stepsChanged) return quest;
      changed = true;

      final allDone = newSteps.every((s) => s.isCompleted);
      var result = quest.copyWith(steps: newSteps);

      if (allDone && !quest.isCompleted) {
        result = result.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        // XP is awarded when the user claims the quest, not here.
      }

      return result;
    }).toList();

    if (changed) {
      state = QuestChainState(allQuests: updated);
      _persist();
    }
  }

  bool _isStepFulfilled(
    QuestStep step,
    QuestsState activities,
    AchievementsState achievements,
  ) {
    switch (step.type) {
      case QuestStepType.activity:
        final activity = activities.allQuests
            .where((q) => q.id == step.targetId)
            .firstOrNull;
        return activity?.isCompleted ?? false;
      case QuestStepType.achievement:
        final achievement = achievements.allAchievements
            .where((a) => a.id == step.targetId)
            .firstOrNull;
        return achievement?.isUnlocked ?? false;
    }
  }

  // ── User actions ───────────────────────────────────────────────────────

  /// Claim a completed quest — awards XP and marks as claimed.
  /// Returns true if the claim succeeded.
  bool claimQuest(String questId) {
    final idx = state.allQuests.indexWhere((q) => q.id == questId);
    if (idx == -1) return false;
    final quest = state.allQuests[idx];
    if (!quest.isClaimable) return false;

    final updated = [...state.allQuests];
    updated[idx] = quest.copyWith(isClaimed: true);
    state = QuestChainState(allQuests: updated);
    _persist();

    // Optimistic local XP; the server awards the authoritative XP via the
    // user_quest_completions trigger when the claim row below arrives.
    _ref.read(userProfileProvider.notifier).addXp(quest.xpReward);
    _syncClaimToRemote(quest.id);
    return true;
  }

  /// Record a claimed story quest in user_quest_completions so the
  /// server-side XP trigger prices it (story quests are seeded into
  /// quest_definitions with max_completions = 1). Fire-and-forget.
  Future<void> _syncClaimToRemote(String questId) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('user_quest_completions').upsert({
        'user_id': userId,
        'quest_id': questId,
        'completion_count': 1,
      }, onConflict: 'user_id,quest_id');
    } catch (e, st) {
      // Local state is primary; the claim stays recorded locally.
      logError(e, st, context: 'questChain.syncClaimToRemote', report: true);
    }
  }

  /// Start tracking a quest (makes it active).
  void startQuest(String questId) {
    final idx = state.allQuests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final quest = state.allQuests[idx];
    if (quest.isStarted) return;

    final updated = [...state.allQuests];
    updated[idx] = quest.copyWith(isStarted: true);
    state = QuestChainState(allQuests: updated);
    _persist();

    // Immediately check if any steps are already done.
    _recomputeSteps();
  }

  /// Abandon a quest (resets progress).
  void abandonQuest(String questId) {
    final idx = state.allQuests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final quest = state.allQuests[idx];

    // Reset all steps and quest state.
    final resetSteps = quest.steps.map((s) => s.copyWith(isCompleted: false)).toList();
    final updated = [...state.allQuests];
    updated[idx] = quest.copyWith(
      steps: resetSteps,
      isStarted: false,
      isCompleted: false,
      isClaimed: false,
    );
    state = QuestChainState(allQuests: updated);
    _persist();
  }

  // ── Dev panel ──────────────────────────────────────────────────────────

  void resetAllQuestChains() {
    final reset = state.allQuests.map((q) {
      final resetSteps = q.steps.map((s) => s.copyWith(isCompleted: false)).toList();
      return q.copyWith(steps: resetSteps, isStarted: false, isCompleted: false, isClaimed: false);
    }).toList();
    state = QuestChainState(allQuests: reset);
    _persist();
  }
}

final questChainProvider =
    StateNotifierProvider<QuestChainNotifier, QuestChainState>(
  (ref) => QuestChainNotifier(ref),
);
