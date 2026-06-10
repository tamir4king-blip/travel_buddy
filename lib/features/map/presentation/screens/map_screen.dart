import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/widgets/achievement_detail_sheet.dart';
import 'package:travel_buddy_mobile/features/map/models/map_marker_item.dart';
import 'package:travel_buddy_mobile/features/map/presentation/map_view.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/achievement_marker.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/area_colors.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/map_filter_tab_bar.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/filter_sheets/bubble_quick_filters.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/filter_sheets/unified_filter_sheet.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/map_pin_popup.dart';
import 'package:travel_buddy_mobile/features/map/providers/current_country_provider.dart';
import 'package:travel_buddy_mobile/features/map/services/local_zone_registry.dart';
import 'package:travel_buddy_mobile/features/map/services/zone_boundary_service.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_camera_provider.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quest_chain_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/skills_provider.dart';
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';

// Map screen widgets — split out of this file as `part` libraries to keep each
// group focused. They share this file's imports and private scope.
part '../widgets/screen_parts/map_controls.dart';
part '../widgets/screen_parts/map_zone_settings.dart';
part '../widgets/screen_parts/map_country_picker.dart';
part '../widgets/screen_parts/map_sheet_widgets.dart';

const _mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

/// Mapbox only ships Android/iOS implementations — on desktop dev runs the
/// native view can never initialize, so we render a static placeholder.
bool get _isNativeMapSupported =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late final PlatformMapController _mapController;
  bool _mapInitialized = false;
  bool _didInitialFly = false;

  // Keeps the native map view alive when the tree switches between the
  // full map experience and the bare home-backdrop canvas.
  final GlobalKey _mapViewKey = GlobalKey();

  // Cached provider references — captured early so dispose() never touches ref
  late final StateController<CachedCameraState?> _cameraStateNotifier;

  // Memoized marker list to avoid redundant setMarkers calls
  List<MapMarkerItem>? _lastMarkers;
  double? _lastUserLat;
  double? _lastUserLng;

  // Memoized per-collection overlay state so we don't re-render every frame.
  String? _lastUnlockedAreasSignature;

  // Zone-hover highlight: the admin boundary under the map center follows
  // the camera (debounced), with the admin level tied to the zoom. The
  // resolved zone name shows in a pill at the top of the screen.
  final ZoneBoundaryService _zoneBoundaryService = ZoneBoundaryService();
  final LocalZoneRegistry _localZoneRegistry = LocalZoneRegistry();
  Timer? _zoneHoverDebounce;
  int _zoneHoverSeq = 0;
  String? _hoverZoneId;
  String? _hoverZoneName;

  // Detail sheet state (achievements route to the canonical
  // AchievementDetailSheet — only quest/skill/chain use the inline sheet).
  SideQuest? _selectedQuest;
  SkillGroup? _selectedSkill;
  Quest? _selectedQuestChain;
  Color _selectedOutlineColor = Colors.white;
  bool _showDetailSheet = false;

  // Filter sheet state
  // _showFilterSheet → hovering bubble quick-filter column above the
  // filter button. _showAdvancedSheet → full advanced filter sheet
  // opened from the column's "Advanced settings" entry.
  bool _showFilterSheet = false;
  bool _showAdvancedSheet = false;

  // Animation controllers
  late AnimationController _sheetAnimController;
  late AnimationController _controlsFadeController;
  // Drives the top bar slide-up + height collapse when entering fullscreen.
  // value 0 = top bar visible, value 1 = top bar hidden (slid up off-screen).
  late AnimationController _immersiveController;

  // Long-press context menu (disabled — TODO: implement when needed)

  // Pin popup state
  bool _showPopup = false;
  String _popupTitle = '';
  String _popupSubtitle = '';
  Color _popupColor = Colors.white;
  Color _popupOutlineColor = Colors.white;
  IconData _popupIcon = LucideIcons.mapPin;
  String _popupMarkerId = '';
  // Cached data for "View more"
  Achievement? _popupAchievement;
  SideQuest? _popupQuest;
  SkillGroup? _popupSkill;
  Quest? _popupQuestChain;
  late AnimationController _popupAnimController;

  // Guard: when a marker tap fires, suppress the map-click dismiss
  // because Mapbox fires both annotation-tap and map-tap for the same touch.
  bool _markerTapConsumed = false;

  @override
  void initState() {
    super.initState();
    // Cache provider references before any async work — ref is safe here
    _cameraStateNotifier = ref.read(cachedCameraStateProvider.notifier);

    _mapController = createMapController(token: _mapboxToken);
    _mapController.onMarkerClick = _onMarkerClick;
    _mapController.onMapLongPress = null;
    _mapController.onMapClick = _onMapClick;
    _mapController.onCameraChanged = _onCameraChanged;

    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popupAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _controlsFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 0,
    );
    _immersiveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 0,
    );

    // Show system bars with transparent backgrounds so the map feels full-screen
    // but the status bar and navigation buttons remain visible.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: true,
    ));

    // Kick off a one-shot location fetch so we have a position to center on
    Future.microtask(() {
      if (!mounted) return;
      final geo = ref.read(geolocationProvider);
      if (!geo.hasLocation) {
        ref.read(geolocationProvider.notifier).getCurrentLocation();
      }
    });

    // On desktop the placeholder is "ready" immediately — without this the
    // loading shimmer covers the canvas forever waiting for onMapReady.
    if (!_isNativeMapSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onMapReady());
    }
  }

  @override
  void dispose() {
    // Detach callbacks so async map operations don't call back into disposed state
    _mapController.onMarkerClick = null;
    _mapController.onMapLongPress = null;
    _mapController.onMapClick = null;
    _mapController.onCameraChanged = null;
    _mapController.onStateChanged = null;

    // Restore default system UI with opaque nav bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarContrastEnforced: true,
    ));
    // Save camera state using cached notifier — no ref access needed
    _saveCameraState();
    _zoneHoverDebounce?.cancel();
    _zoneBoundaryService.dispose();
    _sheetAnimController.dispose();
    _controlsFadeController.dispose();
    _immersiveController.dispose();
    _popupAnimController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _saveCameraState() async {
    try {
      final state = await _mapController.getCameraState();
      if (state != null) {
        _cameraStateNotifier.state = CachedCameraState(
          latitude: state.lat,
          longitude: state.lng,
          zoom: state.zoom,
        );
      }
    } catch (e, st) {
      // Map controller may already be disposed — safe to ignore
      logError(e, st, context: 'map.cacheCameraState');
    }
  }

  void _onMapReady() {
    if (!mounted) return;
    setState(() => _mapInitialized = true);
    _controlsFadeController.forward();

    // Highlight the zone under the initial camera position.
    _zoneHoverDebounce?.cancel();
    _zoneHoverDebounce =
        Timer(const Duration(milliseconds: 600), _updateHoveredZone);
  }

  void _onMapClick(double lat, double lng) {
    // If a marker tap already handled this touch, skip
    if (_markerTapConsumed) return;
    _dismissPopup();
    _dismissDetailSheet();
    if (_showFilterSheet || _showAdvancedSheet) {
      setState(() {
        _showFilterSheet = false;
        _showAdvancedSheet = false;
      });
    }
  }

  void _onMarkerClick(String markerId, MapMarkerType type) {
    if (!mounted) return;

    // Backdrop mode: popups live in the full-map chrome, so a pin tap just
    // answers with a glide + tick. The full experience is one Explore tap away.
    if (ref.read(mapBackdropProvider)) {
      final marker =
          _lastMarkers?.where((m) => m.id == markerId).firstOrNull;
      if (marker != null) {
        HapticFeedback.lightImpact();
        _mapController.easeToPoint(marker.latitude, marker.longitude);
      }
      return;
    }

    _dismissLongPressMenu();

    // Prevent the map-click handler from also firing for this touch
    _markerTapConsumed = true;
    Future.microtask(() => _markerTapConsumed = false);

    // Same pin tapped again — toggle off with animation
    if (_showPopup && _popupMarkerId == markerId) {
      _dismissPopup();
      return;
    }

    switch (type) {
      case MapMarkerType.achievement:
        final achievements = ref.read(achievementsProvider);
        final achievement = achievements.allAchievements
            .where((a) => a.id == markerId)
            .firstOrNull;
        if (achievement != null) {
          final tierColor = AchievementMarker.tierColor(achievement.tier);
          final collectionId = achievement.collectionId;
          _showPinPopup(
            markerId: markerId,
            lat: achievement.latitude!,
            lng: achievement.longitude!,
            title: achievement.title,
            subtitle: achievement.collectionId ?? '',
            color: tierColor,
            outlineColor:
                collectionId != null ? colorForCollection(collectionId) : tierColor,
            icon: LucideIcons.trophy,
            achievement: achievement,
          );
        }
      case MapMarkerType.quest:
        final questId = markerId.contains('@') ? markerId.split('@').first : markerId;
        final quests = ref.read(questsProvider);
        final quest = quests.allQuests
            .where((q) => q.id == questId)
            .firstOrNull;
        if (quest != null) {
          _showPinPopup(
            markerId: markerId,
            lat: quest.latitude!,
            lng: quest.longitude!,
            title: quest.title,
            subtitle: quest.category,
            color: QuestMarkerItem(quest: quest).pinColor,
            outlineColor: AppColors.error,
            icon: LucideIcons.swords,
            quest: quest,
          );
        }
      case MapMarkerType.skill:
        final skills = ref.read(skillsProvider);
        final skill = skills.getSkillById(markerId);
        if (skill != null) {
          _showPinPopup(
            markerId: markerId,
            lat: skill.latitude!,
            lng: skill.longitude!,
            title: skill.name,
            subtitle: skill.description,
            color: SkillMarkerItem(skill: skill).pinColor,
            icon: LucideIcons.sparkles,
            skill: skill,
          );
        }
      case MapMarkerType.questChain:
        final chainId = markerId.replaceFirst('chain-', '');
        final chains = ref.read(questChainProvider);
        final chain = chains.allQuests
            .where((q) => q.id == chainId)
            .firstOrNull;
        if (chain != null) {
          // Look up the first step's activity location
          final quests = ref.read(questsProvider);
          final firstActivity = quests.allQuests
              .where((q) => q.id == chain.steps.first.targetId)
              .firstOrNull;
          if (firstActivity != null &&
              firstActivity.latitude != null &&
              firstActivity.longitude != null) {
            _showPinPopup(
              markerId: markerId,
              lat: firstActivity.latitude!,
              lng: firstActivity.longitude!,
              title: '${chain.icon} ${chain.title}',
              subtitle: '${chain.totalSteps} steps · ${chain.rarity.name}',
              color: QuestChainMarkerItem.rarityColor(chain.rarity),
              outlineColor: AppColors.error,
              icon: LucideIcons.scroll,
              questChain: chain,
            );
          }
        }
    }
  }

  Future<void> _showPinPopup({
    required String markerId,
    required double lat,
    required double lng,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    Color? outlineColor,
    Achievement? achievement,
    SideQuest? quest,
    SkillGroup? skill,
    Quest? questChain,
  }) async {
    // Clear any previous radius circle
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
    }

    // If another popup is showing, reset instantly (no reverse animation)
    if (_showPopup) {
      _popupAnimController.stop();
      _popupAnimController.value = 0;
    }

    if (!mounted) return;

    _popupTitle = title;
    _popupSubtitle = subtitle;
    _popupColor = color;
    _popupOutlineColor = outlineColor ?? color;
    _popupIcon = icon;
    _popupMarkerId = markerId;
    _popupAchievement = achievement;
    _popupQuest = quest;
    _popupSkill = skill;
    _popupQuestChain = questChain;

    // Mark the pin as selected — draws the black arrow above it
    _mapController.setSelectedMarker(markerId);

    // Answer the touch: a tick in the hand and a camera glide to the pin
    // (popup is screen-fixed at the top, so this never chases its own anchor).
    HapticFeedback.lightImpact();
    _mapController.easeToPoint(lat, lng);

    setState(() => _showPopup = true);
    _popupAnimController.forward(from: 0);

    // Auto-show the area overlay (radius or polygon) whenever a pin with
    // a geofence is opened, so the user immediately sees its claim zone.
    if (achievement != null && achievement.hasGeofence) {
      _popupShowRadius();
    }
  }

  void _dismissPopup() {
    if (!_showPopup) return;
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
    }
    // Clear marker ID immediately to prevent re-trigger race conditions
    _popupMarkerId = '';
    _popupAchievement = null;
    _popupQuest = null;
    _popupSkill = null;
    _popupQuestChain = null;
    _mapController.setSelectedMarker(null);
    // Animate out, then remove from tree
    _popupAnimController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _showPopup = false);
    });
  }

  void _popupViewMore() {
    final achievement = _popupAchievement;
    final quest = _popupQuest;
    final skill = _popupSkill;
    final questChain = _popupQuestChain;
    final outlineColor = _popupOutlineColor;
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
    }
    // Achievements route to the canonical full-detail page so all options
    // (retroactive claim, photos, remarks, visit history, collection
    // progress, opening hours, etc.) match the main achievement page.
    // Quests / skills / chains continue to use the inline bottom sheet.
    if (achievement != null) {
      AchievementDetailSheet.show(
        context,
        achievement,
        outlineColor: outlineColor,
      );
    } else {
      _openDetailSheet(
        quest: quest,
        skill: skill,
        questChain: questChain,
        outlineColor: outlineColor,
      );
    }
    // Animate popup out in parallel, then remove it from the tree.
    _popupAnimController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _showPopup = false;
        _popupMarkerId = '';
        _popupAchievement = null;
        _popupQuest = null;
        _popupSkill = null;
        _popupQuestChain = null;
      });
    });
    _mapController.setSelectedMarker(null);
  }

  bool _radiusVisible = false;

  void _popupShowRadius() {
    final achievement = _popupAchievement;
    if (achievement == null || !achievement.hasGeofence) return;

    // Toggle: if radius is already showing, clear it
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
      return;
    }

    _radiusVisible = true;
    if (achievement.hasPolygon) {
      _mapController.showClaimPolygon(achievement.claimPolygon!, _popupColor);
    } else {
      _mapController.showRadiusCircle(
        achievement.latitude!,
        achievement.longitude!,
        achievement.claimRadius!,
        _popupColor,
      );
    }
  }

  void _onCameraChanged() {
    // Popup is fixed at the top of the screen (not anchored to the pin) and
    // the area overlay persists through pan/zoom, so nothing to do here.
    // Popup and overlay are dismissed only by the X button or when another
    // pin is selected.

    // Zone-hover highlight follows the camera center once it settles.
    _zoneHoverDebounce?.cancel();
    _zoneHoverDebounce =
        Timer(const Duration(milliseconds: 400), _updateHoveredZone);
  }

  /// Resolve the admin boundary under the map center (country → neighbourhood
  /// depending on zoom) and highlight its borders.
  Future<void> _updateHoveredZone() async {
    if (!_isNativeMapSupported || !mounted) return;
    final seq = ++_zoneHoverSeq;

    final cam = await _mapController.getCameraState();
    if (cam == null || seq != _zoneHoverSeq || !mounted) return;

    // Bundled neighborhood zones win at the neighbourhood layer — OSM has
    // no polygons for them (e.g. Netanya's neighborhoods are point nodes).
    ZoneBoundary? boundary;
    if (ZoneBoundaryService.adminZoomFor(cam.zoom) >= 14) {
      boundary = await _localZoneRegistry.boundaryAt(cam.lat, cam.lng);
    }
    boundary ??=
        await _zoneBoundaryService.boundaryAt(cam.lat, cam.lng, cam.zoom);
    // A newer camera movement superseded this lookup — drop the result.
    if (seq != _zoneHoverSeq || !mounted) return;

    final resolved = boundary;
    if (resolved == null) {
      if (_hoverZoneId != null) {
        _hoverZoneId = null;
        setState(() => _hoverZoneName = null);
        await _mapController.clearZoneHighlight();
      }
      return;
    }
    if (resolved.id == _hoverZoneId) return;
    _hoverZoneId = resolved.id;
    setState(() => _hoverZoneName = resolved.name);
    await _mapController.setZoneHighlight(resolved.rings);
  }

  void _openDetailSheet(
      {SideQuest? quest,
      SkillGroup? skill,
      Quest? questChain,
      Color? outlineColor}) {
    setState(() {
      _showFilterSheet = false;
      _showAdvancedSheet = false;
      _selectedQuest = quest;
      _selectedSkill = skill;
      _selectedQuestChain = questChain;
      _selectedOutlineColor = outlineColor ?? Colors.white;
      _showDetailSheet = true;
    });
    _sheetAnimController.forward(from: 0);
  }

  void _dismissDetailSheet() {
    if (!_showDetailSheet) return;
    _sheetAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedQuest = null;
          _selectedSkill = null;
          _selectedQuestChain = null;
          _showDetailSheet = false;
        });
      }
    });
  }

  Widget _buildBubbleQuickFilters(BuildContext context) {
    return BubbleQuickFilters(
      onClose: () => setState(() => _showFilterSheet = false),
      onOpenAdvanced: () {
        setState(() {
          _showFilterSheet = false;
          _showAdvancedSheet = true;
        });
      },
    );
  }

  Widget _buildAdvancedFilterSheet(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // absorb taps on the sheet
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: UnifiedFilterSheet(
            onClose: () =>
                setState(() => _showAdvancedSheet = false),
          ),
        ),
      ),
    );
  }

  void _dismissLongPressMenu() {
    // No-op: long-press menu disabled
  }

  void _exitMap() {
    _saveCameraState();
    context.go('/');
  }

  void _toggleImmersive() {
    final current = ref.read(mapImmersiveProvider);
    ref.read(mapImmersiveProvider.notifier).state = !current;
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    final q = query.trim().toLowerCase();

    // Search across all markers for a match
    final achievements = ref.read(achievementsProvider);
    final quests = ref.read(questsProvider);
    final skills = ref.read(skillsProvider);

    // Try achievements
    for (final a in achievements.allAchievements) {
      if (a.latitude != null &&
          a.longitude != null &&
          a.title.toLowerCase().contains(q)) {
        _mapController.flyTo(a.latitude!, a.longitude!, 2000);
        return;
      }
    }
    // Try quests
    for (final quest in quests.allQuests) {
      if (quest.latitude != null &&
          quest.longitude != null &&
          quest.title.toLowerCase().contains(q)) {
        _mapController.flyTo(quest.latitude!, quest.longitude!, 2000);
        return;
      }
    }
    // Try skills
    for (final s in skills.allSkills) {
      if (s.latitude != null &&
          s.longitude != null &&
          s.name.toLowerCase().contains(q)) {
        _mapController.flyTo(s.latitude!, s.longitude!, 2000);
        return;
      }
    }
    // Try quest chains (fly to first step's activity location)
    final chains = ref.read(questChainProvider);
    for (final chain in chains.allQuests) {
      if (chain.title.toLowerCase().contains(q) && chain.steps.isNotEmpty) {
        final activity = quests.allQuests
            .where((a) => a.id == chain.steps.first.targetId)
            .firstOrNull;
        if (activity != null &&
            activity.latitude != null &&
            activity.longitude != null) {
          _mapController.flyTo(activity.latitude!, activity.longitude!, 2000);
          return;
        }
      }
    }
  }

  void _centerOnUser() {
    HapticFeedback.selectionClick();
    final geo = ref.read(geolocationProvider);
    if (geo.hasLocation) {
      _mapController.flyTo(geo.latitude!, geo.longitude!, 2000);
    } else {
      ref.read(geolocationProvider.notifier).getCurrentLocation();
    }
  }

  void _updateMapState() {
    if (!mounted || !_mapController.isInitialized) return;

    final geo = ref.read(geolocationProvider);
    final achievements = ref.read(achievementsProvider);
    final quests = ref.read(questsProvider);
    final skills = ref.read(skillsProvider);
    final chains = ref.read(questChainProvider);
    final filter = ref.read(mapFilterProvider);
    final currentCountry = ref.read(currentCountryProvider);

    Achievement? findById(String id) {
      for (final a in achievements.allAchievements) {
        if (a.id == id) return a;
      }
      return null;
    }

    bool passesZone(double lat, double lng) {
      if (!filter.zoneFilterEnabled) return true;
      switch (filter.zoneMode) {
        case ZoneMode.radius:
          if (!geo.hasLocation) return true;
          final meters = haversineMeters(
              geo.latitude!, geo.longitude!, lat, lng);
          return meters <= filter.zoneRadiusKm * 1000;
        case ZoneMode.country:
          final selected = filter.zoneCountryAchievementId != null
              ? findById(filter.zoneCountryAchievementId!)
              : currentCountry;
          if (selected == null) return true;
          return isWithinClaimArea(lat, lng, selected);
        case ZoneMode.continent:
          final continent = filter.zoneContinentAchievementId != null
              ? findById(filter.zoneContinentAchievementId!)
              : null;
          if (continent == null) return true;
          return isWithinClaimArea(lat, lng, continent);
        case ZoneMode.unlimited:
          return true;
      }
    }

    final markers = <MapMarkerItem>[];

    if (filter.showAchievements) {
      for (final a in achievements.allAchievements) {
        if (a.latitude != null && a.longitude != null) {
          if (filter.showOnlyUnlocked && !a.isUnlocked) continue;
          if (filter.selectedAchievementCollections.isNotEmpty &&
              !filter.selectedAchievementCollections.contains(a.collectionId)) {
            continue;
          }
          if (!passesZone(a.latitude!, a.longitude!)) continue;
          markers.add(AchievementMarkerItem(achievement: a));
        }
      }
    }

    if (filter.showQuests) {
      for (final q in quests.allQuests) {
        if (filter.selectedQuestCategories.isNotEmpty &&
            !filter.selectedQuestCategories.contains(q.category)) {
          continue;
        }
        // Create a marker for every location (primary + additional)
        final allLocs = q.allLocations;
        for (var i = 0; i < allLocs.length; i++) {
          final loc = allLocs[i];
          if (!passesZone(loc.latitude, loc.longitude)) continue;
          final locQuest = q.copyWith(
              latitude: loc.latitude, longitude: loc.longitude);
          markers.add(QuestMarkerItem(quest: locQuest, locationIndex: i));
        }
      }
    }

    if (filter.showSkills) {
      for (final s in skills.allSkills) {
        if (s.latitude != null && s.longitude != null) {
          if (filter.selectedSkillIds.isNotEmpty && !filter.selectedSkillIds.contains(s.id)) {
            continue;
          }
          if (!passesZone(s.latitude!, s.longitude!)) continue;
          markers.add(SkillMarkerItem(skill: s));
        }
      }
    }

    if (filter.showQuestChains) {
      for (final chain in chains.allQuests) {
        if (chain.steps.isEmpty) continue;
        if (filter.selectedQuestChainRarities.isNotEmpty &&
            !filter.selectedQuestChainRarities.contains(chain.rarity.name)) {
          continue;
        }
        // Place quest chain marker at its first step's activity location
        final firstStepTarget = chain.steps.first.targetId;
        final activity = quests.allQuests
            .where((q) => q.id == firstStepTarget)
            .firstOrNull;
        if (activity != null &&
            activity.latitude != null &&
            activity.longitude != null) {
          if (!passesZone(activity.latitude!, activity.longitude!)) continue;
          markers.add(QuestChainMarkerItem(
            questChain: chain,
            latitude: activity.latitude!,
            longitude: activity.longitude!,
          ));
        }
      }
    }

    // Only push markers to the map if they actually changed
    if (!listEquals(_lastMarkers, markers)) {
      _lastMarkers = markers;
      _mapController.setMarkers(markers);
    }

    // "Show all unlocked areas" overlay — renders every unlocked polygon
    // persistently so the user can see their coverage while navigating.
    _updateUnlockedAreasOverlay(achievements, filter);

    // Only update user location if it changed
    if (geo.hasLocation) {
      if (_lastUserLat != geo.latitude || _lastUserLng != geo.longitude) {
        _lastUserLat = geo.latitude;
        _lastUserLng = geo.longitude;
        _mapController.setUserLocation(geo.latitude!, geo.longitude!);
      }
    }

    // First GPS fix of the session: dive from the launch globe down to the
    // user. A dedicated flag (not _mapReady) so the fly-in still happens
    // when the map finishes initializing before the GPS does — which is the
    // normal cold-start order now that the canvas opens with the app.
    if (!_didInitialFly && geo.hasLocation) {
      _didInitialFly = true;
      final cached = ref.read(cachedCameraStateProvider);
      if (cached == null) {
        _mapController.flyTo(geo.latitude!, geo.longitude!, 5000);
      }
    }
  }

  /// Render or clear the per-collection unlocked-area overlay. Each enabled
  /// collection in [MapFilterState.unlockedAreaCollections] renders:
  ///   (a) every unlocked member polygon (hashed color per area), and
  ///   (b) a fixed convex-hull outline around ALL member polygons in the
  ///       collection. Each member polygon is drawn in its own color — no
  ///       merging, summing, or hulling into a single shape.
  /// Collections without polygon-backed unlocked members render nothing.
  Future<void> _updateUnlockedAreasOverlay(
      AchievementsState achievements, MapFilterState filter) async {
    final enabledCollections = filter.showAchievements
        ? filter.unlockedAreaCollections
        : const <String>{};

    if (enabledCollections.isEmpty) {
      if (_lastUnlockedAreasSignature != null) {
        _lastUnlockedAreasSignature = null;
        await _mapController.clearUnlockedAreasOverlay();
      }
      return;
    }

    final areas = <({List<List<double>> polygon, Color color})>[];
    final memberSig = StringBuffer();

    for (final a in achievements.allAchievements) {
      if (!a.isUnlocked) continue;
      if (!a.hasPolygon) continue;
      final cid = a.collectionId;
      if (cid == null || !enabledCollections.contains(cid)) continue;

      areas.add((polygon: a.claimPolygon!, color: colorForArea(a)));
      memberSig.write('${a.id};');
    }

    final memberSignature = memberSig.toString();
    if (memberSignature != _lastUnlockedAreasSignature) {
      _lastUnlockedAreasSignature = memberSignature;
      await _mapController.showUnlockedAreasOverlay(areas);
    }
  }

  // ── Inline detail sheet content builders ──

  Widget _buildSheetContentWithController(ScrollController controller) {
    if (_selectedQuest != null) {
      return _buildQuestContent(controller);
    } else if (_selectedSkill != null) {
      return _buildSkillContent(controller);
    } else if (_selectedQuestChain != null) {
      return _buildQuestChainContent(controller);
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuestContent(ScrollController controller) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final quest = _selectedQuest!;
    final questsState = ref.read(questsProvider);
    final difficultyLabel = switch (quest.difficulty) {
      QuestDifficulty.easy => 'Easy',
      QuestDifficulty.medium => 'Medium',
      QuestDifficulty.hard => 'Hard',
      QuestDifficulty.legendary => 'Legendary',
    };
    final difficultyColor = switch (quest.difficulty) {
      QuestDifficulty.easy => AppColors.success,
      QuestDifficulty.medium => AppColors.accent,
      QuestDifficulty.hard => const Color(0xFFF97316),
      QuestDifficulty.legendary => const Color(0xFF9333EA),
    };
    final verificationLabel = switch (quest.verification) {
      VerificationMethod.photo => 'Photo',
      VerificationMethod.manual => 'Manual',
      VerificationMethod.location => 'Location',
      VerificationMethod.timeBased => 'Timed',
    };
    final verificationIcon = switch (quest.verification) {
      VerificationMethod.photo => LucideIcons.camera,
      VerificationMethod.manual => LucideIcons.checkSquare,
      VerificationMethod.location => LucideIcons.mapPin,
      VerificationMethod.timeBased => LucideIcons.timer,
    };

    // Check if quest is locked
    final isUnlocked = quest.isUnlocked(
      skillLevels: questsState.skillLevels,
      allQuests: questsState.allQuests,
    );

    // Find the skill this quest levels up
    final skill = ref.read(skillsProvider).getSkillById(quest.skillType);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        // Title row
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: difficultyColor,
              ),
              child: const Icon(
                LucideIcons.swords,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quest.category,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Badges row
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _SheetBadge(
              label: difficultyLabel,
              color: difficultyColor,
              icon: LucideIcons.signal,
            ),
            _SheetBadge(
              label: '+${quest.xpReward} XP',
              color: AppColors.xpGreen,
              icon: LucideIcons.zap,
            ),
            _SheetBadge(
              label: verificationLabel,
              color: AppColors.textMuted,
              icon: verificationIcon,
            ),
            if (quest.isRepeatable)
              _SheetBadge(
                label: '${quest.completionCount}/${quest.maxCompletions}',
                color: AppColors.info,
                icon: LucideIcons.repeat,
              ),
            if (!isUnlocked)
              _SheetBadge(
                label: 'Locked',
                color: AppColors.error,
                icon: LucideIcons.lock,
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Description
        Text(
          quest.description,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),

        // Linked skill
        if (skill != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(skill.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RegistryL10n.skillName(locale, skill.id, skill.name),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Lv ${questsState.skillLevels[skill.id] ?? 1} · Levels up this skill',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Requirements (if locked)
        if (!isUnlocked) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(LucideIcons.lock, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (quest.requiredSkillType != null && quest.requiredSkillLevel != null)
            _RequirementRow(
              text: 'Reach level ${quest.requiredSkillLevel} in ${quest.requiredSkillType}',
              met: (questsState.skillLevels[quest.requiredSkillType] ?? 0) >= quest.requiredSkillLevel!,
            ),
          ...quest.requiredQuestIds.map((reqId) {
            final reqQuest = questsState.allQuests.where((q) => q.id == reqId).firstOrNull;
            return _RequirementRow(
              text: 'Complete "${reqQuest?.title ?? reqId}"',
              met: reqQuest?.isCompleted ?? false,
            );
          }),
        ],

        const SizedBox(height: 18),

        // Status
        if (quest.isCompleted)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.check, size: 18, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  quest.isRepeatable
                      ? '${l10n.unlocked} · ${quest.completionCount}/${quest.maxCompletions}'
                      : l10n.unlocked,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSkillContent(ScrollController controller) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final skill = _selectedSkill!;
    final questsState = ref.read(questsProvider);
    final level = questsState.skillLevels[skill.id] ?? 0;
    final xp = questsState.skillXp[skill.id] ?? 0;
    final xpForNext = skill.xpPerLevel;
    final xpInLevel = xp % xpForNext;
    final skillColor = SkillMarkerItem.parseHexColor(skill.gradientStart);

    // Count related activities
    final relatedQuests = questsState.allQuests
        .where((q) => q.skillType == skill.id)
        .toList();
    final completedCount = relatedQuests.where((q) => q.completionCount > 0).length;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        // Title row
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skillColor,
              ),
              child: Center(
                child: Text(
                  skill.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RegistryL10n.skillName(locale, skill.id, skill.name),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.level} $level / ${skill.maxLevel}',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // XP progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: level >= skill.maxLevel
                      ? 1.0
                      : (xpForNext > 0 ? xpInLevel / xpForNext : 0),
                  minHeight: 6,
                  backgroundColor: skillColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(skillColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              level >= skill.maxLevel
                  ? 'MAX'
                  : '$xpInLevel / $xpForNext XP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Stats chips
        Row(
          children: [
            _SheetBadge(
              label: '${relatedQuests.length} activities',
              color: AppColors.accent,
              icon: LucideIcons.compass,
            ),
            const SizedBox(width: 6),
            _SheetBadge(
              label: '$completedCount done',
              color: AppColors.success,
              icon: LucideIcons.checkCircle,
            ),
            const SizedBox(width: 6),
            _SheetBadge(
              label: '$xp total XP',
              color: AppColors.xpGreen,
              icon: LucideIcons.zap,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Description
        Text(
          RegistryL10n.skillDescription(
              locale, skill.id, skill.description),
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuestChainContent(ScrollController controller) {
    final chain = _selectedQuestChain!;
    final rarityColor = QuestChainMarkerItem.rarityColor(chain.rarity);
    final chainNotifier = ref.read(questChainProvider.notifier);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rarityColor,
              ),
              child: Center(
                child: Text(
                  chain.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chain.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: rarityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          chain.rarity.name[0].toUpperCase() +
                              chain.rarity.name.substring(1),
                          style: TextStyle(
                            color: rarityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${chain.xpReward} XP',
                        style: const TextStyle(
                          color: AppColors.xpGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          chain.description,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        // Step progress
        Text(
          '${chain.completedStepCount}/${chain.totalSteps} steps completed',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: chain.progress,
            backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(rarityColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        // Steps list
        for (final step in chain.steps) ...[
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isCompleted
                      ? AppColors.success
                      : AppColors.textMuted.withValues(alpha: 0.3),
                ),
                child: Icon(
                  step.isCompleted ? LucideIcons.check : LucideIcons.circle,
                  size: 14,
                  color: step.isCompleted ? Colors.white : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    color: step.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: step.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (step.type == QuestStepType.activity
                          ? AppColors.success
                          : AppColors.gold)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  step.type == QuestStepType.activity
                      ? 'Activity'
                      : 'Achievement',
                  style: TextStyle(
                    color: step.type == QuestStepType.activity
                        ? AppColors.success
                        : AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        if (chain.isClaimed)
          Center(
            child: Text(
              'Completed!',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          )
        else if (chain.isClaimable)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                chainNotifier.claimQuest(chain.id);
                _dismissDetailSheet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
              ),
              child: Text('Claim +${chain.xpReward} XP'),
            ),
          )
        else if (!chain.isStarted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                chainNotifier.startQuest(chain.id);
                _dismissDetailSheet();
              },
              child: const Text('Start Quest'),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                chainNotifier.abandonQuest(chain.id);
                _dismissDetailSheet();
              },
              child: const Text('Abandon Quest'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final geo = ref.watch(geolocationProvider);
    ref.watch(achievementsProvider);
    ref.watch(questsProvider);
    ref.watch(skillsProvider);
    ref.watch(questChainProvider);
    ref.watch(mapFilterProvider);
    final isImmersive = ref.watch(mapImmersiveProvider);
    final showZoneSettings = ref.watch(mapZoneSettingsOpenProvider);
    final l10n = AppLocalizations.of(context)!;

    // Drive the slide-up animation from the immersive flag.
    if (isImmersive && _immersiveController.status != AnimationStatus.completed) {
      _immersiveController.forward();
    } else if (!isImmersive &&
        _immersiveController.status != AnimationStatus.dismissed) {
      _immersiveController.reverse();
    }

    // Listen for camera commands from AppShell (explore button taps)
    ref.listen(mapCameraCommandProvider, (prev, next) {
      if (next == null || !_mapController.isInitialized) return;
      switch (next) {
        case CenterOnUserCommand():
          final g = ref.read(geolocationProvider);
          if (g.hasLocation) {
            _mapController.animateCamera(
                g.latitude!, g.longitude!, 14.0,
                durationMs: 1200);
          }
          ref.read(isGlobeViewProvider.notifier).state = false;
        case ZoomToGlobeCommand():
          _mapController.animateCamera(20.0, 0.0, 2.0, durationMs: 1200);
          ref.read(isGlobeViewProvider.notifier).state = true;
      }
      Future.microtask(
          () => ref.read(mapCameraCommandProvider.notifier).state = null);
    });

    // Update map entities whenever state changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMapState());

    final Widget mapView = _isNativeMapSupported
        ? PlatformMapViewWidget(
            key: _mapViewKey,
            controller: _mapController,
            onMapReady: _onMapReady,
          )
        : const _DesktopMapPlaceholder();

    // Backdrop mode — the map is the canvas behind the Home sheet: bare,
    // full-bleed, interactive, with all chrome stripped. The GlobalKey above
    // reparents the native view without recreating it.
    if (ref.watch(mapBackdropProvider)) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(child: mapView),
            if (!_mapInitialized)
              Positioned.fill(child: _MapLoadingShimmer()),
            // Auto-recognized zone name — below the canvas chips row.
            if (_hoverZoneName != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: 0,
                right: 0,
                child: Center(child: _ZoneNamePill(name: _hoverZoneName!)),
              ),
          ],
        ),
      );
    }

    return PopScope(
      canPop:
          !_showDetailSheet && !_showFilterSheet && !_showAdvancedSheet,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_showDetailSheet) {
          _dismissDetailSheet();
        } else if (_showAdvancedSheet) {
          setState(() => _showAdvancedSheet = false);
        } else if (_showFilterSheet) {
          setState(() => _showFilterSheet = false);
        }
      },
      child: Material(
      type: MaterialType.transparency,
      child: SafeArea(
        // In fullscreen mode, drop the top inset so the map extends under the
        // status bar (matches the behavior at the bottom, where the nav bar
        // is also hidden).
        top: !isImmersive,
        bottom: false,
        child: Column(
          children: [
            // Top bar: close button (with Exit label) + search bar + zone
            // banner. Sits above the map (not overlaying it) so the map's
            // top edge stops just below this bar. Animates up + collapses
            // when entering fullscreen instead of disappearing instantly.
            ClipRect(
              child: SizeTransition(
                sizeFactor: ReverseAnimation(CurvedAnimation(
                  parent: _immersiveController,
                  curve: Curves.easeOutCubic,
                )),
                axisAlignment: -1,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(0, -1),
                  ).animate(CurvedAnimation(
                    parent: _immersiveController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: _controlsFadeController,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MapExitButton(
                                onTap: _exitMap,
                                tooltip: l10n.mapCloseMap,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MapSearchBar(
                                  onSearch: _onSearchSubmitted,
                                ),
                              ),
                            ],
                          ),
                          const _ZoneStatusBanner(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Map area + overlays — fills the remaining space below the top bar
            Expanded(
              child: Stack(
                children: [
                  // Platform map (fills the area below the top bar)
                  Positioned.fill(child: mapView),

                  // Loading shimmer overlay
                  if (!_mapInitialized)
                    Positioned.fill(
                      child: _MapLoadingShimmer(),
                    ),

                  // Auto-recognized zone name — top of the map canvas.
                  if (_hoverZoneName != null)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child:
                          Center(child: _ZoneNamePill(name: _hoverZoneName!)),
                    ),

            // Right side: map controls (location, zoom, fullscreen).
            // Bottom edge aligns with the filter button on the left so the
            // fullscreen toggle and the filter pill share one baseline.
            Positioned(
              right: 16,
              bottom: 40,
              child: FadeTransition(
                opacity: _controlsFadeController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapControlButton(
                      icon: LucideIcons.crosshair,
                      onTap: _centerOnUser,
                      tooltip: l10n.mapMyLocation,
                      highlighted: true,
                    ),
                    const SizedBox(height: 10),
                    _MapControlButton(
                      icon: LucideIcons.plus,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _mapController.zoomIn();
                      },
                      tooltip: l10n.mapZoomIn,
                    ),
                    const SizedBox(height: 10),
                    _MapControlButton(
                      icon: LucideIcons.minus,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _mapController.zoomOut();
                      },
                      tooltip: l10n.mapZoomOut,
                    ),
                    const SizedBox(height: 10),
                    _MapControlButton(
                      icon: isImmersive
                          ? LucideIcons.minimize2
                          : LucideIcons.maximize2,
                      onTap: _toggleImmersive,
                      tooltip: isImmersive ? 'Show nav bar' : 'Fullscreen',
                    ),
                  ],
                ),
              ),
            ),

            // Zone settings popover — overlays the map (anchored just under
            // where the banner sits) so opening it does not push the top
            // bar's height. Toggled via the gear icon in _ZoneStatusBanner.
            if (showZoneSettings && !isImmersive)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _ZoneSettingsPopover(
                  onClose: () => ref
                      .read(mapZoneSettingsOpenProvider.notifier)
                      .state = false,
                ).animate().fadeIn(
                      duration: 160.ms,
                      curve: Curves.easeOut,
                    ).slideY(
                      begin: -0.06,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),

            // Filter button (bottom-left, above nav bar). Bottom edge aligns
            // with the right-side control column so they share a baseline.
            Positioned(
              left: 16,
              bottom: 40,
              child: FadeTransition(
                opacity: _controlsFadeController,
                child: MapFilterButton(
                  onTap: () {
                    final wasOpen =
                        _showFilterSheet || _showAdvancedSheet;
                    if (!wasOpen && _showPopup) {
                      _dismissPopup();
                    }
                    setState(() {
                      if (wasOpen) {
                        _showFilterSheet = false;
                        _showAdvancedSheet = false;
                      } else {
                        _showFilterSheet = true;
                      }
                    });
                  },
                ),
              ),
            ),

            // Hovering bubble quick-filter column above the filter button.
            // First-tap surface — opens the advanced sheet via its
            // "Advanced settings" entry.
            if (_showFilterSheet)
              Positioned(
                left: 0,
                right: 0,
                bottom: 88,
                child: _buildBubbleQuickFilters(context)
                    .animate()
                    .fadeIn(duration: 160.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.12,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),

            // Advanced filter sheet — opened from the bubble column.
            if (_showAdvancedSheet)
              Positioned(
                left: 0,
                right: 0,
                bottom: 88,
                child: _buildAdvancedFilterSheet(context)
                    .animate()
                    .fadeIn(duration: 180.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.12,
                      end: 0,
                      duration: 240.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .scaleXY(
                      begin: 0.96,
                      end: 1.0,
                      duration: 240.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),

            // Live tracking indicator
            if (geo.isLiveTracking)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 100),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeIn(duration: 800.ms)
                              .fadeOut(duration: 800.ms),
                          const SizedBox(width: 6),
                          Text(
                            l10n.trackingActive,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // Pin popup — fixed at top of screen, slides down from above.
            // Persists through map pan/zoom; dismissed only via X button or
            // when another pin is selected.
            if (_showPopup)
              Builder(
                builder: (context) {
                  final ach = _popupAchievement;
                  return MapPinPopup(
                    title: _popupTitle,
                    subtitle: _popupSubtitle,
                    color: _popupColor,
                    outlineColor: _popupOutlineColor,
                    icon: _popupIcon,
                    animation: _popupAnimController,
                    onViewMore: _popupViewMore,
                    onDismiss: _dismissPopup,
                    xpReward: ach?.xpReward,
                    isUnlocked: ach?.isUnlocked ?? false,
                    visitCount: ach?.visitCount ?? 0,
                    isPendingClaim: ach?.isPendingClaim ?? false,
                  );
                },
              ),

            // Bottom sheet — draggable detail panel
            if (_showDetailSheet)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sheetAnimController,
                  builder: (context, child) {
                    final value = CurvedAnimation(
                      parent: _sheetAnimController,
                      curve: Curves.easeOutCubic,
                    ).value;
                    if (value <= 0) return const SizedBox.shrink();
                    return Opacity(opacity: value, child: child);
                  },
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      // Auto-dismiss when dragged below min extent
                      if (notification.extent <= notification.minExtent) {
                        _dismissDetailSheet();
                      }
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.45,
                      minChildSize: 0.1,
                      maxChildSize: 0.85,
                      snap: true,
                      snapSizes: const [0.45, 0.85],
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            border: Border(
                              top: BorderSide(
                                  color: _selectedOutlineColor, width: 2),
                              left: BorderSide(
                                  color: _selectedOutlineColor, width: 2),
                              right: BorderSide(
                                  color: _selectedOutlineColor, width: 2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedOutlineColor
                                    .withValues(alpha: 0.35),
                                blurRadius: 26,
                                spreadRadius: -2,
                                offset: const Offset(0, -4),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Drag handle — tinted to match the outline
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _dismissDetailSheet,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 40),
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _selectedOutlineColor
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              // Content — uses the DraggableScrollableSheet's controller
                              Expanded(
                                child: _buildSheetContentWithController(
                                    scrollController),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Floating pill showing the auto-recognized zone under the map center
/// (neighbourhood / city / country depending on zoom).
class _ZoneNamePill extends StatelessWidget {
  final String name;

  const _ZoneNamePill({required this.name});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(name),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mapPin,
                size: 14, color: AppColors.primaryLight),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static stand-in for the Mapbox canvas on platforms without a native map
/// (Windows/Linux/macOS dev runs). Keeps the rest of the screen functional.
class _DesktopMapPlaceholder extends StatelessWidget {
  const _DesktopMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDark,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.map,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Map preview is not available on desktop',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
