import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// Iconic deserts of the world — sand seas, salt flats and arid plateaus.
///
/// Polygons are coarse hand-authored approximations of each desert's
/// footprint (5-10 vertices). They are accurate enough for in-polygon
/// proximity checks but will look blocky on the map. Swap for Natural
/// Earth or biome-database polygons later for finer shapes.
const desertsAchievementRegistry = <Achievement>[
  // ══════════════════════════════════════════════════
  // AFRICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'desert-sahara',
    title: 'Sahara',
    description:
        'Cross the world\'s largest hot desert — a 9-million km² sea of dunes spanning eleven countries from the Atlantic to the Red Sea.',
    tier: AchievementTier.platinum,
    xpReward: 60,
    latitude: 24.0,
    longitude: 12.0,
    claimRadius: 200000,
    claimPolygon: [
      [33.0, -10.0],
      [33.0, 10.0],
      [32.0, 22.0],
      [30.0, 32.0],
      [22.0, 36.0],
      [16.0, 30.0],
      [15.0, 18.0],
      [16.0, 5.0],
      [18.0, -5.0],
      [21.0, -13.0],
      [27.0, -13.0],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'africa', 'sahara'],
  ),
  Achievement(
    id: 'desert-namib',
    title: 'Namib (Sossusvlei)',
    description:
        'Walk the world\'s oldest desert and climb the towering red dunes of Sossusvlei on the Namibian coast.',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: -24.7,
    longitude: 15.3,
    claimRadius: 60000,
    claimPolygon: [
      [-18.0, 12.0],
      [-19.0, 14.5],
      [-22.5, 15.5],
      [-26.0, 16.0],
      [-29.0, 17.0],
      [-29.0, 14.5],
      [-25.0, 13.5],
      [-21.0, 13.0],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'africa', 'namibia'],
  ),
  Achievement(
    id: 'desert-kalahari',
    title: 'Kalahari',
    description:
        'Track wildlife across the red sands of the Kalahari spanning Botswana, Namibia and South Africa.',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: -23.0,
    longitude: 22.0,
    claimRadius: 200000,
    claimPolygon: [
      [-19.0, 19.0],
      [-19.5, 22.0],
      [-20.0, 26.0],
      [-23.0, 26.5],
      [-27.0, 25.0],
      [-29.0, 23.0],
      [-28.5, 20.5],
      [-25.0, 19.0],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'africa', 'botswana', 'namibia', 'south-africa'],
  ),

  // ══════════════════════════════════════════════════
  // ASIA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'desert-gobi',
    title: 'Gobi',
    description:
        'Trek the high-altitude rain-shadow desert of Mongolia and northern China — home of dinosaur fossils and snow leopards.',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: 42.5,
    longitude: 105.0,
    claimRadius: 200000,
    claimPolygon: [
      [47.0, 95.0],
      [46.5, 105.0],
      [45.5, 113.0],
      [42.0, 115.0],
      [38.5, 110.0],
      [38.0, 100.0],
      [40.0, 95.0],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'asia', 'mongolia', 'china'],
  ),
  Achievement(
    id: 'desert-taklamakan',
    title: 'Taklamakan',
    description:
        'Cross the "Sea of Death" — a vast sand sea ringed by the Tian Shan, Kunlun and Pamir mountains in Xinjiang.',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: 39.0,
    longitude: 83.0,
    claimRadius: 150000,
    claimPolygon: [
      [40.5, 76.5],
      [41.0, 82.0],
      [40.5, 87.0],
      [39.0, 89.0],
      [37.0, 86.0],
      [37.0, 79.0],
      [39.0, 76.0],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'asia', 'china'],
  ),
  Achievement(
    id: 'desert-wadi-rum',
    title: 'Wadi Rum',
    description:
        'Camp under the stars among the towering sandstone monoliths of the Valley of the Moon in southern Jordan.',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 29.5765,
    longitude: 35.4206,
    claimRadius: 25000,
    claimPolygon: [
      [29.75, 35.30],
      [29.75, 35.60],
      [29.40, 35.65],
      [29.30, 35.55],
      [29.30, 35.30],
      [29.50, 35.25],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'asia', 'jordan'],
  ),
  Achievement(
    id: 'desert-negev',
    title: 'Negev',
    description:
        'Hike the makhtesh craters and ancient Nabatean spice route across Israel\'s southern desert.',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 30.6,
    longitude: 34.85,
    claimRadius: 60000,
    claimPolygon: [
      [31.40, 34.40],
      [31.40, 35.40],
      [30.50, 35.40],
      [29.50, 35.00],
      [29.50, 34.55],
      [30.80, 34.30],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'asia', 'israel'],
  ),

  // ══════════════════════════════════════════════════
  // NORTH AMERICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'desert-death-valley',
    title: 'Death Valley',
    description:
        'Stand at Badwater Basin — the lowest, hottest, driest place in North America in California\'s Mojave.',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: 36.5054,
    longitude: -117.0794,
    claimRadius: 60000,
    claimPolygon: [
      [37.20, -117.55],
      [37.20, -116.55],
      [36.20, -116.30],
      [35.70, -116.55],
      [35.70, -117.55],
      [36.50, -117.65],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'americas', 'usa', 'california'],
  ),
  Achievement(
    id: 'desert-white-sands',
    title: 'White Sands',
    description:
        'Walk the world\'s largest gypsum dune field — 700 km² of brilliant white sand in New Mexico.',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.7872,
    longitude: -106.3257,
    claimRadius: 30000,
    claimPolygon: [
      [33.10, -106.55],
      [33.10, -106.10],
      [32.55, -106.05],
      [32.45, -106.30],
      [32.55, -106.55],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'americas', 'usa', 'new-mexico'],
  ),

  // ══════════════════════════════════════════════════
  // SOUTH AMERICA
  // ══════════════════════════════════════════════════
  Achievement(
    id: 'desert-atacama',
    title: 'Atacama',
    description:
        'Stand on the driest non-polar desert on Earth — a Mars-like high plateau between the Andes and the Pacific.',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: -24.5,
    longitude: -69.5,
    claimRadius: 150000,
    claimPolygon: [
      [-18.0, -70.4],
      [-19.5, -68.5],
      [-22.5, -67.5],
      [-26.0, -68.0],
      [-30.0, -69.5],
      [-30.0, -71.2],
      [-26.0, -71.0],
      [-20.0, -71.0],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'south-america', 'chile'],
  ),
  Achievement(
    id: 'desert-uyuni',
    title: 'Uyuni Salt Flats',
    description:
        'Stand on the world\'s largest salt flat — 10,500 km² of mirror-perfect crust in Bolivia\'s southern Altiplano.',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: -20.13,
    longitude: -67.5,
    claimRadius: 80000,
    claimPolygon: [
      [-19.50, -68.30],
      [-19.60, -67.05],
      [-20.30, -66.80],
      [-20.85, -67.10],
      [-20.80, -67.95],
      [-20.30, -68.30],
    ],
    collectionId: 'deserts',
    tags: ['desert', 'south-america', 'bolivia', 'salt-flat'],
  ),
];
