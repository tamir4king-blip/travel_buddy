import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationState {
  final double? latitude;
  final double? longitude;
  final bool isTracking; // one-shot fetch in progress
  final bool isLiveTracking; // continuous stream active
  final bool hasPermission;
  final String? error;
  final bool isSpoofing;

  const GeolocationState({
    this.latitude,
    this.longitude,
    this.isTracking = false,
    this.isLiveTracking = false,
    this.hasPermission = false,
    this.error,
    this.isSpoofing = false,
  });

  bool get hasLocation => latitude != null && longitude != null;

  double distanceTo(double lat, double lng) {
    if (!hasLocation) return double.infinity;
    return Geolocator.distanceBetween(latitude!, longitude!, lat, lng);
  }

  GeolocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isTracking,
    bool? isLiveTracking,
    bool? hasPermission,
    String? error,
    bool? isSpoofing,
  }) {
    return GeolocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isTracking: isTracking ?? this.isTracking,
      isLiveTracking: isLiveTracking ?? this.isLiveTracking,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error ?? this.error,
      isSpoofing: isSpoofing ?? this.isSpoofing,
    );
  }
}

class GeolocationNotifier extends StateNotifier<GeolocationState> {
  GeolocationNotifier() : super(const GeolocationState());

  StreamSubscription<Position>? _positionSubscription;

  Future<void> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(error: 'Location services are disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(error: 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(error: 'Location permission permanently denied');
        return;
      }

      state = state.copyWith(hasPermission: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> getCurrentLocation() async {
    if (!state.hasPermission) await requestPermission();
    if (!state.hasPermission) return;

    try {
      state = state.copyWith(isTracking: true);
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        isTracking: false,
      );
    } catch (e) {
      state = state.copyWith(isTracking: false, error: e.toString());
    }
  }

  Future<void> startTracking() async {
    if (state.isLiveTracking) return;

    if (!state.hasPermission) await requestPermission();
    if (!state.hasPermission) return;

    // Use platform-specific settings for background location tracking
    final LocationSettings locationSettings;

    if (!kIsWeb && Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        // Keep tracking alive in the background with a foreground service
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Tracking your location for nearby trophies',
          notificationTitle: 'Travel Buddy',
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        ),
      );
    } else if (!kIsWeb && Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        state = state.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isLiveTracking: false,
          error: error.toString(),
        );
        _positionSubscription?.cancel();
        _positionSubscription = null;
      },
    );

    state = state.copyWith(isLiveTracking: true);
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    state = state.copyWith(isLiveTracking: false);
  }

  void enableSpoof(double lat, double lng) {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    state = GeolocationState(
      latitude: lat,
      longitude: lng,
      isTracking: false,
      isLiveTracking: true,
      hasPermission: true,
      isSpoofing: true,
    );
  }

  void updateSpoofedLocation(double lat, double lng) {
    if (!state.isSpoofing) return;
    state = state.copyWith(latitude: lat, longitude: lng);
  }

  void disableSpoof() {
    state = const GeolocationState();
  }

  bool isWithinRadius(double lat, double lng, double radiusMeters) {
    if (!state.hasLocation) return false;
    final distance = state.distanceTo(lat, lng);
    return distance <= radiusMeters;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final geolocationProvider =
    StateNotifierProvider<GeolocationNotifier, GeolocationState>(
  (ref) => GeolocationNotifier(),
);
