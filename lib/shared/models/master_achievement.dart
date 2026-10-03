/// Types of requirements for master achievements
enum MasterRequirementType {
  /// Complete all achievements in a collection
  completeCollection,
  /// Reach a certain level in a skill
  skillLevel,
  /// Complete a certain number of quests
  questCount,
  /// Reach a user level
  userLevel,
  /// Unlock a certain number of achievements
  achievementCount,
  /// Complete quests in a specific category
  questCategory,
  /// Reach a certain streak
  streakDays,
  /// Unlock [MasterRequirement.targetValue] achievements in the collection
  /// [MasterRequirement.targetId]
  collectionProgress,
  /// Unlock [MasterRequirement.targetValue] of the comma-separated
  /// achievement ids in [MasterRequirement.targetId]
  anyOfAchievements,
  /// Unlock [MasterRequirement.targetValue] achievements tagged
  /// [MasterRequirement.targetId] (e.g. an Israel facet tag)
  tagCount,
  /// Visit [MasterRequirement.targetValue] distinct Israel regions
  israelRegionCount,
}

/// A single requirement for a master achievement
class MasterRequirement {
  final MasterRequirementType type;
  final String? targetId; // collectionId, skillId, categoryId
  final int targetValue; // level, count, etc.
  final String description;

  const MasterRequirement({
    required this.type,
    this.targetId,
    required this.targetValue,
    required this.description,
  });
}

/// Tier for master achievements (higher rewards than regular)
enum MasterTier {
  elite,      // 100 XP
  legendary,  // 200 XP
  mythic,     // 500 XP
}

/// A master achievement - meta-achievement with special requirements
class MasterAchievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final MasterTier tier;
  final int xpReward;
  final List<MasterRequirement> requirements;
  final String? unlockMessage; // Special message when unlocked
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0

  const MasterAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.xpReward,
    required this.requirements,
    this.unlockMessage,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
  });

  static int xpForTier(MasterTier tier) {
    return switch (tier) {
      MasterTier.elite => 100,
      MasterTier.legendary => 200,
      MasterTier.mythic => 500,
    };
  }

  MasterAchievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
  }) {
    return MasterAchievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      tier: tier,
      xpReward: xpReward,
      requirements: requirements,
      unlockMessage: unlockMessage,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }
}
