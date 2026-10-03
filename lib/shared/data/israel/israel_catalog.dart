/// Israel Explorer catalog — the MTP-style "lists" of places across Israel.
///
/// Every [IsraelPlace] becomes a regular geofenced [Achievement] (id prefix
/// `il-`), so detection, claiming, revisits, XP and sync all work unchanged.
/// On top of that each place carries a [IsraelRegion] and a set of
/// [IsraelFacet]s, which the profile turns into per-person data points:
/// regional coverage, list progress and a "Traveler DNA" archetype.
///
/// Pure Dart (no Flutter imports) so tool/ seed generators can import it.
library;

import 'package:travel_buddy_mobile/shared/models/achievement.dart';

import 'israel_places_center.dart';
import 'israel_places_cities.dart';
import 'israel_places_jerusalem.dart';
import 'israel_places_more.dart';
import 'israel_places_north.dart';
import 'israel_places_south.dart';

// ── Lists ────────────────────────────────────────────────────────────────────

/// An MTP-style list the user can work through. Each list is an achievement
/// collection (`id`), with defaults its places inherit.
enum IsraelList {
  regions('il-regions', 'Regions of Israel', 'אזורי הארץ', '🗺️', 300,
      AchievementTier.gold, 15000, [IsraelFacet.views]),
  cities('il-cities', 'Cities & Towns', 'ערים ועיירות', '🏙️', 250,
      AchievementTier.bronze, 2500, [IsraelFacet.urban]),
  villages('il-villages', 'Villages & Communities', 'כפרים ומושבות', '🏘️',
      200, AchievementTier.silver, 1200, [IsraelFacet.culture]),
  unesco('il-unesco', 'UNESCO World Heritage', 'אתרי מורשת עולמית', '🏛️',
      400, AchievementTier.gold, 800, [IsraelFacet.history]),
  nationalParks('il-national-parks', 'National Parks', 'גנים לאומיים', '🏞️',
      300, AchievementTier.silver, 700, [IsraelFacet.history, IsraelFacet.nature]),
  nature('il-nature', 'Nature Reserves & Caves', 'שמורות טבע ומערות', '🌿',
      250, AchievementTier.silver, 900, [IsraelFacet.nature]),
  water('il-water', 'Springs, Streams & Waterfalls', 'מעיינות, נחלים ומפלים',
      '💧', 250, AchievementTier.silver, 800, [IsraelFacet.water, IsraelFacet.nature]),
  coast('il-coast', 'Beaches & Reefs', 'חופים ושוניות', '🏖️', 200,
      AchievementTier.bronze, 700, [IsraelFacet.coast]),
  heights('il-heights', 'Peaks, Craters & Viewpoints', 'פסגות, מכתשים ותצפיות',
      '⛰️', 250, AchievementTier.silver, 1000, [IsraelFacet.views]),
  heritage('il-heritage', 'History & Heritage', 'היסטוריה ומורשת', '📜', 250,
      AchievementTier.silver, 500, [IsraelFacet.history]),
  sacred('il-sacred', 'Sacred Places', 'מקומות קדושים', '🕊️', 250,
      AchievementTier.silver, 500, [IsraelFacet.faith]),
  museums('il-museums', 'Museums', 'מוזיאונים', '🖼️', 200,
      AchievementTier.silver, 400, [IsraelFacet.culture]),
  food('il-food', 'Markets, Food & Wine', 'שווקים, אוכל ויין', '🥙', 200,
      AchievementTier.bronze, 400, [IsraelFacet.food]),
  experiences('il-experiences', 'Iconic Experiences', 'חוויות איקוניות', '⭐',
      400, AchievementTier.gold, 800, [IsraelFacet.adventure]);

  const IsraelList(this.id, this.name, this.he, this.emoji, this.bonusXp,
      this.defaultTier, this.defaultRadius, this.facets);

  /// Achievement collection id.
  final String id;
  final String name;
  final String he;
  final String emoji;

