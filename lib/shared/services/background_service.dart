import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/utils/achievement_definitions_codec.dart';
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';

class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Creates the notification channel before the service starts.
  /// Required on Android 8+ and strictly enforced on Android 16.
  static Future<void> _ensureNotificationChannel() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      'gps_scanning',
      'GPS Scanning',
      description: 'Persistent notification while GPS is actively scanning for achievements',
      importance: Importance.low,
      showBadge: false,
    );
    await android.createNotificationChannel(channel);
  }

  static Future<void> initialize() async {
    await _ensureNotificationChannel();
    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: true,
        notificationChannelId: 'gps_scanning',
        initialNotificationTitle: 'Travel Bounty',
        initialNotificationContent: '\u{1F5FA}\uFE0F GPS active \u2014 scanning for achievements',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
    );
  }

  static Future<void> start() async {
    await _service.startService();
  }

  static Future<void> stop() async {
    _service.invoke('stop');
  }

  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}

// ── Background isolate entry points ──────────────────────────────────────────

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stop').listen((event) {
    service.stopSelf();
  });

  final checker = _ProximityChecker();
  await checker.init();

  Timer.periodic(const Duration(seconds: 15), (_) async {
    await checker.poll(service);
  });

  // Run immediately on start
  await checker.poll(service);
}

// ── Proximity checker (runs in background isolate) ───────────────────────────

/// Keys for SharedPreferences
const _keyPendingClaims = 'pending_claims';
const _keyNotifiedAchievements = 'bg_notified_achievements';
const _keyUnlockedAchievements = 'unlocked_achievements';

/// Minimum distance change (meters) to trigger a new proximity check.
const _minMovementMeters = 10.0;

/// Cooldown before re-notifying the same achievement (milliseconds).
const _notifyCooldownMs = 5 * 60 * 1000; // 5 minutes

class _ProximityChecker {
  late FlutterLocalNotificationsPlugin _notifications;
  late SharedPreferences _prefs;

  double? _lastLat;
  double? _lastLng;

  /// Pre-filter: only achievements that have coordinates and a claim radius.
  List<Achievement> _locationAchievements = const [];

