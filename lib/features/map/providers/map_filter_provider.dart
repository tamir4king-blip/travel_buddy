import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the "display only within zone" filter clips markers.
enum ZoneMode {
  /// Markers are clipped to the polygon of a specific country. Defaults
  /// to the user's current country when no explicit country is selected.
  country,

  /// Markers are clipped to the polygon of a specific continent.
  continent,

  /// Markers are clipped to a radius (in km) around the user.
  radius,

  /// No clipping — every marker on the planet passes the zone filter.
  unlimited,
}

class MapFilterState {
  final bool showAchievements;
  final bool showQuests;
  final bool showSkills;
  final bool showQuestChains;
  /// Selected subfilters for achievements (collectionIds), empty = show all
  final Set<String> selectedAchievementCollections;
  /// Selected subfilters for quests (categories), empty = show all
  final Set<String> selectedQuestCategories;
  /// Selected subfilters for skills (skill ids), empty = show all
  final Set<String> selectedSkillIds;
  /// Selected subfilters for quest chains (rarities), empty = show all
  final Set<String> selectedQuestChainRarities;

  /// Collection ids whose unlocked areas (member polygons + outer hull)
  /// are permanently rendered on the map. One toggle per collection in
  /// the filter sheet; empty = no overlays.
  final Set<String> unlockedAreaCollections;

  /// Global filter: when true, hide locked achievement markers so only
  /// already-unlocked achievements are shown on the map.
  final bool showOnlyUnlocked;

  /// When true, the map only shows markers inside the user's zone. The
  /// shape of the zone is controlled by [zoneMode].
  final bool zoneFilterEnabled;

  /// Which shape the zone filter uses — the user's current country
  /// polygon or a radius around their location.
  final ZoneMode zoneMode;

  /// Radius in kilometers used when [zoneMode] is [ZoneMode.radius].
  final double zoneRadiusKm;

  /// Achievement id of an explicitly selected country. When null and
  /// [zoneMode] is [ZoneMode.country], the user's auto-detected country
  /// is used instead.
  final String? zoneCountryAchievementId;

  /// Achievement id of the selected continent (always one of the six
  /// 'continent-*' achievements). Used when [zoneMode] is
  /// [ZoneMode.continent].
  final String? zoneContinentAchievementId;

  const MapFilterState({
    this.showAchievements = true,
    this.showQuests = true,
    this.showSkills = true,
    this.showQuestChains = true,
    this.selectedAchievementCollections = const {},
    this.selectedQuestCategories = const {},
    this.selectedSkillIds = const {},
    this.selectedQuestChainRarities = const {},
    this.unlockedAreaCollections = const {},
    this.showOnlyUnlocked = false,
    this.zoneFilterEnabled = true,
    this.zoneMode = ZoneMode.country,
    this.zoneRadiusKm = 500,
    this.zoneCountryAchievementId,
    this.zoneContinentAchievementId,
  });

  /// Number of active subfilters across all categories.
  int get activeFilterCount =>
      selectedAchievementCollections.length +
      selectedQuestCategories.length +
      selectedSkillIds.length +
      selectedQuestChainRarities.length;

  /// True if any category is hidden or any subfilters are applied.
  bool get hasActiveFilters =>
      !showAchievements ||
      !showQuests ||
      !showSkills ||
      !showQuestChains ||
      showOnlyUnlocked ||
      zoneFilterEnabled ||
      unlockedAreaCollections.isNotEmpty ||
      activeFilterCount > 0;

  MapFilterState copyWith({
    bool? showAchievements,
    bool? showQuests,
    bool? showSkills,
    bool? showQuestChains,
    Set<String>? selectedAchievementCollections,
    Set<String>? selectedQuestCategories,
    Set<String>? selectedSkillIds,
    Set<String>? selectedQuestChainRarities,
    Set<String>? unlockedAreaCollections,
    bool? showOnlyUnlocked,
    bool? zoneFilterEnabled,
    ZoneMode? zoneMode,
    double? zoneRadiusKm,
    Object? zoneCountryAchievementId = _unset,
    Object? zoneContinentAchievementId = _unset,
  }) {
    return MapFilterState(
      showAchievements: showAchievements ?? this.showAchievements,
      showQuests: showQuests ?? this.showQuests,
      showSkills: showSkills ?? this.showSkills,
      showQuestChains: showQuestChains ?? this.showQuestChains,
      selectedAchievementCollections:
          selectedAchievementCollections ?? this.selectedAchievementCollections,
      selectedQuestCategories:
          selectedQuestCategories ?? this.selectedQuestCategories,
      selectedSkillIds: selectedSkillIds ?? this.selectedSkillIds,
      selectedQuestChainRarities:
          selectedQuestChainRarities ?? this.selectedQuestChainRarities,
      unlockedAreaCollections:
          unlockedAreaCollections ?? this.unlockedAreaCollections,
      showOnlyUnlocked: showOnlyUnlocked ?? this.showOnlyUnlocked,
      zoneFilterEnabled: zoneFilterEnabled ?? this.zoneFilterEnabled,
      zoneMode: zoneMode ?? this.zoneMode,
      zoneRadiusKm: zoneRadiusKm ?? this.zoneRadiusKm,
      zoneCountryAchievementId:
          identical(zoneCountryAchievementId, _unset)
              ? this.zoneCountryAchievementId
              : zoneCountryAchievementId as String?,
      zoneContinentAchievementId:
          identical(zoneContinentAchievementId, _unset)
              ? this.zoneContinentAchievementId
              : zoneContinentAchievementId as String?,
    );
  }
}

