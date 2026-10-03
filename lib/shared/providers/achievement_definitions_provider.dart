import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/data/achievement_definitions_repository.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart'
    show achievementRegistry;
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';
import 'package:travel_buddy_mobile/shared/utils/achievement_definitions_codec.dart';

/// Provides the merged achievement definitions list.
/// Priority: Supabase definitions > cached definitions > hardcoded registry.
class AchievementDefinitionsNotifier extends StateNotifier<List<Achievement>> {
  final Ref ref;

  AchievementDefinitionsNotifier(this.ref) : super(achievementRegistry) {
    _load();
  }

  void _load() {
    // 1. Start with hardcoded registry
    final hardcoded = achievementRegistry;

    // 2. Try loading cached Supabase definitions
    try {
      final persistence = ref.read(persistenceServiceProvider);
      final cached = persistence.loadAchievementDefinitions();
      if (cached != null) {
        final remote = parseDefinitions(cached);
        state = mergeDefinitions(hardcoded, remote);
      }
    } catch (e, st) {
      // Cached definitions corrupted — fall back to hardcoded registry.
      logError(e, st, context: 'achievementDefinitions.loadCache',
          report: true);
    }

    // 3. Fetch fresh from Supabase in background
    _syncFromRemote();
  }

  Future<void> _syncFromRemote() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      final client = ref.read(supabaseClientProvider);
      final repo = AchievementDefinitionsRepository(client);
      final remote = await repo.fetchAll();

      if (remote.isNotEmpty) {
        final merged = mergeDefinitions(achievementRegistry, remote);
        state = merged;

        // Cache for offline use + background service
        final persistence = ref.read(persistenceServiceProvider);
        await persistence.saveAchievementDefinitions(serializeDefinitions(remote));
      }
    } catch (e, st) {
      // Supabase unavailable — keep using cached/hardcoded
      logError(e, st, context: 'achievementDefinitions.syncFromRemote',
          report: true);
    }
  }

  /// Force a refresh from Supabase. Called from dev panel.
  Future<void> refresh() async => _syncFromRemote();
}

final achievementDefinitionsProvider =
    StateNotifierProvider<AchievementDefinitionsNotifier, List<Achievement>>(
  (ref) => AchievementDefinitionsNotifier(ref),
);