  /// Collection completion bonus (mirrored into collection_definitions).
  final int bonusXp;
  final AchievementTier defaultTier;

  /// Default claim radius in meters.
  final double defaultRadius;

  /// Facets every place in the list contributes to.
  final List<IsraelFacet> facets;

  String label(String languageCode) => languageCode == 'he' ? he : name;

  static IsraelList? byId(String? id) {
    for (final l in values) {
      if (l.id == id) return l;
    }
    return null;
  }
}

/// Collection ids of the Israel lists.
final israelListIds = {for (final l in IsraelList.values) l.id};

/// Lists whose places people pass through constantly (home town, home
/// region) — revisits use the extended 1-week cooldown.
const israelExtendedCooldownListIds = {'il-regions', 'il-cities', 'il-villages'};

// ── Regions ──────────────────────────────────────────────────────────────────

/// Geographic regions, north to south. Each region also has its own
/// achievement in [IsraelList.regions].
enum IsraelRegion {
  golan('golan', 'Golan Heights', 'רמת הגולן'),
  upperGalilee('upper-galilee', 'Upper Galilee', 'הגליל העליון'),
  westernGalilee('western-galilee', 'Western Galilee', 'הגליל המערבי'),
  kinneret('kinneret', 'Sea of Galilee', 'הכנרת'),
  lowerGalilee('lower-galilee', 'Lower Galilee', 'הגליל התחתון'),
  valleys('valleys', 'Jezreel & Beit She\'an Valleys', 'עמק יזרעאל ועמק בית שאן'),
  haifaCarmel('haifa-carmel', 'Haifa & Carmel', 'חיפה והכרמל'),
  sharon('sharon', 'Sharon', 'השרון'),
  telAviv('tel-aviv', 'Tel Aviv & Gush Dan', 'תל אביב וגוש דן'),
  shfela('shfela', 'Judean Lowlands', 'השפלה'),
  judeanHills('judean-hills', 'Judean Hills', 'הרי יהודה'),
  jerusalem('jerusalem', 'Jerusalem', 'ירושלים'),
  deadSea('dead-sea', 'Dead Sea & Judean Desert', 'ים המלח ומדבר יהודה'),
  northernNegev('northern-negev', 'Northern Negev', 'צפון הנגב'),
  negevHighlands('negev-highlands', 'Negev Highlands', 'הר הנגב'),
  arava('arava', 'Arava', 'הערבה'),
  eilat('eilat', 'Eilat & the Red Sea', 'אילת וים סוף');

  const IsraelRegion(this.id, this.name, this.he);

  final String id;
  final String name;
  final String he;

  String label(String languageCode) => languageCode == 'he' ? he : name;

  /// Every place here also counts toward the desert facet.
  bool get isDesert => const {
        IsraelRegion.deadSea,
        IsraelRegion.northernNegev,
        IsraelRegion.negevHighlands,
        IsraelRegion.arava,
      }.contains(this);

  /// Tag stored on every achievement in this region.
  String get tag => '$regionTagPrefix$id';

  static IsraelRegion? fromTags(Iterable<String> tags) {
    for (final t in tags) {
      if (!t.startsWith(regionTagPrefix)) continue;
      final id = t.substring(regionTagPrefix.length);
      for (final r in values) {
        if (r.id == id) return r;
      }
    }
    return null;
  }
}

const regionTagPrefix = 'il-region:';

// ── Facets (Traveler DNA) ────────────────────────────────────────────────────

