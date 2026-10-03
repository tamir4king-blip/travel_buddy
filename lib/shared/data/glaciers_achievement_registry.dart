import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// Glaciers and ice fields around the world — a curated set of the most
/// iconic ice features across every continent.
///
/// Polygons are coarse 4-7 vertex approximations of each glacier's footprint
/// (authored by hand, not from GIS data). They look blocky on the map but
/// work for in-polygon proximity checks. Swap for Natural Earth /
/// OpenStreetMap polygons later for accurate outlines.
const glaciersAchievementRegistry = <Achievement>[
  // ══════════════════════════════════════════════════
  // SOUTH AMERICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'glacier-perito-moreno',
    title: 'Perito Moreno Glacier',
    description:
        'Stand before the calving wall of one of the few glaciers on Earth still advancing — a 5 km face of blue ice in Argentine Patagonia.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: -50.4814,
    longitude: -73.0420,
    claimRadius: 15000,
    claimPolygon: [
      [-50.42, -73.36],
      [-50.42, -73.05],
      [-50.50, -72.97],
      [-50.55, -73.10],
      [-50.55, -73.30],
      [-50.50, -73.42],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'south-america', 'argentina', 'unesco'],
  ),

  // ══════════════════════════════════════════════════
  // EUROPE
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'glacier-vatnajokull',
    title: 'Vatnajökull',
    description:
        'Cross Europe\'s largest ice cap — a 7,900 km² frozen plateau covering 8% of Iceland, riddled with sub-glacial volcanoes.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: 64.4163,
    longitude: -16.7956,
    claimRadius: 60000,
    claimPolygon: [
      [64.85, -17.40],
      [64.92, -16.30],
      [64.50, -15.40],
      [64.10, -15.50],
      [63.95, -16.70],
      [64.10, -17.60],
      [64.55, -17.75],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'europe', 'iceland', 'unesco'],
  ),
  Achievement(
    id: 'glacier-aletsch',
    title: 'Aletsch Glacier',
    description:
        'Walk above the longest glacier in the Alps — a 23 km river of ice winding down from the Jungfrau region of Switzerland.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: 46.5060,
    longitude: 8.0395,
    claimRadius: 12000,
    claimPolygon: [
      [46.55, 7.95],
      [46.55, 8.10],
      [46.43, 8.12],
      [46.36, 8.04],
      [46.40, 7.96],
      [46.50, 7.93],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'europe', 'switzerland', 'unesco'],
  ),
  Achievement(
    id: 'glacier-jostedalsbreen',
    title: 'Jostedalsbreen',
    description:
        'Trek beneath the largest glacier in continental Europe — a 474 km² ice cap spanning the fjordlands of western Norway.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: 61.6500,
    longitude: 7.0500,
    claimRadius: 25000,
    claimPolygon: [
      [61.95, 7.50],
      [61.85, 7.85],
      [61.55, 7.55],
      [61.30, 6.85],
      [61.45, 6.50],
      [61.75, 6.65],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'europe', 'norway'],
  ),

  // ══════════════════════════════════════════════════
  // NORTH AMERICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'glacier-athabasca',
    title: 'Athabasca Glacier & Columbia Icefield',
    description:
        'Ride a snowcoach onto a tongue of the Columbia Icefield — the largest icefield in the Canadian Rockies, straddling the Continental Divide.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: 52.1880,
    longitude: -117.2370,
    claimRadius: 18000,
    claimPolygon: [
      [52.40, -117.55],
      [52.35, -116.95],
      [52.05, -116.95],
      [51.95, -117.40],
      [52.10, -117.65],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'americas', 'canada'],
  ),
  Achievement(
    id: 'glacier-mendenhall',
    title: 'Mendenhall Glacier',
    description:
        'Hike to the face of a glowing blue glacier just outside Juneau — a 21 km tongue flowing from the Juneau Icefield in Alaska.',
    tier: AchievementTier.silver,
    xpReward: 25,
    latitude: 58.4359,
    longitude: -134.5446,
    claimRadius: 10000,
    claimPolygon: [
      [58.50, -134.60],
      [58.50, -134.45],
      [58.42, -134.42],
      [58.35, -134.55],
      [58.40, -134.65],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'americas', 'usa'],
  ),

  // ══════════════════════════════════════════════════
  // OCEANIA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'glacier-franz-josef',
    title: 'Franz Josef Glacier',
    description:
        'Walk the moraine of a temperate-rainforest glacier — a 12 km river of ice flowing nearly to sea level on New Zealand\'s West Coast.',
    tier: AchievementTier.silver,
    xpReward: 25,
    latitude: -43.4654,
    longitude: 170.1830,
    claimRadius: 8000,
    claimPolygon: [
      [-43.43, 170.20],
      [-43.42, 170.27],
      [-43.48, 170.27],
      [-43.50, 170.20],
      [-43.49, 170.14],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'oceania', 'new-zealand', 'unesco'],
  ),
  Achievement(
    id: 'glacier-fox',
    title: 'Fox Glacier',
    description:
        'Trek the bouldery valley of Fox Glacier — sister ice river to Franz Josef, descending the western slopes of the Southern Alps.',
    tier: AchievementTier.silver,
    xpReward: 25,
    latitude: -43.5360,
    longitude: 170.0210,
    claimRadius: 8000,
    claimPolygon: [
      [-43.49, 170.00],
      [-43.50, 170.10],
      [-43.55, 170.10],
      [-43.58, 170.05],
      [-43.55, 169.97],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'oceania', 'new-zealand', 'unesco'],
  ),

  // ══════════════════════════════════════════════════
  // ANTARCTICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'glacier-antarctic-shelves',
    title: 'Antarctic Ice Shelves',
    description:
        'Set foot on the white continent — vast floating ice shelves like Ross, Ronne, and Filchner cover an area larger than Greenland.',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: -82.0,
    longitude: -55.0,
    claimRadius: 2000000, // 2,000 km — covers most of the continent
    claimPolygon: [
      [-65.0, -85.0],
      [-65.0, -40.0],
      [-78.0, -30.0],
      [-85.0, -50.0],
      [-85.0, -80.0],
      [-78.0, -90.0],
    ],
    collectionId: 'glaciers',
    tags: ['glacier', 'antarctica', 'ice-shelf'],
  ),
];
