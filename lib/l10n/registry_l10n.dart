import 'dart:ui';

import 'package:travel_buddy_mobile/l10n/registry_translations_he.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_activity_quests.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_master_achievements.dart';

/// Localized lookup for registry data (quests, skills, achievements, collections).
/// Falls back to the English string if no translation is found for the locale.
class RegistryL10n {
  RegistryL10n._();

  // ── Regular Achievements ──

  static String achievementTitle(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heAchievementTitles[id] ?? israelHebrewTitles[id] ?? fallback;
    }
    return fallback;
  }

  static String achievementDescription(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heAchievementDescriptions[id] ?? fallback;
    }
    return fallback;
  }

  // ── Collections ──

  static String collectionName(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heCollectionNames[id] ?? IsraelList.byId(id)?.he ?? fallback;
    }
    return fallback;
  }

  // ── Skills ──

  static String skillName(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heSkillNames[id] ?? fallback;
    }
    return fallback;
  }

  static String skillDescription(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heSkillDescriptions[id] ?? fallback;
    }
    return fallback;
  }

  // ── Quests ──

  static String questTitle(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heQuestTitles[id] ?? israelQuestHebrew[id]?.$1 ?? fallback;
    }
    return fallback;
  }

  static String questDescription(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heQuestDescriptions[id] ?? israelQuestHebrew[id]?.$2 ?? fallback;
    }
    return fallback;
  }

  // ── Master Achievements ──

  static String masterTitle(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heMasterAchievementTitles[id] ?? israelMasterHebrew[id]?.$1 ?? fallback;
    }
    return fallback;
  }

  static String masterDescription(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heMasterAchievementDescriptions[id] ??
          israelMasterHebrew[id]?.$2 ??
          fallback;
    }
    return fallback;
  }

  static String masterUnlockMessage(Locale locale, String id, String fallback) {
    if (locale.languageCode == 'he') {
      return heMasterAchievementUnlockMessages[id] ?? fallback;
    }
    return fallback;
  }

  static String masterRequirement(Locale locale, String description) {
    if (locale.languageCode == 'he') {
      return heMasterRequirementDescriptions[description] ?? description;
    }
    return description;
  }
}
