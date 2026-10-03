import 'package:travel_buddy_mobile/shared/models/master_achievement.dart';

/// Israel master achievements: combos ("North to South", "Four Seas"),
/// regional milestones, Traveler-DNA milestones and list completions.
/// Each one gives the profile another distinctive data point.

// ── Helpers ──────────────────────────────────────────────────────────────────

const _mediterranean = 'il-gordon-beach,il-hilton-beach,il-metzitzim-beach,'
    'il-gaash-beach,il-dado-beach,il-dor-beach,il-dor-habonim,'
    'il-nahariya-beach,il-caesarea-aqueduct,il-palmachim-beach,il-achziv,'
    'il-old-jaffa,herzl-beach,poleg-beach,sironit-beach,blue-bay,tzofit-beach,'
    'haonot-beach,beit-yanai,mikhmoret-beach';
const _kinneret = 'il-tzemach-beach,il-majrase,il-yardenit,sea-galilee';
const _deadSea = 'il-dead-sea-float,il-einot-tzukim,sea-dead,lake-dead-sea';
const _redSea = 'il-coral-beach,il-princess-beach,il-north-beach-eilat,'
    'il-dolphin-reef,il-underwater-observatory';

// ── Registry ─────────────────────────────────────────────────────────────────

const israelMasterAchievements = <MasterAchievement>[
  // ══ Regions ══
  MasterAchievement(
    id: 'il-master-regions-5',
    title: 'Region Hopper',
    description: 'Visit places in 5 regions of Israel',
    icon: '🗺️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'The map is starting to fill in!',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.israelRegionCount,
        targetValue: 5,
        description: 'Visit 5 regions',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-regions-10',
    title: 'Across the Land',
    description: 'Visit places in 10 regions of Israel',
    icon: '🧭',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Most of the country is now yours.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.israelRegionCount,
        targetValue: 10,
        description: 'Visit 10 regions',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-regions-all',
    title: 'Every Corner of Israel',
    description: 'Visit places in all 17 regions',
    icon: '🇮🇱',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'From the Hermon to the Red Sea — you\'ve seen it all.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.israelRegionCount,
        targetValue: 17,
        description: 'Visit all 17 regions',
      ),
    ],
  ),

  // ══ Geographic combos ══
  MasterAchievement(
    id: 'il-master-north-to-south',
    title: 'From Metula to Eilat',
    description: 'Stand in the northernmost town and at the southern tip',
    icon: '↕️',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Top to bottom — the whole length of the country.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-metula,il-eilat',
        targetValue: 2,
        description: 'Visit Metula and Eilat',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-high-low',
    title: 'Highest & Lowest',
    description: 'Mount Hermon and the Dead Sea — 2,600 meters apart',
    icon: '📐',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'From the snow line to the lowest place on Earth.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-mount-hermon,il-dead-sea-float',
        targetValue: 2,
        description: 'Visit Mount Hermon and float in the Dead Sea',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-four-seas',
    title: 'Four Seas',
    description: 'The Mediterranean, the Kinneret, the Dead Sea and the Red Sea',
    icon: '🌊',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'Every sea of Israel has touched your feet.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: _mediterranean,
        targetValue: 1,
        description: 'A Mediterranean beach',
      ),
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: _kinneret,
        targetValue: 1,
        description: 'The Sea of Galilee',
      ),
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: _deadSea,
        targetValue: 1,
        description: 'The Dead Sea',
      ),
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: _redSea,
        targetValue: 1,
        description: 'The Red Sea',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-israel-trail',
    title: 'End to End',
    description: 'Both trailheads of the Israel National Trail',
    icon: '🥾',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Dan to Eilat — the trail is in your legs.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-israel-trail-north,il-israel-trail-south',
        targetValue: 2,
        description: 'Reach both trailheads',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-dawn-dusk',
    title: 'Dawn & Dusk',
    description: 'Sunrise on Masada and the stars over the Ramon Crater',
    icon: '🌅',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'You know the desert at both ends of the day.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-masada-sunrise,il-ramon-stargazing',
        targetValue: 2,
        description: 'Masada sunrise and Ramon stargazing',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-big-three',
    title: 'The Big Three',
    description: 'Jerusalem, Tel Aviv and Haifa',
    icon: '🏙️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'The holy, the bold and the beautiful.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-jerusalem,il-tel-aviv,il-haifa',
        targetValue: 3,
        description: 'Visit all three big cities',
      ),
    ],
  ),

  // ══ Themed trails ══
  MasterAchievement(
    id: 'il-master-incense-route',
    title: 'The Incense Route',
    description: 'All four Nabataean desert cities on the UNESCO route',
    icon: '🐫',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'You followed the caravans of frankincense and myrrh.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-avdat,il-mamshit,il-shivta,il-haluza',
        targetValue: 4,
        description: 'Avdat, Mamshit, Shivta and Haluza',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-biblical-tels',
    title: 'Biblical Tels',
    description: 'Megiddo, Hazor and Be\'er Sheva — the UNESCO trio',
    icon: '🏺',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Layer upon layer of ancient cities.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-megiddo,il-tel-hazor,il-tel-beer-sheva',
        targetValue: 3,
        description: 'All three biblical tels',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-craters',
    title: 'Three Craters',
    description: 'The Ramon, the Big and the Small craters',
    icon: '🕳️',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Israel\'s geological wonders are all yours.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-makhtesh-ramon,il-makhtesh-gadol,il-makhtesh-katan',
        targetValue: 3,
        description: 'All three makhteshim',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-crusader-castles',
    title: 'Crusader Castles',
    description: 'Five castles and fortresses of the Crusader era',
    icon: '🏰',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Knights, moats and ramparts — you\'ve stormed them all.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-nimrod-fortress,il-montfort,il-yehiam,il-belvoir,'
            'il-apollonia,il-acre-old-city,il-caesarea',
        targetValue: 5,
        description: 'Visit 5 Crusader castles',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-roman-israel',
    title: 'Roman Israel',
    description: 'Four great Roman-era cities',
    icon: '🏛️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Columns, theaters and mosaics — Rome was here.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-caesarea,il-beit-shean-park,il-tzippori,'
            'il-hamat-gader,il-caesarea-aqueduct,il-beit-guvrin',
        targetValue: 4,
        description: 'Visit 4 Roman-era sites',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-galilee-footsteps',
    title: 'Footsteps in the Galilee',
    description: 'Five sites of the Galilee pilgrimage',
    icon: '⛪',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'You walked the shores of the Gospels.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-capernaum,il-tabgha,il-mount-beatitudes,il-yardenit,'
            'il-basilica-annunciation,il-mount-tabor,il-magdala',
        targetValue: 5,
        description: 'Visit 5 Galilee pilgrimage sites',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-three-faiths',
    title: 'City of Three Faiths',
    description: 'The Western Wall, the Holy Sepulchre and Al-Aqsa',
    icon: '🕊️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Three faiths, one square kilometer.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'site-western-wall,holy-holy-sepulchre,holy-al-aqsa',
        targetValue: 3,
        description: 'Visit all three holy sites',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-waterfalls',
    title: 'Waterfall Chaser',
    description: 'Four of Israel\'s waterfalls',
    icon: '💦',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Rare water in a dry land — you found it.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-banias-waterfall,il-tanur-waterfall,il-saar-falls,'
            'il-nahal-david,il-gamla,il-yehudiya',
        targetValue: 4,
        description: 'Visit 4 waterfalls',
      ),
    ],
  ),

  // ══ Local legends ══
  MasterAchievement(
    id: 'il-master-golan-ranger',
    title: 'Golan Ranger',
    description: 'Five classics of the Golan Heights',
    icon: '🌋',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Basalt, vultures and snowmelt — the Golan knows you.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-mount-hermon,il-banias-springs,il-nimrod-fortress,'
            'il-gamla,il-yehudiya,il-mount-bental,il-meshushim',
        targetValue: 5,
        description: 'Visit 5 Golan classics',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-jerusalem-insider',
    title: 'Jerusalem Insider',
    description: 'Six landmarks of Jerusalem',
    icon: '🕍',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Jerusalem is no longer a stranger to you.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-israel-museum,il-yad-vashem,il-mahane-yehuda,'
            'il-tower-of-david,il-city-of-david,il-western-wall-tunnels,'
            'il-ramparts-walk,il-mount-of-olives,il-jerusalem-old-city',
        targetValue: 6,
        description: 'Visit 6 Jerusalem landmarks',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-tel-aviv-local',
    title: 'Tel Aviv Local',
    description: 'Six classics of Tel Aviv-Yafo',
    icon: '🌇',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'You live the city that never stops.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: 'il-carmel-market,il-old-jaffa,il-white-city,il-tlv-port,'
            'il-gordon-beach,il-tlv-museum-of-art,il-independence-hall,'
            'il-sarona,il-neve-tzedek',
        targetValue: 6,
        description: 'Visit 6 Tel Aviv classics',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-red-sea',
    title: 'Red Sea Diver',
    description: 'Three underwater worlds of Eilat',
    icon: '🐠',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Coral, dolphins and the deep blue.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.anyOfAchievements,
        targetId: _redSea,
        targetValue: 3,
        description: 'Visit 3 Red Sea spots',
      ),
    ],
  ),

  // ══ Traveler DNA milestones ══
  MasterAchievement(
    id: 'il-master-desert-soul',
    title: 'Desert Soul',
    description: 'Visit 10 desert places',
    icon: '🏜️',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'The silence of the desert calls you home.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'il-facet:desert',
        targetValue: 10,
        description: 'Visit 10 desert places',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-time-traveler',
    title: 'Keeper of History',
    description: 'Visit 25 historical places',
    icon: '📜',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Five thousand years, one traveler.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'il-facet:history',
        targetValue: 25,
        description: 'Visit 25 historical places',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-pilgrim',
    title: 'Pilgrim',
    description: 'Visit 10 places of faith',
    icon: '🙏',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'A path walked by millions before you.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'il-facet:faith',
        targetValue: 10,
        description: 'Visit 10 places of faith',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-flavor-hunter',
    title: 'Taste of Israel',
    description: 'Visit 8 markets, wineries and food spots',
    icon: '🥙',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Hummus, wine and za\'atar — you tasted the land.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'il-facet:food',
        targetValue: 8,
        description: 'Visit 8 food places',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-thrill-seeker',
    title: 'Adrenaline Junkie',
    description: 'Visit 10 adventure places',
    icon: '🧗',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Canyons, caves and cliffs — bring on the next one.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'il-facet:adventure',
        targetValue: 10,
        description: 'Visit 10 adventure places',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-water-soul',
    title: 'Spring Chaser',
    description: 'Visit 10 springs, streams and water places',
    icon: '💧',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'You always know where the water is.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'il-facet:water',
        targetValue: 10,
        description: 'Visit 10 water places',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-horizon-hunter',
    title: 'Horizon Hunter',
    description: 'Visit 12 viewpoints and peaks',
    icon: '🔭',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Always looking for the next view.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'il-facet:views',
        targetValue: 12,
        description: 'Visit 12 viewpoints',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-wild-tracker',
    title: 'Wild Tracker',
    description: 'Visit 6 wildlife places',
    icon: '🦅',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Cranes, ibex and vultures — you found them all.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'il-facet:wildlife',
        targetValue: 6,
        description: 'Visit 6 wildlife places',
      ),
    ],
  ),

  // ══ List milestones & completions ══
  MasterAchievement(
    id: 'il-master-city-hopper',
    title: 'City Hopper',
    description: 'Visit 20 cities and towns',
    icon: '🏘️',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Twenty cities, twenty personalities.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.collectionProgress,
        targetId: 'il-cities',
        targetValue: 20,
        description: 'Visit 20 cities',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-unesco',
    title: 'World Heritage Collector',
    description: 'Visit every UNESCO World Heritage site in the list',
    icon: '🏛️',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Every World Heritage site in Israel — collected.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'il-unesco',
        targetValue: 1,
        description: 'Complete the UNESCO list',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-park-ranger',
    title: 'Park Ranger',
    description: 'Visit 15 national parks',
    icon: '🏞️',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'Your parks card is well worn.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.collectionProgress,
        targetId: 'il-national-parks',
        targetValue: 15,
        description: 'Visit 15 national parks',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-experiences',
    title: 'Bucket List: Israel',
    description: 'Complete every iconic experience',
    icon: '⭐',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'Floating, diving, climbing, stargazing — you did it all.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.completeCollection,
        targetId: 'il-experiences',
        targetValue: 1,
        description: 'Complete the Iconic Experiences list',
      ),
    ],
  ),

  // ══ Overall milestones ══
  MasterAchievement(
    id: 'il-master-places-25',
    title: 'Israel Explorer',
    description: 'Visit 25 places in Israel',
    icon: '🧭',
    tier: MasterTier.elite,
    xpReward: 100,
    unlockMessage: 'Twenty-five places in — and just getting started.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'israel',
        targetValue: 25,
        description: 'Visit 25 places',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-places-100',
    title: 'Israel Expert',
    description: 'Visit 100 places in Israel',
    icon: '🏅',
    tier: MasterTier.legendary,
    xpReward: 200,
    unlockMessage: 'A hundred places. You could give the tour.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'israel',
        targetValue: 100,
        description: 'Visit 100 places',
      ),
    ],
  ),
  MasterAchievement(
    id: 'il-master-places-250',
    title: 'Legend of the Land',
    description: 'Visit 250 places in Israel',
    icon: '👑',
    tier: MasterTier.mythic,
    xpReward: 500,
    unlockMessage: 'Few people know Israel like you do.',
    requirements: [
      MasterRequirement(
        type: MasterRequirementType.tagCount,
        targetId: 'israel',
        targetValue: 250,
        description: 'Visit 250 places',
      ),
    ],
  ),
];

