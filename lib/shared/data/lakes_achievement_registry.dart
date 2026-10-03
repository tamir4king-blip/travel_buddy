import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// Famous lakes around the world — a fair sample across every continent.
///
/// Polygons are coarse 4-8 vertex approximations of each lake's footprint
/// (authored by hand, not from GIS data). They will look blocky on the
/// map but work fine for in-polygon proximity checks. Swap for Natural
/// Earth / OpenStreetMap polygons later for accurate shorelines.
const lakesAchievementRegistry = <Achievement>[
  // ══════════════════════════════════════════════════
  // ASIA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'lake-baikal',
    title: 'Lake Baikal',
    description:
        'Stand at the shore of the world\'s deepest and oldest lake — a UNESCO wonder in Siberia holding 20% of Earth\'s unfrozen freshwater.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: 53.5,
    longitude: 108.0,
    claimRadius: 30000,
    claimPolygon: [
      [55.8, 109.6],
      [55.2, 110.0],
      [54.0, 109.5],
      [52.4, 107.0],
      [51.5, 104.8],
      [52.3, 104.3],
      [53.8, 107.0],
      [55.0, 108.8],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'asia', 'unesco'],
  ),
  Achievement(
    id: 'lake-caspian',
    title: 'Caspian Sea',
    description:
        'The largest enclosed inland body of water on Earth — straddling Europe and Asia with five bordering nations.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: 42.0,
    longitude: 50.5,
    claimRadius: 50000,
    claimPolygon: [
      [47.2, 51.0],
      [47.0, 53.5],
      [44.5, 53.0],
      [42.0, 52.0],
      [39.5, 53.5],
      [37.0, 53.5],
      [36.8, 51.0],
      [38.0, 48.5],
      [41.5, 48.8],
      [45.5, 49.0],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'asia', 'europe'],
  ),
  Achievement(
    id: 'lake-dead-sea',
    title: 'Dead Sea',
    description:
        'The lowest point on Earth — float effortlessly in its hyper-saline waters between Israel and Jordan.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: 31.5,
    longitude: 35.5,
    claimRadius: 15000,
    claimPolygon: [
      [31.77, 35.47],
      [31.72, 35.57],
      [31.35, 35.58],
      [30.99, 35.50],
      [30.98, 35.37],
      [31.30, 35.38],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'asia', 'middle-east'],
  ),

  // ══════════════════════════════════════════════════
  // AFRICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'lake-victoria',
    title: 'Lake Victoria',
    description:
        'Africa\'s largest lake and source of the Nile — shared by Uganda, Kenya and Tanzania.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: -1.0,
    longitude: 33.0,
    claimRadius: 35000,
    claimPolygon: [
      [0.5, 31.7],
      [0.55, 34.2],
      [-0.5, 34.5],
      [-2.7, 33.5],
      [-3.0, 32.0],
      [-1.4, 31.5],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'africa'],
  ),
  Achievement(
    id: 'lake-tanganyika',
    title: 'Lake Tanganyika',
    description:
        'A 673 km ribbon of blue — the world\'s longest freshwater lake, running between four African nations.',
    tier: AchievementTier.silver,
    xpReward: 25,
    latitude: -6.0,
    longitude: 29.5,
    claimRadius: 25000,
    claimPolygon: [
      [-3.35, 29.2],
      [-3.30, 29.5],
      [-4.50, 29.7],
      [-6.50, 29.9],
      [-7.90, 30.7],
      [-8.80, 31.2],
      [-8.85, 30.8],
      [-7.40, 30.2],
      [-5.80, 29.3],
      [-4.20, 29.1],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'africa'],
  ),

  // ══════════════════════════════════════════════════
  // NORTH AMERICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'lake-superior',
    title: 'Lake Superior',
    description:
        'The largest of the Great Lakes by surface area — big enough to contain the other four combined.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: 47.7,
    longitude: -87.5,
    claimRadius: 40000,
    claimPolygon: [
      [48.95, -89.5],
      [48.75, -85.0],
      [47.05, -84.5],
      [46.50, -86.8],
      [46.55, -90.1],
      [47.35, -92.0],
      [48.10, -90.4],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'americas', 'great-lakes'],
  ),
  Achievement(
    id: 'lake-tahoe',
    title: 'Lake Tahoe',
    description:
        'Alpine-clear waters cradled by the Sierra Nevada on the California–Nevada border.',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 39.0968,
    longitude: -120.0324,
    claimRadius: 8000,
    claimPolygon: [
      [39.25, -120.10],
      [39.23, -119.93],
      [39.10, -119.92],
      [38.93, -119.98],
      [38.92, -120.08],
      [39.15, -120.14],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'americas', 'usa'],
  ),
  Achievement(
    id: 'lake-great-salt',
    title: 'Great Salt Lake',
    description:
        'The largest saltwater lake in the Western Hemisphere — a surreal pink-hued expanse in Utah.',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 41.1,
    longitude: -112.5,
    claimRadius: 25000,
    claimPolygon: [
      [41.75, -112.85],
      [41.70, -112.10],
      [41.15, -112.05],
      [40.75, -112.30],
      [40.80, -112.95],
      [41.30, -113.20],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'americas', 'usa'],
  ),
  Achievement(
    id: 'lake-crater',
    title: 'Crater Lake',
    description:
        'A near-perfect circle of deep blue filling the caldera of Mount Mazama in Oregon.',
    tier: AchievementTier.silver,
    xpReward: 25,
    latitude: 42.9446,
    longitude: -122.1090,
    claimRadius: 5000,
    claimPolygon: [
      [42.99, -122.14],
      [42.99, -122.07],
      [42.94, -122.05],
      [42.90, -122.08],
      [42.90, -122.15],
      [42.95, -122.17],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'americas', 'usa'],
  ),

  // ══════════════════════════════════════════════════
  // SOUTH AMERICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'lake-titicaca',
    title: 'Lake Titicaca',
    description:
        'The highest navigable lake on Earth at 3,812 m — sacred to the Inca, spanning Peru and Bolivia.',
    tier: AchievementTier.gold,
    xpReward: 40,
    latitude: -15.8,
    longitude: -69.3,
    claimRadius: 20000,
    claimPolygon: [
      [-15.15, -69.75],
      [-15.20, -68.95],
      [-15.95, -68.55],
      [-16.50, -68.75],
      [-16.40, -69.40],
      [-15.70, -69.85],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'south-america'],
  ),

  // ══════════════════════════════════════════════════
  // EUROPE
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'lake-geneva',
    title: 'Lake Geneva',
    description:
        'A crescent of alpine blue shared by Switzerland and France — Montreux jazz, Chillon Castle, vineyard terraces.',
    tier: AchievementTier.silver,
    xpReward: 25,
    latitude: 46.45,
    longitude: 6.5,
    claimRadius: 8000,
    claimPolygon: [
      [46.52, 6.15],
      [46.48, 6.85],
      [46.40, 6.90],
      [46.30, 6.60],
      [46.35, 6.20],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'europe'],
  ),
  Achievement(
    id: 'lake-como',
    title: 'Lake Como',
    description:
        'An inverted-Y of deep water framed by the Italian Alps — villas, cypresses, and vintage wooden boats.',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 46.0,
    longitude: 9.25,
    claimRadius: 5000,
    claimPolygon: [
      [46.17, 9.25],
      [46.07, 9.32],
      [45.98, 9.28],
      [45.86, 9.22],
      [45.90, 9.12],
      [46.00, 9.15],
      [46.10, 9.20],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'europe'],
  ),
  Achievement(
    id: 'lake-loch-ness',
    title: 'Loch Ness',
    description:
        'A 37 km trench of dark peaty water in the Scottish Highlands — famously rumored home of Nessie.',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 57.3,
    longitude: -4.4,
    claimRadius: 8000,
    claimPolygon: [
      [57.45, -4.38],
      [57.40, -4.30],
      [57.27, -4.42],
      [57.15, -4.55],
      [57.20, -4.60],
      [57.35, -4.45],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'europe'],
  ),

  // ══════════════════════════════════════════════════
  // OCEANIA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'lake-taupo',
    title: 'Lake Taupo',
    description:
        'New Zealand\'s largest lake — a vast caldera on the North Island formed by one of Earth\'s biggest eruptions.',
    tier: AchievementTier.silver,
    xpReward: 25,
    latitude: -38.8,
    longitude: 175.9,
    claimRadius: 12000,
    claimPolygon: [
      [-38.65, 175.75],
      [-38.60, 176.10],
      [-38.85, 176.15],
      [-39.00, 176.00],
      [-38.95, 175.75],
      [-38.75, 175.70],
    ],
    collectionId: 'lakes',
    tags: ['lake', 'oceania'],
  ),
];
