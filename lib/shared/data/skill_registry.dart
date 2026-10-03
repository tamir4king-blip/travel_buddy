import 'package:travel_buddy_mobile/shared/models/skill_group.dart';

/// Expanded skill registry - 44 skill groups from Travel Trophies
/// Categories: outdoor, water, extreme, sports, food, culture, social, urban, travel, crafts, mind, lifestyle, wellness
const skillRegistry = <SkillGroup>[
  // === OUTDOOR & NATURE ===
  SkillGroup(
    id: 'hiker', name: 'Hiker', icon: '🥾',
    description: 'Trail master',
    categories: ['hiking'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#16a34a', gradientEnd: '#10b981',
    latitude: 46.948, longitude: 7.448,
  ),
  SkillGroup(
    id: 'camper', name: 'Camper', icon: '⛺',
    description: 'Outdoor survivor',
    categories: ['camping'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#d97706', gradientEnd: '#f97316',
    latitude: 37.748, longitude: -119.588,
  ),
  SkillGroup(
    id: 'angler', name: 'Angler', icon: '🎣',
    description: 'Master fisher',
    categories: ['fishing'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#2563eb', gradientEnd: '#06b6d4',
    latitude: 60.391, longitude: 5.322,
  ),
  SkillGroup(
    id: 'naturalist', name: 'Naturalist', icon: '🦋',
    description: 'Wildlife whisperer',
    categories: ['wildlife'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#84cc16', gradientEnd: '#22c55e',
    latitude: 10.280, longitude: -83.850,
  ),
  SkillGroup(
    id: 'stargazer', name: 'Stargazer', icon: '🔭',
    description: 'Cosmic explorer',
    categories: ['adventure'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#1e1b4b', gradientEnd: '#312e81',
    latitude: -23.262, longitude: -67.750,
  ),
  SkillGroup(
    id: 'gardener', name: 'Gardener', icon: '🌱',
    description: 'Life grower',
    categories: ['wellness'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#15803d', gradientEnd: '#4ade80',
    latitude: 52.269, longitude: 4.547,
  ),

  // === WATER SPORTS ===
  SkillGroup(
    id: 'diver', name: 'Diver', icon: '🤿',
    description: 'Deep explorer',
    categories: ['water-sports'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#0891b2', gradientEnd: '#2563eb',
    latitude: -16.280, longitude: 145.790,
  ),
  SkillGroup(
    id: 'surfer', name: 'Surfer', icon: '🏄',
    description: 'Wave rider',
    categories: ['water-sports'],
    maxLevel: 50, xpPerLevel: 550,
    gradientStart: '#14b8a6', gradientEnd: '#22d3ee',
    latitude: 38.722, longitude: -9.139,
  ),
  SkillGroup(
    id: 'sailor', name: 'Sailor', icon: '⛵',
    description: 'Sea captain',
    categories: ['water-sports'],
    maxLevel: 50, xpPerLevel: 550,
    gradientStart: '#3b82f6', gradientEnd: '#6366f1',
    latitude: 36.393, longitude: 25.461,
  ),
  SkillGroup(
    id: 'kayaker', name: 'Kayaker', icon: '🚣',
    description: 'River rider',
    categories: ['water-sports'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#0284c7', gradientEnd: '#0ea5e9',
    latitude: -44.672, longitude: 167.926,
  ),
  SkillGroup(
    id: 'swimmer', name: 'Swimmer', icon: '🏊',
    description: 'Human fish',
    categories: ['water-sports', 'wellness'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#06b6d4', gradientEnd: '#22d3ee',
    latitude: -33.891, longitude: 151.275,
  ),

  // === EXTREME & ADRENALINE ===
  SkillGroup(
    id: 'skydiver', name: 'Skydiver', icon: '🪂',
    description: 'Freefall master',
    categories: ['extreme'],
    maxLevel: 50, xpPerLevel: 700,
    gradientStart: '#7c3aed', gradientEnd: '#d946ef',
    latitude: 25.197, longitude: 55.274,
  ),
  SkillGroup(
    id: 'climber', name: 'Climber', icon: '🧗',
    description: 'Vertical warrior',
    categories: ['extreme'],
    maxLevel: 50, xpPerLevel: 650,
    gradientStart: '#57534e', gradientEnd: '#d97706',
    latitude: 45.924, longitude: 6.870,
  ),
  SkillGroup(
    id: 'skier', name: 'Skier', icon: '⛷️',
    description: 'Mountain shredder',
    categories: ['skiing'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#0ea5e9', gradientEnd: '#6366f1',
    latitude: 46.020, longitude: 7.749,
  ),
  SkillGroup(
    id: 'snowboarder', name: 'Snowboarder', icon: '🏂',
    description: 'Snow shredder',
    categories: ['skiing', 'extreme'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#6366f1', gradientEnd: '#8b5cf6',
    latitude: 50.116, longitude: -122.957,
  ),
  SkillGroup(
    id: 'paraglider', name: 'Paraglider', icon: '🪂',
    description: 'Wind rider',
    categories: ['extreme'],
    maxLevel: 50, xpPerLevel: 650,
    gradientStart: '#f97316', gradientEnd: '#eab308',
    latitude: 46.686, longitude: 7.863,
  ),

  // === SPORTS & FITNESS ===
  SkillGroup(
    id: 'runner', name: 'Runner', icon: '🏃',
    description: 'Speed demon',
    categories: ['wellness'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#ef4444', gradientEnd: '#f97316',
    latitude: 52.515, longitude: 13.377,
  ),
  SkillGroup(
    id: 'biker', name: 'Cyclist', icon: '🚴',
    description: 'Road warrior',
    categories: ['transportation'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#eab308', gradientEnd: '#f59e0b',
    latitude: 52.370, longitude: 4.895,
  ),
  SkillGroup(
    id: 'yogi', name: 'Yogi', icon: '🧘',
    description: 'Inner peace',
    categories: ['wellness'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#a78bfa', gradientEnd: '#a855f7',
    latitude: 30.086, longitude: 78.268,
  ),
  SkillGroup(
    id: 'martial', name: 'Martial Artist', icon: '🥋',
    description: 'Warrior path',
    categories: ['wellness', 'extreme'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#1f2937', gradientEnd: '#4b5563',
    latitude: 35.690, longitude: 139.692,
  ),

  // === FOOD & DRINK ===
  SkillGroup(
    id: 'chef', name: 'Chef', icon: '👨‍🍳',
    description: 'Kitchen master',
    categories: ['cooking'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#f97316', gradientEnd: '#ef4444',
    latitude: 41.903, longitude: 12.496,
  ),
  SkillGroup(
    id: 'baker', name: 'Baker', icon: '🥐',
    description: 'Dough artist',
    categories: ['cooking'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#d97706', gradientEnd: '#fbbf24',
    latitude: 48.861, longitude: 2.347,
  ),
  SkillGroup(
    id: 'grillmaster', name: 'Grill Master', icon: '🔥',
    description: 'Fire lord',
    categories: ['cooking'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#dc2626', gradientEnd: '#f97316',
    latitude: 30.267, longitude: -97.743,
  ),
  SkillGroup(
    id: 'sommelier', name: 'Sommelier', icon: '🍷',
    description: 'Wine expert',
    categories: ['food-drink'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#be123c', gradientEnd: '#9333ea',
    latitude: 44.838, longitude: -0.579,
  ),
  SkillGroup(
    id: 'barista', name: 'Barista', icon: '☕',
    description: 'Coffee artist',
    categories: ['food-drink'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#92400e', gradientEnd: '#c2410c',
    latitude: -37.814, longitude: 144.963,
  ),
  SkillGroup(
    id: 'mixologist', name: 'Mixologist', icon: '🍸',
    description: 'Cocktail wizard',
    categories: ['food-drink', 'nightlife'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#7c3aed', gradientEnd: '#c026d3',
    latitude: 23.137, longitude: -82.359,
  ),
  SkillGroup(
    id: 'foodie', name: 'Foodie', icon: '🍜',
    description: 'World taster',
    categories: ['food-drink'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#ea580c', gradientEnd: '#dc2626',
    latitude: 13.756, longitude: 100.502,
  ),

  // === CULTURE & ARTS ===
  SkillGroup(
    id: 'historian', name: 'Historian', icon: '🏛️',
    description: 'Past keeper',
    categories: ['cultural'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#b45309', gradientEnd: '#ca8a04',
    latitude: 37.984, longitude: 23.728,
  ),
  SkillGroup(
    id: 'artist', name: 'Artist', icon: '🎨',
    description: 'Creative soul',
    categories: ['cultural'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#ec4899', gradientEnd: '#a855f7',
    latitude: 43.768, longitude: 11.252,
  ),
  SkillGroup(
    id: 'musician', name: 'Musician', icon: '🎸',
    description: 'Sound master',
    categories: ['cultural'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#9333ea', gradientEnd: '#4f46e5',
    latitude: 36.163, longitude: -86.781,
  ),
  SkillGroup(
    id: 'linguist', name: 'Linguist', icon: '🗣️',
    description: 'Polyglot',
    categories: ['cultural'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#0369a1', gradientEnd: '#0891b2',
    latitude: 46.204, longitude: 6.143,
  ),

  // === SOCIAL & NIGHTLIFE ===
  SkillGroup(
    id: 'partygoer', name: 'Party Animal', icon: '🎉',
    description: 'Life of party',
    categories: ['nightlife'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#d946ef', gradientEnd: '#ec4899',
    latitude: 38.909, longitude: 1.432,
  ),
  SkillGroup(
    id: 'dancer', name: 'Dancer', icon: '💃',
    description: 'Dance floor king',
    categories: ['nightlife'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#f43f5e', gradientEnd: '#db2777',
    latitude: -34.604, longitude: -58.382,
  ),
  SkillGroup(
    id: 'socialite', name: 'Socialite', icon: '🤝',
    description: 'People person',
    categories: ['social'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#10b981', gradientEnd: '#14b8a6',
    latitude: 40.758, longitude: -73.986,
  ),
  SkillGroup(
    id: 'volunteer', name: 'Volunteer', icon: '💚',
    description: 'Community giver',
    categories: ['social'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#16a34a', gradientEnd: '#22c55e',
    latitude: -1.292, longitude: 36.821,
  ),

  // === URBAN & PHOTOGRAPHY ===
  SkillGroup(
    id: 'photographer', name: 'Photographer', icon: '📸',
    description: 'Moment catcher',
    categories: ['photography'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#374151', gradientEnd: '#475569',
    latitude: 48.857, longitude: 2.352,
  ),
  SkillGroup(
    id: 'explorer', name: 'Explorer', icon: '🧭',
    description: 'Urban navigator',
    categories: ['urban'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#475569', gradientEnd: '#71717a',
    latitude: 31.631, longitude: -7.989,
  ),
  SkillGroup(
    id: 'shopper', name: 'Shopper', icon: '🛍️',
    description: 'Deal hunter',
    categories: ['shopping'],
    maxLevel: 50, xpPerLevel: 300,
    gradientStart: '#ec4899', gradientEnd: '#fb7185',
    latitude: 45.464, longitude: 9.190,
  ),

  // === TRAVEL & FREEDOM ===
  SkillGroup(
    id: 'nomad', name: 'Digital Nomad', icon: '💻',
    description: 'Work anywhere',
    categories: ['urban', 'adventure'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#3b82f6', gradientEnd: '#8b5cf6',
    latitude: -8.410, longitude: 115.189,
  ),
  SkillGroup(
    id: 'backpacker', name: 'Backpacker', icon: '🎒',
    description: 'Free traveler',
    categories: ['adventure'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#059669', gradientEnd: '#10b981',
    latitude: 27.717, longitude: 85.324,
  ),
  SkillGroup(
    id: 'roadtripper', name: 'Road Tripper', icon: '🚗',
    description: 'Road nomad',
    categories: ['transportation', 'adventure'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#f59e0b', gradientEnd: '#ef4444',
    latitude: 34.052, longitude: -118.244,
  ),
  SkillGroup(
    id: 'pilot', name: 'Aviator', icon: '✈️',
    description: 'Sky master',
    categories: ['transportation'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#0284c7', gradientEnd: '#1d4ed8',
    latitude: 36.019, longitude: -75.668,
  ),

  // === UNIQUE EXPERIENCES ===
  SkillGroup(
    id: 'festival', name: 'Festival Goer', icon: '🎪',
    description: 'Life celebrator',
    categories: ['nightlife', 'social', 'cultural'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#c026d3', gradientEnd: '#e879f9',
    latitude: -22.906, longitude: -43.173,
  ),
  SkillGroup(
    id: 'sunset', name: 'Sunset Chaser', icon: '🌅',
    description: 'Moment lover',
    categories: ['photography'],
    maxLevel: 50, xpPerLevel: 300,
    gradientStart: '#f97316', gradientEnd: '#fb923c',
    latitude: 36.462, longitude: 25.376,
  ),
  SkillGroup(
    id: 'aurora', name: 'Aurora Hunter', icon: '🌌',
    description: 'Light seeker',
    categories: ['adventure', 'photography'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#4f46e5', gradientEnd: '#22c55e',
    latitude: 69.649, longitude: 18.956,
  ),
];

/// Get a skill group by ID
SkillGroup? getSkillById(String id) {
  try {
    return skillRegistry.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}

/// Get skill groups by category
List<SkillGroup> getSkillsByCategory(String category) {
  return skillRegistry.where((s) => s.categories.contains(category)).toList();
}
