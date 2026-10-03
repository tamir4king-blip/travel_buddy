import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';

/// Collections whose members represent individual countries. Used by the
/// zone filter to figure out which country the user is currently in.
const _countryCollections = <String>{
  'europe',
  'africa',
  'asia',
  'americas',
  'south-america',
  'oceania',
};

/// The country achievement whose polygon (or radius) contains the user's
/// current GPS position, or null if none matches. Used by the "display
/// only within zone" filter to default its zone to the user's country.
final currentCountryProvider = Provider<Achievement?>((ref) {
  final geo = ref.watch(geolocationProvider);
  if (!geo.hasLocation) return null;

  final achievements = ref.watch(achievementsProvider);
  final lat = geo.latitude!;
  final lng = geo.longitude!;

  for (final a in achievements.allAchievements) {
    if (!_countryCollections.contains(a.collectionId)) continue;
    if (isWithinClaimArea(lat, lng, a)) return a;
  }
  return null;
});
