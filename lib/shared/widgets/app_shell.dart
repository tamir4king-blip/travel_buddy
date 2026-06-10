import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/activity_log/presentation/screens/activity_log_screen.dart';
import 'package:travel_buddy_mobile/features/home/presentation/widgets/home_map_sheet.dart';
import 'package:travel_buddy_mobile/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:travel_buddy_mobile/features/map/presentation/screens/map_screen.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_camera_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/nearby_achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/proximity_alert.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {
  String? _alertAchievementId;

  // Horizontal slide animation controller (0 = current page, ±1 = fully slid)
  late AnimationController _slideController;
  int? _slideTargetIndex; // The page index we're sliding towards
  bool _isSlideAnimating = false; // True when auto-animating after drag end

  // Nav bar hide/show animation for immersive map (0 = visible, 1 = hidden)
  late AnimationController _navBarHideController;
  bool _wasOnMap = false;

  // Map enter/exit crossfade (0 = tabs visible, 1 = map visible)
  late AnimationController _mapEnterController;
  bool _hasVisitedMap = false;
  // Tracks the most recently active tab so it stays rendered behind the
  // map fade — gives the crossfade something visible to fade into/out of.
  int _lastTabIndex = 0;

  // Double-tap detection for explore button
  DateTime? _lastExploreTapTime;

  // Horizontal swipe state
  int _previousIndex = 0;
  double _horizontalDragStart = 0;
  double _horizontalDragDelta = 0;
  bool _isHorizontalSwiping = false;

  static const _routes = ['/', '/log', '/leaderboard', '/profile'];

  static const _pageWidgets = <Widget>[
    // Home is not a page anymore — it renders as a draggable sheet over the
    // live map canvas (see the HomeMapSheet layer in build).
    SizedBox.shrink(),
    ActivityLogScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  // Single persistent MapScreen instance — mounted lazily on first visit and
  // kept alive across navigation so its camera, zoom, and native view state
  // survive switching to other tabs.
  static const Widget _persistentMap = MapScreen();

  /// Whether the current route is the map page.
  bool _isMapRoute(BuildContext context) {
    return GoRouterState.of(context).uri.path == '/map';
  }

  /// Returns IndexedStack for main tabs, last-active-tab IndexedStack while
  /// the map is being shown (so the crossfade has something to fade between),
  /// or the GoRouter child for sub-routes.
  /// Wraps content in MediaQuery.removePadding to prevent SafeArea from
  /// double-counting the bottom inset (already handled by the content area's
  /// bottom: navBarHeight + bottomInset positioning).
  Widget _pageContent(int selectedIndex) {
    final location = GoRouterState.of(context).uri.path;
    final Widget child;
    if (_routes.contains(location)) {
      child = IndexedStack(index: selectedIndex, children: _pageWidgets);
    } else if (location == '/map') {
      child = IndexedStack(index: _lastTabIndex, children: _pageWidgets);
    } else {
      child = widget.child;
    }
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideController.addListener(() => setState(() {}));
    _slideController.addStatusListener(_onSlideAnimationStatus);

    _navBarHideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _navBarHideController.addListener(() => setState(() {}));

    _mapEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _mapEnterController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _slideController.removeStatusListener(_onSlideAnimationStatus);
    _slideController.dispose();
    _navBarHideController.dispose();
    _mapEnterController.dispose();
    super.dispose();
  }

  void _onSlideAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isSlideAnimating) {
      _isSlideAnimating = false;
      if (_slideTargetIndex != null && mounted) {
        final targetIndex = _slideTargetIndex!;
        _slideTargetIndex = null;
        _slideController.value = 0;
        context.go(_routes[targetIndex]);
      } else {
        _slideTargetIndex = null;
      }
    }
  }

  /// Current slide offset as -1..+1.
  double get _slideOffset {
    if (_slideTargetIndex == null) return 0;
    final currentIndex = _previousIndex;
    if (_slideTargetIndex! > currentIndex) {
      return -_slideController.value;
    } else {
      return _slideController.value;
    }
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/log') return 1;
    if (location == '/leaderboard') return 2;
    if (location == '/profile') return 3;
    return 0;
  }

  /// Handles horizontal drag start.
  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isSlideAnimating) return;
    _horizontalDragStart = details.globalPosition.dx;
    _horizontalDragDelta = 0;
    _isHorizontalSwiping = false;
    _slideTargetIndex = null;
    _slideController.value = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, int currentIndex) {
    if (_isSlideAnimating) return;

    _horizontalDragDelta = details.globalPosition.dx - _horizontalDragStart;

    if (!_isHorizontalSwiping && _horizontalDragDelta.abs() > 10) {
      _isHorizontalSwiping = true;
    }

    if (_isHorizontalSwiping) {
      final sw = MediaQuery.of(context).size.width;
      final rawOffset = (_horizontalDragDelta / sw).clamp(-1.0, 1.0);

      int? target;
      if (rawOffset < 0 && currentIndex < _routes.length - 1) {
        target = currentIndex + 1;
      } else if (rawOffset > 0 && currentIndex > 0) {
        target = currentIndex - 1;
      }

      if (target != null) {
        _slideTargetIndex = target;
        _slideController.value = rawOffset.abs();
      } else {
        _slideTargetIndex = null;
        _slideController.value = rawOffset.abs() * 0.2;
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details, int currentIndex) {
    if (_isSlideAnimating || !_isHorizontalSwiping) {
      _isHorizontalSwiping = false;
      if (!_isSlideAnimating && _slideController.value > 0) {
        _slideTargetIndex = null;
        _isSlideAnimating = true;
        _slideController.animateTo(0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic);
      }
      return;
    }

    _isHorizontalSwiping = false;

    final velocity = details.primaryVelocity ?? 0;
    final progress = _slideController.value;
    final hasTarget = _slideTargetIndex != null;

    bool commit = false;
    if (hasTarget) {
      if (velocity.abs() > 300) {
        final slidingToNext = _slideTargetIndex! > currentIndex;
        commit = slidingToNext ? velocity < 0 : velocity > 0;
      } else {
        commit = progress > 0.35;
      }
    }

    _isSlideAnimating = true;

    if (commit && hasTarget) {
      HapticFeedback.selectionClick();
      final remainingFraction = 1.0 - progress;
      final duration = Duration(
        milliseconds: (remainingFraction * 250).round().clamp(100, 250),
      );
      _slideController.animateTo(1.0,
          duration: duration, curve: Curves.easeOutCubic);
    } else {
      _slideTargetIndex = null;
      final duration = Duration(
        milliseconds: (progress * 250).round().clamp(100, 250),
      );
      _slideController.animateTo(0,
          duration: duration, curve: Curves.easeOutCubic);
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (index < 0 || index >= _routes.length) return;

    // From the map page the slide-rendering path doesn't apply, so fall back
    // to an instant route change. The map already animates its own exit.
    if (_isMapRoute(context)) {
      _slideController.stop();
      _slideTargetIndex = null;
      _slideController.value = 0;
      _isSlideAnimating = false;
      context.go(_routes[index]);
      return;
    }

    final currentIndex = _currentIndex(context);
    if (index == currentIndex || _isSlideAnimating) return;

    HapticFeedback.selectionClick();

    // Drive the same slide animation used for swipe — completion triggers
    // the route change in [_onSlideAnimationStatus].
    _previousIndex = currentIndex;
    _slideTargetIndex = index;
    _slideController.value = 0;
    _isSlideAnimating = true;
    _slideController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onExploreTap(BuildContext context) {
    final isOnMap = _isMapRoute(context);

    if (!isOnMap) {
      // Not on map — navigate to it
      HapticFeedback.mediumImpact();
      _lastExploreTapTime = null;
      context.go('/map');
      return;
    }

    // Already on map — detect single vs double tap
    final now = DateTime.now();
    if (_lastExploreTapTime != null &&
        now.difference(_lastExploreTapTime!).inMilliseconds < 300) {
      // Double tap — zoom to globe
      _lastExploreTapTime = null;
      HapticFeedback.mediumImpact();
      ref.read(mapCameraCommandProvider.notifier).state =
          const ZoomToGlobeCommand();
    } else {
      // First tap — wait to see if a second tap follows
      _lastExploreTapTime = now;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_lastExploreTapTime == now && mounted) {
          // No second tap arrived — single tap: center on user
          _lastExploreTapTime = null;
          HapticFeedback.selectionClick();
          ref.read(mapCameraCommandProvider.notifier).state =
              const CenterOnUserCommand();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final geo = ref.watch(geolocationProvider);
    final nearbyState = ref.watch(nearbyAchievementsProvider);
    final selectedIndex = _currentIndex(context);
    final isOnMap = _isMapRoute(context);
    // Home shows the live map behind the dashboard sheet — both routes keep
    // the canvas visible and interactive.
    final isHome = GoRouterState.of(context).uri.path == '/';
    final showCanvas = isOnMap || isHome;

    // Tell MapScreen which face to wear: bare canvas under the home sheet,
    // or the full experience with chrome. Post-frame to avoid provider
    // writes during build; the GlobalKey inside MapScreen keeps the native
    // view alive across the switch.
    final wantBackdrop = isHome && !isOnMap;
    if (ref.read(mapBackdropProvider) != wantBackdrop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(mapBackdropProvider.notifier).state = wantBackdrop;
      });
    }
    // Nav bar: watch immersive state to hide/show
    final isImmersive = ref.watch(mapImmersiveProvider);
    // When leaving the map, always reset immersive mode
    if (!isOnMap && _wasOnMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(mapImmersiveProvider.notifier).state = false;
      });
    }
    // Sync nav bar animation with immersive state
    if (isImmersive && _navBarHideController.status != AnimationStatus.forward &&
        _navBarHideController.status != AnimationStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navBarHideController.forward();
      });
    } else if (!isImmersive && _navBarHideController.status != AnimationStatus.reverse &&
        _navBarHideController.status != AnimationStatus.dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navBarHideController.reverse();
      });
    }
    _wasOnMap = isOnMap;

    // Drive the map crossfade based on the current route (map page OR home
    // canvas — the map stays put when moving between the two).
    if (showCanvas) {
      _hasVisitedMap = true;
      if (_mapEnterController.status != AnimationStatus.forward &&
          _mapEnterController.status != AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapEnterController.forward();
        });
      }
    } else if (_hasVisitedMap) {
      if (_mapEnterController.status != AnimationStatus.reverse &&
          _mapEnterController.status != AnimationStatus.dismissed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapEnterController.reverse();
        });
      }
    }

    // Track previous index for horizontal swipe (only for tab pages)
    if (!isOnMap) {
      _previousIndex = selectedIndex;
      _lastTabIndex = selectedIndex;
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

    const navBarHeight = 68.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final bottomNav = _buildCustomNavBar(
      context: context,
      l10n: l10n,
      selectedIndex: selectedIndex,
      navBarHeight: navBarHeight,
      isOnMap: isOnMap,
    );

    final screenWidth = MediaQuery.of(context).size.width;

    // Compute slide translation for horizontal page swipe
    final slideOffset = _slideOffset;
    final slideTranslation = slideOffset * screenWidth;

    // Determine which adjacent page to show
    int? adjIndex;
    if (_slideTargetIndex != null && _slideController.value > 0) {
      adjIndex = _slideTargetIndex;
    }

    // Nav bar animation progress: 0 = visible, 1 = hidden
    final navHideProgress = Curves.easeOutCubic.transform(_navBarHideController.value);
    final contentBottom = (navBarHeight + bottomInset) * (1 - navHideProgress);
    final navBarBottom = -(navBarHeight + bottomInset) * navHideProgress;

    // Map crossfade progress (0 = tabs visible, 1 = map visible).
    final mapEased = Curves.easeOutCubic.transform(_mapEnterController.value);

    final body = Stack(
      children: [
        // Page content area
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: contentBottom,
          child: Stack(
            children: [
              // Tabs layer — always there, fades out as map fades in.
              Material(
                color: AppColors.bgDark,
                child: Opacity(
                  opacity: 1 - mapEased,
                  child: IgnorePointer(
                    ignoring: showCanvas,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: (details) {
                        _onHorizontalDragStart(details);
                      },
                      onHorizontalDragUpdate: (details) {
                        _onHorizontalDragUpdate(details, selectedIndex);
                      },
                      onHorizontalDragEnd: (details) {
                        _onHorizontalDragEnd(details, selectedIndex);
                      },
                      child: ClipRect(
                        child: Stack(
                          children: [
                            // Current page — slides with the finger
                            Transform.translate(
                              offset: Offset(slideTranslation, 0),
                              child: SizedBox(
                                width: screenWidth,
                                child: ScrollConfiguration(
                                  behavior: _ClampingScrollBehavior(),
                                  child: _pageContent(selectedIndex),
                                ),
                              ),
                            ),
                            // Adjacent page — slides in from the opposite edge
                            if (adjIndex != null)
                              Transform.translate(
                                offset: Offset(
                                  slideOffset > 0
                                      ? -screenWidth + slideTranslation
                                      : screenWidth + slideTranslation,
                                  0,
                                ),
                                child: SizedBox(
                                  width: screenWidth,
                                  height: double.infinity,
                                  child: Material(
                                    color: AppColors.bgDark,
                                    child: AbsorbPointer(
                                      child: _pageWidgets[adjIndex],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Persistent map layer — mounted lazily on first visit and kept
              // alive afterwards so its native view + camera survive
              // navigating to other tabs. Crossfades and slightly scales in
              // for a smoother enter/exit feel.
              if (_hasVisitedMap)
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

              // Home dashboard sheet — floats over the live canvas. Stays
              // mounted (hidden) on other routes so its drag position and
              // the dashboard's state survive tab switches.
              if (_hasVisitedMap)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !isHome,
                    child: Opacity(
                      opacity: isOnMap ? 0.0 : mapEased,
                      child: const HomeMapSheet(),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Bottom nav bar (slides down when map is immersive)
        Positioned(
          left: 0,
          right: 0,
          bottom: navBarBottom,
          height: navBarHeight + bottomInset,
          child: bottomNav,
        ),

        // Explore button — positioned independently for correct hit testing
        Positioned(
          left: 0,
          right: 0,
          bottom: navBarBottom + bottomInset + navBarHeight - 40,
          child: Center(
            child: _buildExploreButton(
                context, AppLocalizations.of(context)!, isOnMap),
          ),
        ),
      ],
    );

    // Transparent Material so every floating layer (home sheet, alert banner,
    // explore button, nav bar) has a Material ancestor — Text without one
    // renders with the debug yellow/red underline decoration.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          body,
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

  Widget _buildCustomNavBar({
    required BuildContext context,
    required AppLocalizations l10n,
    required int selectedIndex,
    required double navBarHeight,
    required bool isOnMap,
  }) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final leftTabs = [
      _NavTabData(LucideIcons.home, l10n.navHome, 0),
      _NavTabData(LucideIcons.bookOpen, l10n.navLog, 1),
    ];
    final rightTabs = [
      _NavTabData(LucideIcons.trophy, l10n.navRankings, 2),
      _NavTabData(LucideIcons.user, l10n.navProfile, 3),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: navBarHeight + bottomInset,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset,
          height: navBarHeight,
          child: Row(
            children: [
              ...leftTabs.map((tab) => Expanded(
                    child: _buildNavTab(
                      context: context,
                      icon: tab.icon,
                      label: tab.label,
                      index: tab.index,
                      selectedIndex: selectedIndex,
                      isOnMap: isOnMap,
                    ),
                  )),
              const Expanded(child: SizedBox()),
              ...rightTabs.map((tab) => Expanded(
                    child: _buildNavTab(
                      context: context,
                      icon: tab.icon,
                      label: tab.label,
                      index: tab.index,
                      selectedIndex: selectedIndex,
                      isOnMap: isOnMap,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavTab({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int selectedIndex,
    required bool isOnMap,
  }) {
    final isSelected = index == selectedIndex && !isOnMap;
    const duration = Duration(milliseconds: 250);
    const curve = Curves.easeOutCubic;
    final activeColor = AppColors.primaryLight;
    final inactiveColor = AppColors.textMuted.withValues(alpha: 0.6);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onDestinationSelected(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Selection indicator dot
          AnimatedContainer(
            duration: duration,
            curve: curve,
            width: isSelected ? 16 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          // Animated icon with scale
          TweenAnimationBuilder<double>(
            tween: Tween(end: isSelected ? 1.15 : 1.0),
            duration: duration,
            curve: curve,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? activeColor : inactiveColor,
              decoration: TextDecoration.none,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreButton(
      BuildContext context, AppLocalizations l10n, bool isOnMap) {
    const buttonSize = 56.0;
    const duration = Duration(milliseconds: 280);
    const curve = Curves.easeOutCubic;

    return GestureDetector(
      onTap: () => _onExploreTap(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: isOnMap ? 1.1 : 1.0),
            duration: duration,
            curve: curve,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: AnimatedContainer(
              duration: duration,
              curve: curve,
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isOnMap
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isOnMap ? null : AppColors.bgCardLight,
                boxShadow: isOnMap
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.globe,
                  key: ValueKey(isOnMap),
                  size: 26,
                  color: isOnMap ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isOnMap ? FontWeight.w600 : FontWeight.w400,
              color: isOnMap
                  ? AppColors.primaryLight
                  : AppColors.textMuted.withValues(alpha: 0.6),
              decoration: TextDecoration.none,
            ),
            child: Text(l10n.navExplore),
          ),
        ],
      ),
    );
  }
}

class _NavTabData {
  final IconData icon;
  final String label;
  final int index;
  const _NavTabData(this.icon, this.label, this.index);
}

class _ClampingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
