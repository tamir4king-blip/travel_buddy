/// Pure XP rules shared by the whole app and mirrored by the server-side
/// SQL functions in `supabase/migrations/*_server_authoritative_xp.sql`.
///
/// The server is authoritative for `profiles.total_xp` / `profiles.level`:
/// it re-derives XP from synced rows (user_achievements, quest completions,
/// collections, master achievements) using these same formulas. Client-side
/// awards are optimistic UI only and get reconciled on the next remote load.
/// If you change a formula here, update the matching SQL function too.
library;

abstract final class XpRules {
  /// Multiplier applied to retroactive achievement claims.
  static const double retroactiveMultiplier = 0.8;

  /// XP awarded for an achievement claim.
  static int achievementXp(int baseXp, {bool isRetroactive = false}) =>
      isRetroactive ? (baseXp * retroactiveMultiplier).round() : baseXp;

  /// Diminishing returns for repeat quest completions:
  /// 100% for the first, then 75%, 50%, and 25% for every later repeat.
  static int questXp(int baseXp, int completionCount) {
    if (completionCount <= 1) return baseXp;
    if (completionCount == 2) return (baseXp * 0.75).round();
    if (completionCount == 3) return (baseXp * 0.50).round();
    return (baseXp * 0.25).round();
  }

  /// 15% bonus applied to *skill* XP when a quest completion includes photos.
  ///
  /// Deliberately NOT applied to profile/total XP: the server cannot verify
  /// photos, so leaderboard XP uses the unboosted value on both sides.
  static int withPhotoBonus(int xp) => (xp * 1.15).round();

  /// Fallback bonus for completing a collection that has no explicit
  /// `bonusXp` in the collection registry.
  static const int defaultCollectionBonus = 50;

  /// XP thresholds for levels 1–10; beyond that every 1500 XP is a level.
  static const List<int> _thresholds = [
    0, 100, 250, 500, 850, 1300, 1850, 2500, 3300, 4250, 5400,
  ];

  static int levelForXp(int totalXp) {
    for (var level = 1; level < _thresholds.length; level++) {
      if (totalXp < _thresholds[level]) return level;
    }
    return 10 + ((totalXp - 5400) ~/ 1500);
  }

  static int xpForLevel(int level) {
    if (level <= 10) return _thresholds[level];
    return 5400 + (level - 10) * 1500;
  }

  static int xpToNextLevel(int totalXp, int currentLevel) =>
      xpForLevel(currentLevel + 1) - totalXp;
}