/// Interest dimensions. A person's mix of facets across unlocked places is
/// their "Traveler DNA"; the dominant facet names their archetype.
enum IsraelFacet {
  nature('Nature', 'טבע', '🌿', 'Trail Seeker', 'מחפש/ת שבילים'),
  water('Water', 'מים', '💧', 'Spring Chaser', 'צייד/ת מעיינות'),
  coast('Sea', 'ים', '🌊', 'Sea Soul', 'נשמה ימית'),
  desert('Desert', 'מדבר', '🏜️', 'Desert Wanderer', 'נווד/ת מדבר'),
  views('Views', 'נופים', '🔭', 'Horizon Hunter', 'צייד/ת אופקים'),
  history('History', 'היסטוריה', '🏺', 'Time Traveler', 'נוסע/ת בזמן'),
  faith('Faith', 'אמונה', '🕊️', 'Pilgrim', 'עולה רגל'),
  culture('Culture', 'תרבות', '🎭', 'Culture Curator', 'אוצר/ת תרבות'),
  urban('Cities', 'ערים', '🏙️', 'City Hopper', 'קופץ/ת ערים'),
  food('Food', 'אוכל', '🥙', 'Flavor Hunter', 'צייד/ת טעמים'),
  adventure('Adventure', 'הרפתקה', '🧗', 'Thrill Seeker', 'מחפש/ת ריגושים'),
  wildlife('Wildlife', 'חיות בר', '🦅', 'Wild Tracker', 'גשש/ית חיות בר');

  const IsraelFacet(this.name, this.he, this.emoji, this.archetype, this.archetypeHe);

  final String name;
  final String he;
  final String emoji;
  final String archetype;
  final String archetypeHe;

  String label(String languageCode) => languageCode == 'he' ? he : name;
  String archetypeLabel(String languageCode) =>
      languageCode == 'he' ? archetypeHe : archetype;

  String get tag => '$facetTagPrefix$name'.toLowerCase();

  static IsraelFacet? fromTag(String tag) {
    for (final f in values) {
      if (f.tag == tag) return f;
    }
    return null;
  }
}

const facetTagPrefix = 'il-facet:';

// ── Places ───────────────────────────────────────────────────────────────────

class IsraelPlace {
  const IsraelPlace(
    this.id,
    this.title,
    this.he,
    this.list,
    this.region,
    this.lat,
    this.lng,
    this.description, {
    this.radius,
    this.tier,
    this.facets = const [],
  });

  /// Achievement id, always prefixed `il-`.
  final String id;
  final String title;
  final String he;
  final IsraelList list;
  final IsraelRegion region;
  final double lat;
  final double lng;
  final String description;

  /// Claim radius in meters; defaults to the list's.
  final double? radius;

  /// Defaults to the list's tier.
  final AchievementTier? tier;

  /// Facets beyond the list's defaults.
  final List<IsraelFacet> facets;

  AchievementTier get effectiveTier => tier ?? list.defaultTier;

  Set<IsraelFacet> get allFacets => {
        ...list.facets,
        ...facets,
        if (region.isDesert) IsraelFacet.desert,
      };

  Achievement toAchievement() => Achievement(
        id: id,
        title: title,
        description: description,
        tier: effectiveTier,
        xpReward: xpForTier(effectiveTier),
        latitude: lat,
        longitude: lng,
        claimRadius: radius ?? list.defaultRadius,
        collectionId: list.id,
        tags: [
          'israel',
          region.tag,
          for (final f in allFacets) f.tag,
        ],
      );

  static int xpForTier(AchievementTier tier) => switch (tier) {
        AchievementTier.bronze => 10,
        AchievementTier.silver => 20,
        AchievementTier.gold => 35,
        AchievementTier.platinum => 50,
      };
}

/// Every Israel place, north to south within each source file.
const israelPlaces = <IsraelPlace>[
  ...israelRegionAndCityPlaces,
  ...israelNorthPlaces,
  ...israelCenterPlaces,
  ...israelJerusalemPlaces,
  ...israelSouthPlaces,
  ...israelMorePlaces,
];

/// The places as achievements, ready for the achievement registry.
final israelAchievementRegistry = <Achievement>[
  for (final p in israelPlaces) p.toAchievement(),
];

/// Hebrew titles for the Israel achievements (looked up by RegistryL10n).
final israelHebrewTitles = <String, String>{
  for (final p in israelPlaces) p.id: p.he,
};

/// Every Israel achievement id (achievements in Israel lists).
bool isIsraelAchievement(Achievement a) => israelListIds.contains(a.collectionId);
