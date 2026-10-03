import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// Collection ID sets for grouping achievements.
const continentCollectionIds = {
  'europe', 'americas', 'africa', 'asia', 'south-america', 'oceania',
  'antarctica',
};
const themedCollectionIds = {
  'national-parks', 'ski-resorts', 'capitals', 'ancient-sites',
  'holy-sites', 'seas', 'tourist-destinations', 'glaciers'
};
const localCollectionIds = {'landmarks', 'beaches', 'parks', 'culture'};
const metaCollectionIds = {'continents', 'zones'};

/// Country tag → continent ID mapping.
const countryToContinent = <String, String>{
  'france': 'europe', 'italy': 'europe', 'spain': 'europe',
  'germany': 'europe', 'uk': 'europe', 'netherlands': 'europe',
  'greece': 'europe', 'switzerland': 'europe', 'portugal': 'europe',
  'austria': 'europe', 'croatia': 'europe', 'turkey': 'europe',
  'usa': 'americas', 'canada': 'americas', 'mexico': 'americas',
  'chile': 'south-america', 'peru': 'south-america',
  'south-africa': 'africa', 'egypt': 'africa',
  'japan': 'asia', 'india': 'asia', 'cambodia': 'asia',
  'saudi-arabia': 'asia', 'israel': 'asia', 'uae': 'asia',
  'thailand': 'asia', 'singapore': 'asia', 'indonesia': 'asia',
  'nepal': 'asia', 'china': 'asia', 'pakistan': 'asia',
  'sri-lanka': 'asia', 'myanmar': 'asia',
  'morocco': 'africa', 'ethiopia': 'africa',
  'united-kingdom': 'europe',
  'australia': 'oceania', 'new-zealand': 'oceania',
  'iceland': 'europe', 'norway': 'europe', 'argentina': 'south-america',
};

/// Display labels for countries.
const countryLabels = <String, String>{
  'france': 'France', 'italy': 'Italy', 'spain': 'Spain',
  'germany': 'Germany', 'uk': 'United Kingdom', 'netherlands': 'Netherlands',
  'greece': 'Greece', 'switzerland': 'Switzerland', 'portugal': 'Portugal',
  'austria': 'Austria', 'croatia': 'Croatia', 'turkey': 'Turkey',
  'usa': 'United States', 'canada': 'Canada', 'mexico': 'Mexico',
  'chile': 'Chile', 'peru': 'Peru',
  'south-africa': 'South Africa', 'egypt': 'Egypt',
  'japan': 'Japan', 'india': 'India', 'cambodia': 'Cambodia',
  'saudi-arabia': 'Saudi Arabia', 'israel': 'Israel', 'uae': 'UAE',
  'thailand': 'Thailand', 'singapore': 'Singapore', 'indonesia': 'Indonesia',
  'nepal': 'Nepal', 'china': 'China', 'pakistan': 'Pakistan',
  'sri-lanka': 'Sri Lanka', 'myanmar': 'Myanmar',
  'morocco': 'Morocco', 'ethiopia': 'Ethiopia',
  'united-kingdom': 'United Kingdom',
  'australia': 'Australia', 'new-zealand': 'New Zealand',
  'iceland': 'Iceland', 'norway': 'Norway', 'argentina': 'Argentina',
};

/// Display labels for themed collections.
const themedLabels = <String, String>{
  'national-parks': 'National Parks',
  'ski-resorts': 'Ski Resorts',
  'capitals': 'World Capitals',
  'ancient-sites': 'Ancient Sites',
  'holy-sites': 'Holy Sites',
  'seas': 'Seas',
  'tourist-destinations': 'Top Destinations',
  'glaciers': 'Glaciers & Ice',
};

/// Display labels for local collections.
const localLabels = <String, String>{
  'landmarks': 'Landmarks',
  'beaches': 'Beaches',
  'parks': 'Parks',
  'culture': 'Culture',
};

/// Display labels for continents.
const continentLabels = <String, String>{
  'europe': 'Europe',
  'asia': 'Asia',
  'africa': 'Africa',
  'americas': 'North America',
  'south-america': 'South America',
  'oceania': 'Oceania',
  'antarctica': 'Antarctica',
};

/// Derive continent for a themed-collection achievement via its tags.
String? continentOfThemed(Achievement a) {
  for (final tag in a.tags) {
    if (continentCollectionIds.contains(tag)) return tag;
    final mapped = countryToContinent[tag];
    if (mapped != null) return mapped;
  }
  return null;
}

/// Extract the country tag from a themed-collection achievement.
String? countryOf(Achievement a) {
  for (final tag in a.tags) {
    if (countryToContinent.containsKey(tag)) return tag;
  }
  return null;
}

/// Unified country key for any achievement.
String? countryKey(Achievement a) {
  if (continentCollectionIds.contains(a.collectionId)) {
    final prefix = '${a.collectionId}-';
    if (a.id.startsWith(prefix)) return a.id.substring(prefix.length);
    return null;
  }
  return countryOf(a);
}

/// Unified continent key for any achievement.
String? continentKey(Achievement a) {
  if (continentCollectionIds.contains(a.collectionId)) {
    return a.collectionId;
  }
  return continentOfThemed(a);
}
