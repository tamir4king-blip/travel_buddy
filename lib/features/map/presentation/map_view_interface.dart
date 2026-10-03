import 'package:flutter/material.dart';
import 'package:travel_buddy_mobile/features/map/models/map_marker_item.dart';

/// Platform-agnostic map controller interface.
abstract class MapViewController {
  bool get isInitialized;
  void Function(String markerId, MapMarkerType type)? onMarkerClick;

  void flyTo(double lat, double lng, [double altitude = 2000]);
  void animateCamera(double lat, double lng, double zoom, {int durationMs = 1000});
  Future<({double lat, double lng, double zoom})?> getCameraState();
  void setMarkers(List<MapMarkerItem> markers);
  void setUserLocation(double lat, double lng);
  void resetCompass({int durationMs = 500});
  void zoomIn({int durationMs = 300});
  void zoomOut({int durationMs = 300});

  /// Convert geographic coordinates to screen pixel position.
  Future<({double x, double y})?> pixelForCoordinate(double lat, double lng);

  /// Callback for long-press on the map (lat, lng of the pressed point).
  void Function(double lat, double lng)? onMapLongPress;

  /// Callback for tap on an empty area of the map (lat, lng of the tapped point).
  void Function(double lat, double lng)? onMapClick;

  /// Callback fired on every camera change (pan, zoom, rotate).
  VoidCallback? onCameraChanged;

  /// Show a translucent circle on the map at the given coordinate with radius in meters.
  Future<void> showRadiusCircle(double lat, double lng, double radiusMeters, Color color);

  /// Show a translucent polygon on the map. [polygon] is [[lat, lng], ...].
  Future<void> showClaimPolygon(List<List<double>> polygon, Color color);

  /// Remove the radius circle / claim polygon from the map.
  Future<void> clearRadiusCircle();

  /// Highlight a marker as "selected" — renders a small black arrow above
  /// the pin. Pass null to clear.
  void setSelectedMarker(String? markerId);

  /// Render multiple polygon overlays simultaneously (persistent — not wiped
  /// by showRadiusCircle/showClaimPolygon). Used for the "show all unlocked
  /// areas" map filter. Each entry is `(polygon [[lat,lng],...], color)`.
  Future<void> showUnlockedAreasOverlay(
      List<({List<List<double>> polygon, Color color})> areas);

  /// Remove the unlocked-areas overlay.
  Future<void> clearUnlockedAreasOverlay();

  /// Cover the world in a dark "fog of war", with holes punched where the
  /// user has unlocked content. [polygons] are explicit hole rings
  /// (`[[lat,lng], ...]`); [circles] are radius-based holes around a point.
  Future<void> setFogOfWar({
    required List<List<List<double>>> polygons,
    required List<({double lat, double lng, double radius})> circles,
  });

  /// Remove the fog-of-war overlay entirely.
  Future<void> clearFogOfWar();

  /// Highlight an administrative zone (the "hover" boundary) — translucent
  /// fill + glowing border. [rings] are outer rings as `[[lat,lng],...]`,
  /// one per polygon part.
  Future<void> setZoneHighlight(List<List<List<double>>> rings);

  /// Remove the zone-hover highlight.
  Future<void> clearZoneHighlight();

  void dispose();
}

/// Platform-agnostic map view widget interface.
abstract class PlatformMapView extends StatefulWidget {
  const PlatformMapView({super.key});
}
