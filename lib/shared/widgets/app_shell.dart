import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/activity_log/presentation/screens/activity_log_screen.dart';
import 'package:travel_buddy_mobile/features/home/presentation/widgets/home_map_sheet.dart';
import 'package:travel_buddy_mobile/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:travel_buddy_mobile/features/map/presentation/screens/map_screen.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/nearby_achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/proximity_alert.dart';

/// Map-first shell: the full-screen map IS the app. There is no bottom
/// navigation bar — destinations live in the [HomeMapSheet] menu sheet that
/// floats over the canvas. Non-map routes render as pages above the map with
/// a floating close button back to it.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {
  String? _alertAchievementId;

  // Map enter/exit crossfade (0 = page visible, 1 = map visible)
  late AnimationController _mapEnterController;

  // The last non-map tab page, kept rendered behind the crossfade.
  int _lastPageIndex = 0;

  static const _pageRoutes = ['/log', '/leaderboard', '/profile'];

  static const _pageWidgets = <Widget>[
    ActivityLogScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  // Single persistent MapScreen instance — mounted once and kept alive for
  // the whole session so its camera, zoom, and native view state survive
  // visiting other pages.
  static const Widget _persistentMap = MapScreen();

  @override
  void initState() {
    super.initState();
    _mapEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      // The app opens on the map — canvas fully visible from the first frame.
      value: 1.0,
    );
    _mapEnterController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mapEnterController.dispose();
    super.dispose();
  }

  /// IndexedStack for the main pages, or the GoRouter child for sub-routes.
  Widget _pageContent(String location) {
    final index = _pageRoutes.indexOf(location);
    if (index != -1 || location == '/' || location == '/map') {
      return IndexedStack(
        index: index != -1 ? index : _lastPageIndex,
        children: _pageWidgets,
      );
    }
    return widget.child;
  }

  @override
  Widget build(BuildContext context) {
    final geo = ref.watch(geolocationProvider);
    final nearbyState = ref.watch(nearbyAchievementsProvider);
    final location = GoRouterState.of(context).uri.path;
    // '/' is the map. '/map' stays as an alias for older deep links.
    final showCanvas = location == '/' || location == '/map';

    final pageIndex = _pageRoutes.indexOf(location);
    if (pageIndex != -1) _lastPageIndex = pageIndex;

    // Crossfade between the canvas and the page layer.
    if (showCanvas) {
      if (_mapEnterController.status != AnimationStatus.forward &&
          _mapEnterController.status != AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapEnterController.forward();
        });
      }
    } else {
      if (_mapEnterController.status != AnimationStatus.reverse &&
          _mapEnterController.status != AnimationStatus.dismissed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapEnterController.reverse();
        });
      }
    }

    // Listen for newly discovered achievements — show in-app alert banner.
    ref.listen(nearbyAchievementsProvider, (prev, next) {
      if (!geo.isLiveTracking) return;
      if (next.newlyDiscovered.isNotEmpty) {
        final achievement = next.newlyDiscovered.first;
        setState(() {
          _alertAchievementId = achievement.id;
        });

        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && _alertAchievementId == achievement.id) {
            setState(() => _alertAchievementId = null);
          }
        });
      }
    });

    final alertAchievement = _alertAchievementId != null
        ? nearbyState.nearby
            .where((a) => a.id == _alertAchievementId)
            .firstOrNull
        : null;

    // Map crossfade progress (0 = page visible, 1 = map visible).
    final mapEased = Curves.easeOutCubic.transform(_mapEnterController.value);

    // Transparent Material so every floating layer (menu sheet, alert banner,
    // close button) has a Material ancestor — Text without one renders with
    // the debug yellow/red underline decoration.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Page layer — log / rankings / profile / sub-routes.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: showCanvas,
              child: Opacity(
                opacity: 1 - mapEased,
                child: Material(
                  color: AppColors.bgDark,
                  child: _pageContent(location),
                ),
              ),
            ),
          ),

          // The living canvas — always mounted, the app's true home.
          IgnorePointer(
            ignoring: !showCanvas,
            child: Opacity(
              opacity: mapEased,
              child: Transform.scale(
                scale: 0.97 + 0.03 * mapEased,
                child: _persistentMap,
              ),
            ),
          ),

          // Menu sheet — dashboard + destinations, floats over the canvas.
          // Stays mounted (hidden) on other routes so its drag position and
          // the dashboard's state survive navigation.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !showCanvas,
              child: Opacity(
                opacity: showCanvas ? mapEased : 0.0,
                child: const HomeMapSheet(),
              ),
            ),
          ),

          // Floating close button — returns from any page to the map.
          if (!showCanvas)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    right: AppSpacing.lg,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/');
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgCardLight,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Proximity alert banner.
          if (alertAchievement != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ProximityAlert(
                    achievement: alertAchievement,
                    distance: geo.hasLocation
                        ? geo.distanceTo(alertAchievement.latitude!,
                            alertAchievement.longitude!)
                        : 0,
                    onClaim: () {
                      setState(() => _alertAchievementId = null);
                    },
                    onDismiss: () {
                      setState(() => _alertAchievementId = null);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
