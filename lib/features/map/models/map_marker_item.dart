import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/achievement_marker.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/marker_icons.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';

enum MapMarkerType { achievement, quest, skill, questChain }

sealed class MapMarkerItem {
  final String id;
  final double latitude;
  final double longitude;
  final MapMarkerType type;
  final Color pinColor;

  const MapMarkerItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.pinColor,
  });

  /// Icon glyph rendered inside the pin circle. Subclasses override.
  IconData get iconData => LucideIcons.mapPin;

  /// Whether the pin should render in its locked visual state (muted fill).
  bool get isLocked => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarkerItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          type == other.type &&
          pinColor == other.pinColor &&
          iconData.codePoint == other.iconData.codePoint &&
          isLocked == other.isLocked;

  @override
  int get hashCode => Object.hash(
      id, latitude, longitude, type, pinColor, iconData.codePoint, isLocked);
}

class AchievementMarkerItem extends MapMarkerItem {
  final Achievement achievement;

  AchievementMarkerItem({required this.achievement})
      : super(
          id: achievement.id,
          latitude: achievement.latitude!,
          longitude: achievement.longitude!,
          type: MapMarkerType.achievement,
          pinColor: AchievementMarker.tierColor(achievement.tier),
        );

  @override
  IconData get iconData =>
      achievement.isUnlocked
          ? iconForCollection(achievement.collectionId)
          : LucideIcons.lock;

  @override
  bool get isLocked => !achievement.isUnlocked;
}

class QuestMarkerItem extends MapMarkerItem {
  final SideQuest quest;

  QuestMarkerItem({required this.quest, int locationIndex = 0})
      : super(
          id: locationIndex == 0 ? quest.id : '${quest.id}@$locationIndex',
          latitude: quest.latitude!,
          longitude: quest.longitude!,
          type: MapMarkerType.quest,
          pinColor: _questDifficultyColor(quest.difficulty),
        );

  static Color _questDifficultyColor(QuestDifficulty difficulty) {
    return switch (difficulty) {
      QuestDifficulty.easy => AppColors.success,
      QuestDifficulty.medium => AppColors.accent,
      QuestDifficulty.hard => const Color(0xFFF97316),
      QuestDifficulty.legendary => const Color(0xFF9333EA),
    };
  }
}

class SkillMarkerItem extends MapMarkerItem {
  final SkillGroup skill;

  SkillMarkerItem({required this.skill})
      : super(
          id: skill.id,
          latitude: skill.latitude!,
          longitude: skill.longitude!,
          type: MapMarkerType.skill,
          pinColor: parseHexColor(skill.gradientStart),
        );

  static Color parseHexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class QuestChainMarkerItem extends MapMarkerItem {
  final Quest questChain;

  QuestChainMarkerItem({
    required this.questChain,
    required double latitude,
    required double longitude,
  }) : super(
          id: 'chain-${questChain.id}',
          latitude: latitude,
          longitude: longitude,
          type: MapMarkerType.questChain,
          pinColor: rarityColor(questChain.rarity),
        );

  static Color rarityColor(QuestRarity rarity) {
    return switch (rarity) {
      QuestRarity.common => AppColors.success,
      QuestRarity.rare => AppColors.info,
      QuestRarity.epic => const Color(0xFF9333EA),
      QuestRarity.legendary => const Color(0xFFEAB308),
    };
  }
}