const Object _unset = Object();

class MapFilterNotifier extends StateNotifier<MapFilterState> {
  MapFilterNotifier() : super(const MapFilterState());

  void resetAll() => state = const MapFilterState();

  void toggleAchievements() =>
      state = state.copyWith(
        showAchievements: !state.showAchievements,
        selectedAchievementCollections: const {},
      );

  void toggleQuests() =>
      state = state.copyWith(
        showQuests: !state.showQuests,
        selectedQuestCategories: const {},
      );

  void toggleSkills() =>
      state = state.copyWith(
        showSkills: !state.showSkills,
        selectedSkillIds: const {},
      );

  void toggleQuestChains() =>
      state = state.copyWith(
        showQuestChains: !state.showQuestChains,
        selectedQuestChainRarities: const {},
      );

  void toggleAchievementCollection(String collectionId) {
    final current = Set<String>.from(state.selectedAchievementCollections);
    if (current.contains(collectionId)) {
      current.remove(collectionId);
    } else {
      current.add(collectionId);
    }
    state = state.copyWith(selectedAchievementCollections: current);
  }

  void setAchievementCollections(Set<String> ids) =>
      state = state.copyWith(selectedAchievementCollections: ids);

  void toggleQuestCategory(String category) {
    final current = Set<String>.from(state.selectedQuestCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(selectedQuestCategories: current);
  }

  void toggleSkillId(String skillId) {
    final current = Set<String>.from(state.selectedSkillIds);
    if (current.contains(skillId)) {
      current.remove(skillId);
    } else {
      current.add(skillId);
    }
    state = state.copyWith(selectedSkillIds: current);
  }

  void toggleQuestChainRarity(String rarity) {
    final current = Set<String>.from(state.selectedQuestChainRarities);
    if (current.contains(rarity)) {
      current.remove(rarity);
    } else {
      current.add(rarity);
    }
    state = state.copyWith(selectedQuestChainRarities: current);
  }

  void clearAchievementFilters() =>
      state = state.copyWith(selectedAchievementCollections: const {});

  void clearActivityFilters() =>
      state = state.copyWith(
        selectedQuestCategories: const {},
        selectedSkillIds: const {},
      );

  void clearQuestFilters() =>
      state = state.copyWith(selectedQuestChainRarities: const {});

  void toggleUnlockedAreaCollection(String collectionId) {
    final current = Set<String>.from(state.unlockedAreaCollections);
    if (current.contains(collectionId)) {
      current.remove(collectionId);
    } else {
      current.add(collectionId);
    }
    state = state.copyWith(unlockedAreaCollections: current);
  }

  void setUnlockedAreaCollections(Set<String> ids) =>
      state = state.copyWith(unlockedAreaCollections: ids);

  void clearUnlockedAreaCollections() =>
      state = state.copyWith(unlockedAreaCollections: const {});

  void toggleShowOnlyUnlocked() =>
      state = state.copyWith(showOnlyUnlocked: !state.showOnlyUnlocked);

  void toggleZoneFilter() =>
      state = state.copyWith(zoneFilterEnabled: !state.zoneFilterEnabled);

  void setZoneMode(ZoneMode mode) =>
      state = state.copyWith(zoneMode: mode);

  void setZoneRadiusKm(double km) =>
      state = state.copyWith(zoneRadiusKm: km.clamp(10, 5000));

  /// Set the explicit country achievement id used by [ZoneMode.country].
  /// Pass null to fall back to the user's current country.
  void setZoneCountry(String? achievementId) => state = state.copyWith(
        zoneCountryAchievementId: achievementId,
      );

  /// Set the continent achievement id used by [ZoneMode.continent].
  void setZoneContinent(String? achievementId) => state = state.copyWith(
        zoneContinentAchievementId: achievementId,
      );
}

final mapFilterProvider =
    StateNotifierProvider<MapFilterNotifier, MapFilterState>(
  (ref) => MapFilterNotifier(),
);
