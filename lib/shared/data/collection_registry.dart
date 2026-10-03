class CollectionInfo {
  final String id;
  final String name;
  final String icon;
  final int bonusXp;

  const CollectionInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.bonusXp,
  });
}

const collectionRegistry = <CollectionInfo>[
  CollectionInfo(id: 'beaches', name: 'Beaches', icon: '🏖️', bonusXp: 75),
  CollectionInfo(id: 'landmarks', name: 'Landmarks', icon: '🏛️', bonusXp: 100),
  CollectionInfo(id: 'parks', name: 'Parks', icon: '🌳', bonusXp: 100),
  CollectionInfo(id: 'culture', name: 'Culture', icon: '🎭', bonusXp: 75),
  CollectionInfo(id: 'europe', name: 'European Countries', icon: '🇪🇺', bonusXp: 150),
  CollectionInfo(id: 'americas', name: 'American Destinations', icon: '🗽', bonusXp: 150),
  CollectionInfo(id: 'national-parks', name: 'National Parks', icon: '🌲', bonusXp: 200),
  CollectionInfo(id: 'ski-resorts', name: 'Ski Resorts', icon: '⛷️', bonusXp: 150),
  CollectionInfo(id: 'capitals', name: 'World Capitals', icon: '🏛️', bonusXp: 200),
  CollectionInfo(id: 'ancient-sites', name: 'Ancient Religious Sites', icon: '🕌', bonusXp: 250),
  CollectionInfo(id: 'holy-sites', name: 'Holy Sites', icon: '🛐', bonusXp: 300),
  CollectionInfo(id: 'tourist-destinations', name: 'Popular Tourist Destinations', icon: '🌍', bonusXp: 200),
  CollectionInfo(id: 'africa', name: 'African Countries', icon: '🌍', bonusXp: 150),
  CollectionInfo(id: 'asia', name: 'Asian Countries', icon: '🌏', bonusXp: 150),
  CollectionInfo(id: 'south-america', name: 'South American Countries', icon: '🌎', bonusXp: 150),
  CollectionInfo(id: 'oceania', name: 'Oceania', icon: '🏝️', bonusXp: 150),
  CollectionInfo(id: 'continents', name: 'Continents', icon: '🌐', bonusXp: 300),
  CollectionInfo(id: 'lakes', name: 'Famous Lakes', icon: '🏞️', bonusXp: 150),
  CollectionInfo(id: 'seas', name: 'Seas of the World', icon: '🌊', bonusXp: 200),
  CollectionInfo(id: 'mountains', name: 'Iconic Mountains', icon: '🏔️', bonusXp: 200),
  CollectionInfo(id: 'volcanoes', name: 'Volcanoes', icon: '🌋', bonusXp: 250),
  CollectionInfo(id: 'waterfalls', name: 'Waterfalls', icon: '💦', bonusXp: 200),
  CollectionInfo(id: 'world-wonders', name: 'World Wonders', icon: '🗿', bonusXp: 350),
  CollectionInfo(id: 'glaciers', name: 'Glaciers & Ice', icon: '🧊', bonusXp: 200),
  CollectionInfo(id: 'deserts', name: 'Deserts', icon: '🏜️', bonusXp: 250),
  CollectionInfo(id: 'zones', name: 'Zones', icon: '📍', bonusXp: 50),
];

CollectionInfo? getCollectionInfo(String id) {
  try {
    return collectionRegistry.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