  /// Cached Supabase definitions JSON that [_locationAchievements] was built
  /// from — rebuilt only when the main isolate writes a new cache.
  String? _definitionsSource;
  bool _definitionsLoaded = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _notifications = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    _refreshDefinitions();
  }

  /// Use the same definitions as the main isolate: hardcoded registry merged
  /// with the Supabase cache, so remote-only achievements and edited
  /// polygons/radii are detected in the background too.
  void _refreshDefinitions() {
    final cached = _prefs.getString(achievementDefinitionsCacheKey);
    if (_definitionsLoaded && cached == _definitionsSource) return;

    var definitions = achievementRegistry;
    if (cached != null) {
      try {
        definitions = mergeDefinitions(achievementRegistry, parseDefinitions(cached));
      } catch (e, st) {
        // Corrupted cache — fall back to the hardcoded registry.
        logError(e, st, context: 'backgroundService.loadDefinitions');
      }
    }

    _locationAchievements = definitions.where((a) => a.hasGeofence).toList();
    _definitionsSource = cached;
    _definitionsLoaded = true;
  }

  Future<void> poll(ServiceInstance service) async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      // Battery optimization: skip if hasn't moved > 10m
      if (_lastLat != null && _lastLng != null) {
        final moved = _haversineMeters(_lastLat!, _lastLng!, lat, lng);
        if (moved < _minMovementMeters) return;
      }

      _lastLat = lat;
      _lastLng = lng;

      // Reload SharedPreferences to pick up changes from the main isolate
      await _prefs.reload();
      _refreshDefinitions();

      // Load current state from SharedPreferences
      final unlockedData = _loadUnlockedData();
      final unlockedIds = unlockedData.keys.toSet();
      final pendingClaims = _loadPendingClaims();
      final notifiedMap = _loadNotifiedMap();

      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      int nearbyCount = 0;

      for (final achievement in _locationAchievements) {
        if (!isWithinClaimArea(lat, lng, achievement)) continue;

        if (unlockedIds.contains(achievement.id)) {
          // ── Revisit: already unlocked ──
          // Cooldown anchor: prefer lastVisitedAt, fall back to unlockedAt
          // so legacy unlocks (or dev-panel forceUnlock) still respect the
          // cooldown window.
          final data = unlockedData[achievement.id];
          final lastVisitedRaw = data?['lastVisitedAt'] as String?;
          final unlockedRaw = data?['unlockedAt'] as String?;
          DateTime? anchor;
          if (lastVisitedRaw != null) {
            anchor = DateTime.tryParse(lastVisitedRaw);
          }
          anchor ??= unlockedRaw != null ? DateTime.tryParse(unlockedRaw) : null;

          final cooldown = AchievementsNotifier.cooldownFor(achievement);
          if (anchor != null && now.difference(anchor) < cooldown) {
            continue;
          }

          // Cooldown passed — actually record the revisit into SharedPreferences
          // so the diary/timeline, visit count, and Supabase sync all reflect it.
          final currentCount = (data?['visitCount'] as int?) ?? 1;
          final newCount = currentCount + 1;
          final history = <String>[];
          final existingHistory = data?['revisitHistory'] as List<dynamic>?;
          if (existingHistory != null) {
            history.addAll(existingHistory.cast<String>());
          }
          history.add(now.toIso8601String());

          if (data != null) {
            data['visitCount'] = newCount;
            data['lastVisitedAt'] = now.toIso8601String();
            data['revisitHistory'] = history;
            data['isPendingRevisit'] = true;
            _saveUnlockedData(unlockedData);
          }

          // Fire revisit notification (with notification cooldown)
          final lastNotified = notifiedMap[achievement.id] ?? 0;
          if (nowMs - lastNotified > _notifyCooldownMs) {
            await _showRevisitNotification(achievement, newCount);
            notifiedMap[achievement.id] = nowMs;
          }
        } else {
          // ── First-time claim: not yet unlocked ──
          nearbyCount++;

          // Mark as pending claim
          if (!pendingClaims.containsKey(achievement.id)) {
            pendingClaims[achievement.id] = now.toIso8601String();
          }

          // Fire notification (with cooldown)
          final lastNotified = notifiedMap[achievement.id] ?? 0;
          if (nowMs - lastNotified > _notifyCooldownMs) {
            await _showAchievementNotification(achievement);
            notifiedMap[achievement.id] = nowMs;
          }
        }
      }

      // Persist updated state
      _savePendingClaims(pendingClaims);
      _saveNotifiedMap(notifiedMap);

      // Update the foreground notification body
      if (service is AndroidServiceInstance) {
        final body = nearbyCount > 0
            ? '\u{1F5FA}\uFE0F GPS active \u2014 $nearbyCount achievement${nearbyCount == 1 ? '' : 's'} nearby'
            : '\u{1F5FA}\uFE0F GPS active \u2014 scanning for achievements';
        service.setForegroundNotificationInfo(
          title: 'Travel Bounty',
          content: body,
        );
      }
    } catch (e, st) {
      // GPS timeout or error — skip this cycle
      logError(e, st, context: 'backgroundService.gpsCycle');
    }
  }

  // ── Notification ───────────────────────────────────────────────────────────

  Future<void> _showAchievementNotification(Achievement achievement) async {
    const androidDetails = AndroidNotificationDetails(
      'achievement_unlocked',
      'Achievement Alerts',
      channelDescription: 'Notifications when you unlock an achievement',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      achievement.id.hashCode,
      '\u{1F3C6} Achievement Unlocked!',
      '${achievement.title} \u2014 tap to claim',
      details,
    );
  }

  Future<void> _showRevisitNotification(
    Achievement achievement, int visitNumber,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'proximity_alerts',
      'Achievement Alerts',
      channelDescription: 'Notifications for achievement revisits',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      achievement.id.hashCode + 10000,
      'Revisit recorded: ${achievement.title}',
      'Visit #$visitNumber logged! Open the app to claim it.',
      details,
    );
  }

  // ── Haversine ──────────────────────────────────────────────────────────────

  static double _haversineMeters(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  // ── SharedPreferences helpers ──────────────────────────────────────────────

  /// Returns a map of achievement ID → its persisted JSON data (including
  /// lastVisitedAt, visitCount, etc.) so the background service can
  /// distinguish first-time claims from revisits and respect cooldowns.
  Map<String, Map<String, dynamic>> _loadUnlockedData() {
    final raw = _prefs.getString(_keyUnlockedAchievements);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final result = <String, Map<String, dynamic>>{};
      for (final e in list) {
        final map = e as Map<String, dynamic>;
        final id = map['id'] as String?;
        if (id != null) result[id] = map;
      }
      return result;
    } catch (e, st) {
      logError(e, st, context: 'backgroundService.loadUnlockedData');
      return {};
    }
  }

  /// Persists updated unlocked data back to SharedPreferences as a JSON list.
  /// The main isolate reads this on foreground resume to pick up background
  /// revisit counts.
  void _saveUnlockedData(Map<String, Map<String, dynamic>> data) {
    _prefs.setString(_keyUnlockedAchievements, jsonEncode(data.values.toList()));
  }

  Map<String, String> _loadPendingClaims() {
    final raw = _prefs.getString(_keyPendingClaims);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (e, st) {
      logError(e, st, context: 'backgroundService.loadPendingClaims');
      return {};
    }
  }

  void _savePendingClaims(Map<String, String> claims) {
    _prefs.setString(_keyPendingClaims, jsonEncode(claims));
  }

  Map<String, int> _loadNotifiedMap() {
    final raw = _prefs.getString(_keyNotifiedAchievements);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as int));
    } catch (e, st) {
      logError(e, st, context: 'backgroundService.loadNotifiedMap');
      return {};
    }
  }

  void _saveNotifiedMap(Map<String, int> map) {
    _prefs.setString(_keyNotifiedAchievements, jsonEncode(map));
  }
}
