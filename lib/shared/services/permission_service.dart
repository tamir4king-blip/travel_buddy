import 'package:permission_handler/permission_handler.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';

class PermissionService {
  /// Requests foreground location permission (while using the app).
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    } catch (e, st) {
      logError(e, st, context: 'permission.requestLocation');
      return false;
    }
  }

  /// Requests background location permission (allow all the time).
  /// Must be called after foreground location is already granted.
  /// Returns true if granted, false otherwise.
  Future<bool> requestBackgroundLocationPermission() async {
    try {
      // Don't request if foreground location isn't granted yet
      if (!await Permission.locationWhenInUse.isGranted) return false;
      final status = await Permission.locationAlways.request();
      return status.isGranted;
    } catch (e, st) {
      logError(e, st, context: 'permission.requestBackgroundLocation');
      return false;
    }
  }

  /// Requests notification permission (Android 13+).
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e, st) {
      logError(e, st, context: 'permission.requestNotification');
      return false;
    }
  }

  /// Runs the full permission flow sequentially with gating.
  /// Returns true if all permissions were granted.
  Future<bool> requestAllPermissions() async {
    // Step 1: Foreground location
    final locationGranted = await requestLocationPermission();
    if (!locationGranted) return false;

    // Step 2: Background location (only if foreground was granted)
    final backgroundGranted = await requestBackgroundLocationPermission();

    // Step 3: Notification permission
    final notificationGranted = await requestNotificationPermission();

    return locationGranted && backgroundGranted && notificationGranted;
  }

  /// Checks if location (foreground) and notification permissions are granted.
  /// These are the minimum required to safely start the background service.
  Future<bool> canStartBackgroundService() async {
    try {
      final location = await Permission.locationWhenInUse.isGranted;
      final notification = await Permission.notification.isGranted;
      return location && notification;
    } catch (e, st) {
      logError(e, st, context: 'permission.canStartBackgroundService');
      return false;
    }
  }

  /// Checks if all permissions (including background location) are granted.
  Future<bool> hasAllPermissions() async {
    try {
      final location = await Permission.locationWhenInUse.isGranted;
      final backgroundLocation = await Permission.locationAlways.isGranted;
      final notification = await Permission.notification.isGranted;
      return location && backgroundLocation && notification;
    } catch (e, st) {
      logError(e, st, context: 'permission.hasAllPermissions');
      return false;
    }
  }

  /// Opens the app settings page so the user can manually grant permissions.
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
