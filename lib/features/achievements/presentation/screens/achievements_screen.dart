import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/achievement_unlock_popup.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/widgets/achievement_detail_sheet.dart';

// Achievements screen widgets - split out of this file as `part` libraries to
// keep each section focused. They share this files imports and private scope.
part '../widgets/screen_parts/achievements_explore_tab.dart';
part '../widgets/screen_parts/achievements_collection_views.dart';
part '../widgets/screen_parts/achievements_timeline.dart';

// ══════════════════════════════════════════════════════════════
// Constants
// ══════════════════════════════════════════════════════════════

const _continentCollectionIds = {
  'europe', 'americas', 'africa', 'asia', 'south-america', 'oceania'
};
const _themedCollectionIds = {
  'national-parks', 'ski-resorts', 'capitals', 'ancient-sites',
  'holy-sites', 'seas', 'tourist-destinations'
};
const _localCollectionIds = {'landmarks', 'beaches', 'parks', 'culture'};

// Geographic difficulty tiers — each level in the cascade
enum _GeoTier { zone, country, continent, global }

Color _geoTierColor(_GeoTier tier) => switch (tier) {
  _GeoTier.zone => AppColors.bronze,
  _GeoTier.country => AppColors.silver,
  _GeoTier.continent => AppColors.gold,
  _GeoTier.global => AppColors.platinum,
};

String _geoTierLabel(_GeoTier tier) => switch (tier) {
  _GeoTier.zone => 'Zone',
  _GeoTier.country => 'Country',
  _GeoTier.continent => 'Continent',
  _GeoTier.global => 'Earth',
};

class _ContinentInfo {
  final String id;
  final String label;
  final String emoji;
  const _ContinentInfo(
      {required this.id, required this.label, required this.emoji});
}

const _continents = [
  _ContinentInfo(id: 'europe', label: 'Europe', emoji: '\u{1F30D}'),
  _ContinentInfo(id: 'asia', label: 'Asia', emoji: '\u{1F30F}'),
  _ContinentInfo(id: 'africa', label: 'Africa', emoji: '\u{1F30D}'),
  _ContinentInfo(id: 'americas', label: 'North America', emoji: '\u{1F30E}'),
  _ContinentInfo(
      id: 'south-america', label: 'South America', emoji: '\u{1F30E}'),
  _ContinentInfo(id: 'oceania', label: 'Oceania', emoji: '\u{1F30F}'),
];

/// Map continent id → adjectival form for section labels like "European Countries".
const _continentAdjective = <String, String>{
  'europe': 'European',
  'asia': 'Asian',
  'africa': 'African',
  'americas': 'North American',
  'south-america': 'South American',
  'oceania': 'Oceanian',
};

const _countryToContinent = <String, String>{
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
};

const _countryLabels = <String, String>{
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
};

const _themedLabels = <String, String>{
  'national-parks': 'All National Parks on Earth',
  'ski-resorts': 'All Ski Resorts on Earth',
  'capitals': 'All Capitals on Earth',
  'ancient-sites': 'All Ancient Sites on Earth',
  'holy-sites': 'All Holy Sites on Earth',
  'seas': 'All Seas on Earth',
  'tourist-destinations': 'All Destinations on Earth',
};

const _themedIcons = <String, IconData>{
  'national-parks': LucideIcons.trees,
  'ski-resorts': LucideIcons.snowflake,
  'capitals': LucideIcons.building2,
  'ancient-sites': LucideIcons.church,
  'holy-sites': LucideIcons.church,
  'seas': LucideIcons.waves,
  'tourist-destinations': LucideIcons.mapPin,
};

const _localLabels = <String, String>{
  'landmarks': 'Landmarks',
  'beaches': 'Beaches',
  'parks': 'Parks',
  'culture': 'Culture',
};

const _localIcons = <String, IconData>{
  'landmarks': LucideIcons.landmark,
  'beaches': LucideIcons.umbrella,
  'parks': LucideIcons.palmtree,
  'culture': LucideIcons.palette,
};

// ── Helpers ──

/// Derive continent for a themed-collection achievement via its tags.
String? _continentOfThemed(Achievement a) {
  for (final tag in a.tags) {
    if (_continentCollectionIds.contains(tag)) return tag;
    final mapped = _countryToContinent[tag];
    if (mapped != null) return mapped;
  }
  return null;
}

/// Extract the country tag from a themed-collection achievement.
String? _countryOf(Achievement a) {
  for (final tag in a.tags) {
    if (_countryToContinent.containsKey(tag)) return tag;
  }
  return null;
}

/// Unified country key for any achievement (works across collection types).
String? _countryKey(Achievement a) {
  // Countries collection: extract from ID  e.g. "europe-france" → "france"
  if (_continentCollectionIds.contains(a.collectionId)) {
    final prefix = '${a.collectionId}-';
    if (a.id.startsWith(prefix)) return a.id.substring(prefix.length);
    return null;
  }
  // Themed collection: extract from tags
  return _countryOf(a);
}

/// Unified continent key for any achievement.
String? _continentKey(Achievement a) {
  if (_continentCollectionIds.contains(a.collectionId)) {
    return a.collectionId;
  }
  return _continentOfThemed(a);
}

// ══════════════════════════════════════════════════════════════
// Main Screen
// ══════════════════════════════════════════════════════════════

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Text(
              l10n.navAchievements,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _AchievementsPendingClaims(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.bgCardLight.withValues(alpha: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ]),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                indicatorPadding: const EdgeInsets.all(2),
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.compass, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.navExplore),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.calendarClock, size: 16),
                        const SizedBox(width: 6),
                        Text(l10n.unlockTimeline),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ExploreTab(),
                _AchievementTimelineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
