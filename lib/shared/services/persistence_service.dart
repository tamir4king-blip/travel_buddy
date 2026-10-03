import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:travel_buddy_mobile/shared/utils/achievement_definitions_codec.dart';

class PersistenceService {
  final SharedPreferences _prefs;

  PersistenceService(this._prefs);

  // Keys
  static const _keyUserProfile = 'user_profile';
  static const _keyUnlockedAchievements = 'unlocked_achievements';
  static const _keyCompletedQuests = 'completed_quests';
  static const _keySkillXp = 'skill_xp';
  static const _keyStreakData = 'streak_data';
  static const _keyMasterAchievements = 'master_achievements';
  static const _keyCompletedCollections = 'completed_collections';
  static const _keyQuestPhotos = 'quest_photos';
  static const _keyLocale = 'app_locale';
  static const _keyLiveTracking = 'live_tracking';
  static const _keyNotifications = 'notifications_enabled';
  static const _keyPendingClaims = 'pending_claims';
  static const _keyAchievementDefinitions = achievementDefinitionsCacheKey;

  // --- User Profile ---

  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setString(_keyUserProfile, jsonEncode(profile.toJson()));
  }

  UserProfile? loadUserProfile() {
    final raw = _prefs.getString(_keyUserProfile);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // --- Achievements ---

  Future<void> saveUnlockedAchievements(List<Map<String, dynamic>> achievements) async {
    await _prefs.setString(_keyUnlockedAchievements, jsonEncode(achievements));
  }

  List<Map<String, dynamic>> loadUnlockedAchievements() {
    final raw = _prefs.getString(_keyUnlockedAchievements);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // --- Quests ---

  Future<void> saveCompletedQuests(Map<String, int> questCompletions) async {
    await _prefs.setString(_keyCompletedQuests, jsonEncode(questCompletions));
  }

  Map<String, int> loadCompletedQuests() {
    final raw = _prefs.getString(_keyCompletedQuests);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as int));
  }

  // --- Skill XP ---

  Future<void> saveSkillXp(Map<String, int> skillXp) async {
    await _prefs.setString(_keySkillXp, jsonEncode(skillXp));
  }

  Map<String, int> loadSkillXp() {
    final raw = _prefs.getString(_keySkillXp);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as int));
  }

  // --- Streak ---

  Future<void> saveStreakData(int streak, DateTime? lastCompletionDate) async {
    await _prefs.setString(_keyStreakData, jsonEncode({
      'currentStreak': streak,
      'lastCompletionDate': lastCompletionDate?.toIso8601String(),
    }));
  }

  ({int currentStreak, DateTime? lastCompletionDate}) loadStreakData() {
    final raw = _prefs.getString(_keyStreakData);
    if (raw == null) return (currentStreak: 0, lastCompletionDate: null);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return (
      currentStreak: map['currentStreak'] as int? ?? 0,
      lastCompletionDate: map['lastCompletionDate'] != null
          ? DateTime.parse(map['lastCompletionDate'] as String)
          : null,
    );
  }

  // --- Master Achievements ---

  Future<void> saveMasterAchievementIds(Set<String> ids) async {
    await _prefs.setStringList(_keyMasterAchievements, ids.toList());
  }

  Set<String> loadMasterAchievementIds() {
    final list = _prefs.getStringList(_keyMasterAchievements);
    return list?.toSet() ?? {};
  }

  // --- Completed Collections ---

  Future<void> saveCompletedCollections(Set<String> ids) async {
    await _prefs.setStringList(_keyCompletedCollections, ids.toList());
  }

  Set<String> loadCompletedCollections() {
    final list = _prefs.getStringList(_keyCompletedCollections);
    return list?.toSet() ?? {};
  }

  // --- Quest Photos ---

  Future<void> saveQuestPhotos(Map<String, List<String>> photos) async {
    await _prefs.setString(_keyQuestPhotos, jsonEncode(photos));
  }

  Map<String, List<String>> loadQuestPhotos() {
    final raw = _prefs.getString(_keyQuestPhotos);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) =>
        MapEntry(k, (v as List<dynamic>).cast<String>()));
  }

  // --- Locale ---

  Future<void> saveLocale(String languageCode) async {
    await _prefs.setString(_keyLocale, languageCode);
  }

  String? loadLocale() {
    return _prefs.getString(_keyLocale);
  }

  // --- Live Tracking ---

  Future<void> saveLiveTracking(bool enabled) async {
    await _prefs.setBool(_keyLiveTracking, enabled);
  }

  bool loadLiveTracking() {
    return _prefs.getBool(_keyLiveTracking) ?? false;
  }

  // --- Notifications ---

  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotifications, enabled);
  }

  bool loadNotificationsEnabled() {
    return _prefs.getBool(_keyNotifications) ?? true;
  }

  // --- Pending Claims ---

  Future<void> savePendingClaims(Map<String, String> pendingClaims) async {
    await _prefs.setString(_keyPendingClaims, jsonEncode(pendingClaims));
  }

  Map<String, String> loadPendingClaims() {
    final raw = _prefs.getString(_keyPendingClaims);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as String));
  }

  // --- Revisits awaiting server validation ---

  static const _keyPendingRevisitSync = 'pending_revisit_sync';

  /// Achievement id → UTC ISO timestamps not yet sent to `register_revisit`.
  Future<void> savePendingRevisitSync(Map<String, List<String>> queue) async {
    await _prefs.setString(_keyPendingRevisitSync, jsonEncode(queue));
  }

  Map<String, List<String>> loadPendingRevisitSync() {
    final raw = _prefs.getString(_keyPendingRevisitSync);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) =>
        MapEntry(k, (v as List<dynamic>).cast<String>()));
  }

  // --- Achievement Definitions (Supabase cache) ---

  Future<void> saveAchievementDefinitions(String json) async {
    await _prefs.setString(_keyAchievementDefinitions, json);
  }

  String? loadAchievementDefinitions() {
    return _prefs.getString(_keyAchievementDefinitions);
  }

  // --- Quest Chains ---

  static const _keyQuestChains = 'quest_chains';

  Future<void> saveQuestChains(String jsonString) async {
    await _prefs.setString(_keyQuestChains, jsonString);
  }

  String? loadQuestChains() {
    return _prefs.getString(_keyQuestChains);
  }

  // --- Reload from disk ---

  /// Re-reads SharedPreferences from disk. Call this when the app resumes
  /// so that changes made by the background isolate become visible.
  Future<void> reload() async {
    await _prefs.reload();
  }

  // --- Clear All ---

  Future<void> clearAll() async {
    await _prefs.remove(_keyUserProfile);
    await _prefs.remove(_keyUnlockedAchievements);
    await _prefs.remove(_keyCompletedQuests);
    await _prefs.remove(_keySkillXp);
    await _prefs.remove(_keyStreakData);
    await _prefs.remove(_keyMasterAchievements);
    await _prefs.remove(_keyCompletedCollections);
    await _prefs.remove(_keyQuestPhotos);
    await _prefs.remove(_keyLocale);
    await _prefs.remove(_keyLiveTracking);
    await _prefs.remove(_keyNotifications);
    await _prefs.remove(_keyPendingClaims);
    await _prefs.remove(_keyPendingRevisitSync);
    await _prefs.remove(_keyQuestChains);
  }
}