/// Hebrew titles and descriptions for the Israel masters.
const israelMasterHebrew = <String, (String title, String description)>{
  'il-master-regions-5': ('קופץ/ת אזורים', 'בקרו ב-5 אזורים בארץ'),
  'il-master-regions-10': ('לאורכה ולרוחבה', 'בקרו ב-10 אזורים בארץ'),
  'il-master-regions-all': ('בכל פינה בארץ', 'בקרו בכל 17 האזורים'),
  'il-master-north-to-south': ('ממטולה עד אילת', 'עמדו ביישוב הצפוני ביותר ובקצה הדרומי'),
  'il-master-high-low': ('הכי גבוה, הכי נמוך', 'החרמון וים המלח — 2,600 מטר הפרש'),
  'il-master-four-seas': ('ארבעה ימים', 'הים התיכון, הכנרת, ים המלח וים סוף'),
  'il-master-israel-trail': ('מקצה לקצה', 'שתי נקודות הקצה של שביל ישראל'),
  'il-master-dawn-dusk': ('זריחה ושקיעה', 'זריחה על מצדה וכוכבים מעל מכתש רמון'),
  'il-master-big-three': ('שלוש הגדולות', 'ירושלים, תל אביב וחיפה'),
  'il-master-incense-route': ('דרך הבשמים', 'כל ארבע ערי המדבר הנבטיות'),
  'il-master-biblical-tels': ('התלים המקראיים', 'מגידו, חצור ובאר שבע'),
  'il-master-craters': ('שלושה מכתשים', 'מכתש רמון, הגדול והקטן'),
  'il-master-crusader-castles': ('מבצרי הצלבנים', 'חמישה מבצרים מתקופת הצלבנים'),
  'il-master-roman-israel': ('ישראל הרומית', 'ארבעה אתרים מהתקופה הרומית'),
  'il-master-galilee-footsteps': ('בעקבות הבשורה בגליל', 'חמישה אתרי עלייה לרגל בגליל'),
  'il-master-three-faiths': ('עיר שלוש הדתות', 'הכותל, כנסיית הקבר ואל-אקצא'),
  'il-master-waterfalls': ('צייד/ת מפלים', 'ארבעה מפלים בארץ'),
  'il-master-golan-ranger': ('סייר/ת הגולן', 'חמש קלאסיקות של רמת הגולן'),
  'il-master-jerusalem-insider': ('ירושלמי/ת מבפנים', 'שישה ציוני דרך בירושלים'),
  'il-master-tel-aviv-local': ('תל אביבי/ת', 'שש קלאסיקות של תל אביב-יפו'),
  'il-master-red-sea': ('צולל/ת ים סוף', 'שלושה עולמות תת-ימיים באילת'),
  'il-master-desert-soul': ('נשמה מדברית', 'בקרו ב-10 מקומות במדבר'),
  'il-master-time-traveler': ('שומר/ת ההיסטוריה', 'בקרו ב-25 אתרים היסטוריים'),
  'il-master-pilgrim': ('עולה רגל', 'בקרו ב-10 מקומות קדושים'),
  'il-master-flavor-hunter': ('טעם של ארץ', 'בקרו ב-8 שווקים, יקבים ומקומות אוכל'),
  'il-master-thrill-seeker': ('מכור/ה לאדרנלין', 'בקרו ב-10 מקומות הרפתקה'),
  'il-master-water-soul': ('צייד/ת מעיינות', 'בקרו ב-10 מעיינות, נחלים ומקומות מים'),
  'il-master-horizon-hunter': ('צייד/ת אופקים', 'בקרו ב-12 תצפיות ופסגות'),
  'il-master-wild-tracker': ('גשש/ית חיות בר', 'בקרו ב-6 מקומות של חיות בר'),
  'il-master-city-hopper': ('קופץ/ת ערים', 'בקרו ב-20 ערים ועיירות'),
  'il-master-unesco': ('אספן/ית מורשת עולמית', 'כל אתרי מורשת אונסק"ו ברשימה'),
  'il-master-park-ranger': ('פקח/ית גנים', 'בקרו ב-15 גנים לאומיים'),
  'il-master-experiences': ('רשימת החלומות: ישראל', 'השלימו את כל החוויות האיקוניות'),
  'il-master-places-25': ('מגלה הארץ', 'בקרו ב-25 מקומות בארץ'),
  'il-master-places-100': ('מומחה/ית לארץ', 'בקרו ב-100 מקומות בארץ'),
  'il-master-places-250': ('אגדת הארץ', 'בקרו ב-250 מקומות בארץ'),
};
