enum QuestDifficulty { easy, medium, hard, legendary }

enum VerificationMethod { photo, manual, location, timeBased }

/// A geographic location where an activity can be performed.
class ActivityLocation {
  final double latitude;
  final double longitude;

  const ActivityLocation({required this.latitude, required this.longitude});
}

class SideQuest {
  final String id;
  final String title;
  final String description;
  final String category;
  final String skillType;
  final QuestDifficulty difficulty;
  final int xpReward;
  final VerificationMethod verification;
  final bool isRepeatable;
  final int maxCompletions;
  final int completionCount;
  final bool isCompleted;
  final String? requiredSkillType;
  final int? requiredSkillLevel;
  final List<String> requiredQuestIds;
  final double? latitude;
  final double? longitude;

  /// Additional locations where this activity can be performed.
  final List<ActivityLocation> locations;

  const SideQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.skillType,
    required this.difficulty,
    required this.xpReward,
    this.verification = VerificationMethod.manual,
    this.isRepeatable = false,
    this.maxCompletions = 1,
    this.completionCount = 0,
    this.isCompleted = false,
    this.requiredSkillType,
    this.requiredSkillLevel,
    this.requiredQuestIds = const [],
    this.latitude,
    this.longitude,
    this.locations = const [],
  });

  /// All locations: primary lat/lng (if set) + additional locations.
  List<ActivityLocation> get allLocations {
    final result = <ActivityLocation>[];
    if (latitude != null && longitude != null) {
      result.add(ActivityLocation(latitude: latitude!, longitude: longitude!));
    }
    result.addAll(locations);
    return result;
  }

  bool isUnlocked({
    required Map<String, int> skillLevels,
    required List<SideQuest> allQuests,
  }) {
    if (requiredSkillType != null && requiredSkillLevel != null) {
      final currentLevel = skillLevels[requiredSkillType] ?? 0;
      if (currentLevel < requiredSkillLevel!) return false;
    }
    for (final reqId in requiredQuestIds) {
      final reqQuest = allQuests.where((q) => q.id == reqId).firstOrNull;
      if (reqQuest == null || !reqQuest.isCompleted) return false;
    }
    return true;
  }

  SideQuest copyWith({
    int? completionCount,
    bool? isCompleted,
    String? requiredSkillType,
    int? requiredSkillLevel,
    List<String>? requiredQuestIds,
    double? latitude,
    double? longitude,
    List<ActivityLocation>? locations,
  }) {
    return SideQuest(
      id: id,
      title: title,
      description: description,
      category: category,
      skillType: skillType,
      difficulty: difficulty,
      xpReward: xpReward,
      verification: verification,
      isRepeatable: isRepeatable,
      maxCompletions: maxCompletions,
      completionCount: completionCount ?? this.completionCount,
      isCompleted: isCompleted ?? this.isCompleted,
      requiredSkillType: requiredSkillType ?? this.requiredSkillType,
      requiredSkillLevel: requiredSkillLevel ?? this.requiredSkillLevel,
      requiredQuestIds: requiredQuestIds ?? this.requiredQuestIds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locations: locations ?? this.locations,
    );
  }
}
