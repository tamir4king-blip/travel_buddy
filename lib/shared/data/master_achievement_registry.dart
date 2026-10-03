import 'package:travel_buddy_mobile/shared/data/israel/israel_master_achievements.dart';
import 'package:travel_buddy_mobile/shared/models/master_achievement.dart';

/// Master Achievement Registry - Elite meta-achievements
/// These unlock by completing collections, reaching milestones, etc.
const masterAchievementRegistry = <MasterAchievement>[
  // ============================================
  // COLLECTION MASTERS - Complete full collections
  // ============================================
  MasterAchievement(
    id: 'master-nature',
    title: 'Nature Master',
    description: 'Complete all Nature collection achievements',
    icon: '🌲',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'You are one with nature!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'nature',
        targetValue: 1,
        description: 'Complete Nature collection',
      ),
    ],
  ),
  MasterAchievement(
    id: 'master-cities',
    title: 'Urban Legend',
    description: 'Complete all Cities collection achievements',
    icon: '🏙️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'The city is your playground!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'cities',
        targetValue: 1,
        description: 'Complete Cities collection',
      ),
    ],
  ),
  MasterAchievement(
    id: 'master-food',
    title: 'Culinary Connoisseur',
    description: 'Complete all Food & Drink collection achievements',
    icon: '🍽️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Your palate knows no bounds!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'food-drink',
        targetValue: 1,
        description: 'Complete Food & Drink collection',
      ),
    ],
  ),
  MasterAchievement(
    id: 'master-culture',
    title: 'Culture Virtuoso',
    description: 'Complete all Culture collection achievements',
    icon: '🎭',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'A true citizen of the world!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'culture',
        targetValue: 1,
        description: 'Complete Culture collection',
      ),
    ],
  ),
  MasterAchievement(
    id: 'master-photography',
    title: 'Visual Storyteller',
    description: 'Complete all Photography collection achievements',
    icon: '📷',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Every picture tells your story!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'photography',
        targetValue: 1,
        description: 'Complete Photography collection',
      ),
    ],
  ),

  // ============================================
  // SKILL MASTERS - Reach high levels in skills
  // ============================================
  MasterAchievement(
    id: 'master-hiker',
    title: 'Trail Legend',
    description: 'Reach level 25 in Hiking skill',
    icon: '🥾',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'No trail can stop you!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.skillLevel,
        targetId: 'hiker',
        targetValue: 25,
        description: 'Reach Hiker level 25',
      ),
    ],
  ),
  MasterAchievement(
    id: 'master-photographer-skill',
    title: 'Lens Master',
    description: 'Reach level 25 in Photography skill',
    icon: '📸',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'You see beauty everywhere!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.skillLevel,
        targetId: 'photographer',
        targetValue: 25,
        description: 'Reach Photographer level 25',
      ),
    ],
  ),
  MasterAchievement(
    id: 'master-chef-skill',
    title: 'Kitchen Royalty',
    description: 'Reach level 25 in Chef skill',
    icon: '👨‍🍳',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'The kitchen bows to you!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.skillLevel,
        targetId: 'chef',
        targetValue: 25,
        description: 'Reach Chef level 25',
      ),
    ],
  ),
  MasterAchievement(
    id: 'master-diver-skill',
    title: 'Deep Sea Legend',
    description: 'Reach level 25 in Diving skill',
    icon: '🤿',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'The ocean reveals its secrets to you!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.skillLevel,
        targetId: 'diver',
        targetValue: 25,
        description: 'Reach Diver level 25',
      ),
    ],
  ),

  // ============================================
  // QUEST MASTERS - Complete many quests
  // ============================================
  MasterAchievement(
    id: 'quest-apprentice',
    title: 'Quest Apprentice',
    description: 'Complete 10 side quests',
    icon: '📜',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Your journey has begun!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.questCount,
        targetValue: 10,
        description: 'Complete 10 quests',
      ),
    ],
  ),
  MasterAchievement(
    id: 'quest-journeyman',
    title: 'Quest Journeyman',
    description: 'Complete 50 side quests',
    icon: '⚔️',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'A seasoned adventurer!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.questCount,
        targetValue: 50,
        description: 'Complete 50 quests',
      ),
    ],
  ),
  MasterAchievement(
    id: 'quest-master',
    title: 'Quest Master',
    description: 'Complete 100 side quests',
    icon: '🏆',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'A true legend of adventure!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.questCount,
        targetValue: 100,
        description: 'Complete 100 quests',
      ),
    ],
  ),

  // ============================================
  // LEVEL MASTERS - Reach user levels
  // ============================================
  MasterAchievement(
    id: 'level-10',
    title: 'Rising Star',
    description: 'Reach user level 10',
    icon: '⭐',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Your star is rising!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.userLevel,
        targetValue: 10,
        description: 'Reach level 10',
      ),
    ],
  ),
  MasterAchievement(
    id: 'level-25',
    title: 'Seasoned Traveler',
    description: 'Reach user level 25',
    icon: '🌟',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Experience is your guide!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.userLevel,
        targetValue: 25,
        description: 'Reach level 25',
      ),
    ],
  ),
  MasterAchievement(
    id: 'level-50',
    title: 'Living Legend',
    description: 'Reach user level 50',
    icon: '💫',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'You are a living legend!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.userLevel,
        targetValue: 50,
        description: 'Reach level 50',
      ),
    ],
  ),

  // ============================================
  // ACHIEVEMENT HUNTERS - Unlock achievements
  // ============================================
  MasterAchievement(
    id: 'collector-bronze',
    title: 'Trophy Collector',
    description: 'Unlock 5 achievements',
    icon: '🥉',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'The collection begins!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.achievementCount,
        targetValue: 5,
        description: 'Unlock 5 achievements',
      ),
    ],
  ),
  MasterAchievement(
    id: 'collector-silver',
    title: 'Achievement Hunter',
    description: 'Unlock 10 achievements',
    icon: '🥈',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Hunting for glory!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.achievementCount,
        targetValue: 10,
        description: 'Unlock 10 achievements',
      ),
    ],
  ),
  MasterAchievement(
    id: 'collector-gold',
    title: 'Master Collector',
    description: 'Unlock all achievements',
    icon: '🥇',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'You have collected them all!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.achievementCount,
        targetValue: 76, // Total achievements in registry (21 local + 55 travel)
        description: 'Unlock all 76 achievements',
      ),
    ],
  ),

  // ============================================
  // STREAK MASTERS - Maintain streaks
  // ============================================
  MasterAchievement(
    id: 'streak-week',
    title: 'Week Warrior',
    description: 'Maintain a 7-day streak',
    icon: '🔥',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'A week of dedication!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.streakDays,
        targetValue: 7,
        description: 'Reach 7-day streak',
      ),
    ],
  ),
  MasterAchievement(
    id: 'streak-month',
    title: 'Monthly Devotee',
    description: 'Maintain a 30-day streak',
    icon: '💥',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'A month of pure dedication!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.streakDays,
        targetValue: 30,
        description: 'Reach 30-day streak',
      ),
    ],
  ),
  MasterAchievement(
    id: 'streak-100',
    title: 'Unstoppable Force',
    description: 'Maintain a 100-day streak',
    icon: '⚡',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'Nothing can stop you!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.streakDays,
        targetValue: 100,
        description: 'Reach 100-day streak',
      ),
    ],
  ),

  // ============================================
  // CATEGORY SPECIALISTS - Quest category masters
  // ============================================
  MasterAchievement(
    id: 'hiking-specialist',
    title: 'Hiking Specialist',
    description: 'Complete 10 hiking quests',
    icon: '🏔️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'The mountains call your name!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.questCategory,
        targetId: 'hiking',
        targetValue: 10,
        description: 'Complete 10 hiking quests',
      ),
    ],
  ),
  MasterAchievement(
    id: 'cooking-specialist',
    title: 'Cooking Specialist',
    description: 'Complete 10 cooking quests',
    icon: '🍳',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'The kitchen is your domain!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.questCategory,
        targetId: 'cooking',
        targetValue: 10,
        description: 'Complete 10 cooking quests',
      ),
    ],
  ),
  MasterAchievement(
    id: 'photography-specialist',
    title: 'Photography Specialist',
    description: 'Complete 10 photography quests',
    icon: '🖼️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'You capture life beautifully!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.questCategory,
        targetId: 'photography',
        targetValue: 10,
        description: 'Complete 10 photography quests',
      ),
    ],
  ),

  // ============================================
  // ULTIMATE MASTERS - Legendary challenges
  // ============================================
  MasterAchievement(
    id: 'jack-of-all-trades',
    title: 'Jack of All Trades',
    description: 'Reach level 10 in 10 different skills',
    icon: '🎯',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'Master of many crafts!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.skillLevel,
        targetId: '_multi_10',
        targetValue: 10,
        description: 'Reach level 10 in 10 skills',
      ),
    ],
  ),
  MasterAchievement(
    id: 'ultimate-traveler',
    title: 'Ultimate Traveler',
    description: 'Complete all collection master achievements',
    icon: '🌍',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'The world is yours!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'nature',
        targetValue: 1,
        description: 'Master Nature collection',
      ),
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'cities',
        targetValue: 1,
        description: 'Master Cities collection',
      ),
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'food-drink',
        targetValue: 1,
        description: 'Master Food & Drink collection',
      ),
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'culture',
        targetValue: 1,
        description: 'Master Culture collection',
      ),
    ],
  ),
  // Israel Explorer masters (combos, regions, Traveler DNA, lists)
  ...israelMasterAchievements,
];

/// Get master achievement by ID
MasterAchievement? getMasterAchievementById(String id) {
  try {
    return masterAchievementRegistry.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
}

/// Get master achievements by tier
List<MasterAchievement> getMasterAchievementsByTier(MasterTier tier) {
  return masterAchievementRegistry.where((m) => m.tier == tier).toList();
}
