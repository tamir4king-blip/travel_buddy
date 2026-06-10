import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/core/router/app_router.dart';
import 'package:travel_buddy_mobile/shared/services/persistence_service.dart';
import 'package:travel_buddy_mobile/shared/services/notification_service.dart';
import 'package:travel_buddy_mobile/shared/services/background_service.dart';
import 'package:travel_buddy_mobile/shared/services/permission_service.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/notification_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/locale_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/nearby_achievements_provider.dart';

const _mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');
const _keyPermissionsRequested = 'permissions_requested';

/// Mapbox and the background service only have Android/iOS implementations.
/// On desktop (Windows dev runs) their platform channels are missing.
bool get _isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mapbox
  if (_isMobilePlatform) {
    MapboxOptions.setAccessToken(_mapboxToken);
  }

  // Initialize Supabase (only if credentials are provided)
  if (SupabaseConfig.supabaseUrl.isNotEmpty &&
      SupabaseConfig.supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      SupabaseConfig.initialized = true;
    } catch (e, st) {
      // Supabase init failed -- app will still work with local-only mode.
      // Sentry isn't initialised yet here, so this is debug-only.
      logError(e, st, context: 'supabase.init');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final persistenceService = PersistenceService(prefs);

  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize background service (creates notification channel)
  // but do NOT start it yet — permissions may not be granted
  if (_isMobilePlatform) {
    try {
      await BackgroundService.initialize();
    } catch (e, st) {
      // Non-fatal: service just won't be available. Sentry not yet initialised.
      logError(e, st, context: 'backgroundService.initialize');
    }
  }

  // Check if live tracking was enabled before app closed
  final shouldRestoreTracking = persistenceService.loadLiveTracking();

  await SentryFlutter.init(
    (options) {
      options.dsn = SupabaseConfig.sentryDsn;
      options.tracesSampleRate = 1.0;
      options.debug = false;
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(persistenceService),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: TravelBuddyApp(restoreTracking: shouldRestoreTracking),
      ),
    ),
  );
}

class TravelBuddyApp extends ConsumerStatefulWidget {
  final bool restoreTracking;
  const TravelBuddyApp({super.key, this.restoreTracking = false});

  @override
  ConsumerState<TravelBuddyApp> createState() => _TravelBuddyAppState();
}

class _TravelBuddyAppState extends ConsumerState<TravelBuddyApp>
    with WidgetsBindingObserver {
  bool _trackingRestored = false;
  bool _permissionsHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Run permission flow and tracking restore after the first frame
    // so the user sees the app UI before system dialogs appear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePermissionsAndTracking();
    });
  }

  Future<void> _handlePermissionsAndTracking() async {
    if (_permissionsHandled) return;
    _permissionsHandled = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionService = PermissionService();
      final alreadyRequested =
          prefs.getBool(_keyPermissionsRequested) ?? false;

      // First launch: request permissions sequentially with gating
      if (!alreadyRequested) {
        await permissionService.requestAllPermissions();
        await prefs.setBool(_keyPermissionsRequested, true);
      }

      // Start background service only if safe to do so
      if (_isMobilePlatform &&
          await permissionService.canStartBackgroundService()) {
        try {
          await BackgroundService.start();
        } catch (e, st) {
          // Service failed to start — non-fatal
          logError(e, st, context: 'backgroundService.start');
        }
      }
    } catch (e, st) {
      // Permission flow failed — app continues without background service.
      // Unexpected here, so surface it to Sentry.
      logError(e, st, context: 'permissionFlow', report: true);
    }

    // Restore live tracking if it was enabled before app closed
    if (widget.restoreTracking) {
      await _restoreTracking();
    } else {
      // Even without live tracking, fetch location once so the zone widget
      // knows the user's current area immediately on app launch
      await _fetchInitialLocation();
    }
  }

  Future<void> _fetchInitialLocation() async {
    final geoNotifier = ref.read(geolocationProvider.notifier);
    await geoNotifier.getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _restoreTracking() async {
    if (_trackingRestored) return;
    _trackingRestored = true;

    final geoNotifier = ref.read(geolocationProvider.notifier);
    await geoNotifier.startTracking();

    // Force the nearby achievements provider to initialize
    // so it starts checking proximity immediately
    ref.read(nearbyAchievementsProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app returns to foreground, sync pending claims from
    // the background service and re-check proximity
    if (state == AppLifecycleState.resumed) {
      ref.read(achievementsProvider.notifier).refreshFromStorage();

      final geo = ref.read(geolocationProvider);
      if (geo.isLiveTracking) {
        // Trigger a recomputation of nearby achievements
        ref.read(nearbyAchievementsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TravelBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
