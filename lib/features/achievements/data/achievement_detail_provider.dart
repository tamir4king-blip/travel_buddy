import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/features/achievements/data/achievement_repository.dart';
import 'package:travel_buddy_mobile/shared/models/achievement_detail.dart';

/// Fetches rich achievement detail by ID. Returns `null` on failure (offline fallback).
final achievementDetailProvider =
    FutureProvider.family<AchievementDetail?, String>((ref, id) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getDetail(id);
});
