import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/features/map/models/map_marker_item.dart';
import 'package:travel_buddy_mobile/features/map/presentation/map_view_interface.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Layer / source ids. Markers and fog are rendered as *style layers* fed by
// GeoJSON sources (not point annotations): the Mapbox engine then handles
// clustering, zoom-interpolated sizing and hit-testing natively, which keeps
// hundreds of pins smooth.
// ─────────────────────────────────────────────────────────────────────────────
const _kMarkerSourceId = 'tb-markers';
const _kPinLayerId = 'tb-marker-pins';
const _kClusterGlowLayerId = 'tb-cluster-glow';
const _kClusterCoreLayerId = 'tb-cluster-core';
const _kClusterCountLayerId = 'tb-cluster-count';
const _kFogSourceId = 'tb-fog';
const _kFogLayerId = 'tb-fog-fill';
const _kFogEdgeSourceId = 'tb-fog-edge';
const _kFogEdgeLayerId = 'tb-fog-edge-glow';
const _kZoneSourceId = 'tb-zone-hover';
const _kZoneFillLayerId = 'tb-zone-hover-fill';
const _kZoneLineLayerId = 'tb-zone-hover-line';

const _kEmptyFeatureCollection = '{"type":"FeatureCollection","features":[]}';

/// How dark the unexplored world is. 0 disables the effect visually.
const _kFogOpacity = 0.55;

/// Mobile map controller using Mapbox Maps SDK.
class PlatformMapController extends MapViewController {
  MapboxMap? _mapboxMap;
  bool _initialized = false;

  // Current state for rebuilds
  List<MapMarkerItem> _markers = [];
  double? _userLat;
  double? _userLng;
  VoidCallback? onStateChanged;

  // Fog-of-war hole data (kept so it can be pushed once layers exist).
  List<List<List<double>>> _fogPolygons = const [];
  List<({double lat, double lng, double radius})> _fogCircles = const [];
  bool _fogDirty = false;
  bool _layersReady = false;

  // Zone-hover highlight rings (kept so they can be pushed once layers exist).
  List<List<List<double>>> _zoneRings = const [];
  bool _zoneDirty = false;

  // Radius circle / single-polygon preview (cleared on each new selection)
  PolygonAnnotationManager? _radiusManager;

  // Persistent overlay for "show all unlocked areas" toggle (independent from
  // the radius preview — doesn't get wiped by pin taps).
  PolygonAnnotationManager? _unlockedAreasManager;

  // Currently-selected marker (tapped) — re-renders its pin with the black
  // arrow indicator via a `selected` feature property.
  String? _selectedMarkerId;
  void Function(String? newId, String? previousId)? _onSelectionChanged;

  @override
  void setSelectedMarker(String? markerId) {
    if (_selectedMarkerId == markerId) return;
    final previous = _selectedMarkerId;
    _selectedMarkerId = markerId;
    _onSelectionChanged?.call(markerId, previous);
  }

  @override
  bool get isInitialized => _initialized;

  @override
  void Function(String markerId, MapMarkerType type)? onMarkerClick;

  @override
  void Function(double lat, double lng)? onMapLongPress;

  @override
  void Function(double lat, double lng)? onMapClick;

  @override
  VoidCallback? onCameraChanged;

  List<MapMarkerItem> get markers => _markers;
  double? get userLat => _userLat;
  double? get userLng => _userLng;

  void attachMap(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _initialized = true;
  }

  /// Called by the widget once the style has loaded and all sources/layers
  /// have been created — fog data set before that point is flushed here.
  Future<void> markLayersReady() async {
    _layersReady = true;
    if (_fogDirty) await _pushFog();
    if (_zoneDirty) await _pushZoneHighlight();
  }

  @override
  void flyTo(double lat, double lng, [double altitude = 2000]) {
    if (!_initialized || _mapboxMap == null) return;
    // Close fly-ins get a cinematic tilt; wider ones stay top-down.
    final close = altitude < 3000;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: close ? 14.5 : 12.0,
        pitch: close ? 40.0 : 0.0,
      ),
      MapAnimationOptions(duration: 1400),
    );
  }

  @override
  void animateCamera(double lat, double lng, double zoom, {int durationMs = 1000}) {
    if (!_initialized || _mapboxMap == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: durationMs),
    );
  }

  /// Glide the camera to a point without changing zoom — used when a pin is
  /// tapped so the map answers the touch (Zenly-style) instead of sitting
  /// still under the popup.
  Future<void> easeToPoint(double lat, double lng, {int durationMs = 600}) async {
    if (!_initialized || _mapboxMap == null) return;
    await _mapboxMap!.easeTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat))),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  Future<({double lat, double lng, double zoom})?> getCameraState() async {
    if (!_initialized || _mapboxMap == null) return null;
    final state = await _mapboxMap!.getCameraState();
    final center = state.center.coordinates;
    return (lat: center.lat.toDouble(), lng: center.lng.toDouble(), zoom: state.zoom);
  }

  @override
  void setMarkers(List<MapMarkerItem> markers) {
    _markers = markers;
    onStateChanged?.call();
  }

  @override
  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    onStateChanged?.call();
  }

  @override
  Future<({double x, double y})?> pixelForCoordinate(double lat, double lng) async {
    if (!_initialized || _mapboxMap == null) return null;
    final screen = await _mapboxMap!.pixelForCoordinate(
      Point(coordinates: Position(lng, lat)),
    );
    return (x: screen.x, y: screen.y);
  }

  @override
  void resetCompass({int durationMs = 500}) {
    if (!_initialized || _mapboxMap == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(bearing: 0, pitch: 0),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  void zoomIn({int durationMs = 300}) async {
    if (!_initialized || _mapboxMap == null) return;
    final state = await _mapboxMap!.getCameraState();
    final newZoom = (state.zoom + 1).clamp(0.0, 22.0);
    _mapboxMap!.flyTo(
      CameraOptions(zoom: newZoom),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  void zoomOut({int durationMs = 300}) async {
    if (!_initialized || _mapboxMap == null) return;
    final state = await _mapboxMap!.getCameraState();
    final newZoom = (state.zoom - 1).clamp(0.0, 22.0);
    _mapboxMap!.flyTo(
      // Flatten the tilt as the user pulls away — keeps the wide view
      // readable and lets the globe appear level at low zooms.
      CameraOptions(zoom: newZoom, pitch: newZoom < 9 ? 0 : null),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  Future<void> showRadiusCircle(double lat, double lng, double radiusMeters, Color color) async {
    if (!_initialized || _mapboxMap == null) return;
    await clearRadiusCircle();

    _radiusManager = await _mapboxMap!.annotations.createPolygonAnnotationManager();
    final points = geoCircle(lat, lng, radiusMeters, 64);
    await _radiusManager!.create(PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [points.map((p) => Position(p.$2, p.$1)).toList()]),
      fillColor: _colorToArgbInt(color.withValues(alpha: 0.2)),
      fillOutlineColor: _colorToArgbInt(color),
      fillOpacity: 1.0,
    ));
  }

  @override
  Future<void> showClaimPolygon(List<List<double>> polygon, Color color) async {
    if (!_initialized || _mapboxMap == null) return;
    if (polygon.length < 3) return;
    await clearRadiusCircle();

    _radiusManager = await _mapboxMap!.annotations.createPolygonAnnotationManager();
    final positions = polygon.map((p) => Position(p[1], p[0])).toList();
    // Close the ring if not already closed
    if (positions.first.lng != positions.last.lng ||
        positions.first.lat != positions.last.lat) {
      positions.add(positions.first);
    }
    await _radiusManager!.create(PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [positions]),
      fillColor: _colorToArgbInt(color.withValues(alpha: 0.55)),
      fillOutlineColor: _colorToArgbInt(color),
      fillOpacity: 1.0,
    ));
  }

  @override
  Future<void> clearRadiusCircle() async {
    if (_radiusManager != null) {
      await _radiusManager!.deleteAll();
      _radiusManager = null;
    }
  }

  @override
  Future<void> showUnlockedAreasOverlay(
      List<({List<List<double>> polygon, Color color})> areas) async {
    if (!_initialized || _mapboxMap == null) return;
    await clearUnlockedAreasOverlay();
    if (areas.isEmpty) return;

    _unlockedAreasManager =
        await _mapboxMap!.annotations.createPolygonAnnotationManager();

    for (final a in areas) {
      if (a.polygon.length < 3) continue;
      final positions = a.polygon.map((p) => Position(p[1], p[0])).toList();
      if (positions.first.lng != positions.last.lng ||
          positions.first.lat != positions.last.lat) {
        positions.add(positions.first);
      }
      await _unlockedAreasManager!.create(PolygonAnnotationOptions(
        geometry: Polygon(coordinates: [positions]),
        fillColor: _colorToArgbInt(a.color.withValues(alpha: 0.55)),
        fillOutlineColor: _colorToArgbInt(a.color),
        fillOpacity: 1.0,
      ));
    }
  }

  @override
  Future<void> clearUnlockedAreasOverlay() async {
    if (_unlockedAreasManager != null) {
      await _unlockedAreasManager!.deleteAll();
      _unlockedAreasManager = null;
    }
  }

  // ── Fog of war ────────────────────────────────────────────────────────────

  @override
  Future<void> setFogOfWar({
    required List<List<List<double>>> polygons,
    required List<({double lat, double lng, double radius})> circles,
  }) async {
    _fogPolygons = polygons;
    _fogCircles = circles;
    _fogDirty = true;
    if (_layersReady) await _pushFog();
  }

  @override
  Future<void> clearFogOfWar() async {
    _fogPolygons = const [];
    _fogCircles = const [];
    _fogDirty = true;
    if (!_layersReady || _mapboxMap == null) return;
    _fogDirty = false;
    try {
      await _mapboxMap!.style
          .setStyleSourceProperty(_kFogSourceId, 'data', _kEmptyFeatureCollection);
      await _mapboxMap!.style
          .setStyleSourceProperty(_kFogEdgeSourceId, 'data', _kEmptyFeatureCollection);
    } catch (e, st) {
      logError(e, st, context: 'map.clearFog');
    }
  }

  /// Build the fog polygon (world rectangle + one interior ring per unlocked
  /// area) and the matching glow outlines, then push both sources.
  Future<void> _pushFog() async {
    final map = _mapboxMap;
    if (map == null) return;
    _fogDirty = false;

    // Hole rings in GeoJSON order ([lng, lat]).
    final holes = <List<List<double>>>[];
    for (final ring in _fogPolygons) {
      if (ring.length < 3) continue;
      final coords = ring.map((p) => [p[1], p[0]]).toList();
      if (coords.first[0] != coords.last[0] || coords.first[1] != coords.last[1]) {
        coords.add(coords.first);
      }
      holes.add(coords);
    }
    for (final c in _fogCircles) {
      holes.add(geoCircle(c.lat, c.lng, c.radius, 48)
          .map((p) => [p.$2, p.$1])
          .toList());
    }

    // World-covering outer ring. Latitude is clamped short of the poles so
    // the rectangle stays valid in both mercator and globe projections.
    const world = [
      [-180.0, -85.0],
      [180.0, -85.0],
      [180.0, 85.0],
      [-180.0, 85.0],
      [-180.0, -85.0],
    ];

    final fog = jsonEncode({
      'type': 'Feature',
      'properties': <String, dynamic>{},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [world, ...holes],
      },
    });

    // The teal "discovered edge" glow gets its own source so the world
    // rectangle's border isn't outlined too.
    final edges = jsonEncode({
      'type': 'Feature',
      'properties': <String, dynamic>{},
      'geometry': {
        'type': 'MultiLineString',
        'coordinates': holes,
      },
    });

    try {
      await map.style.setStyleSourceProperty(_kFogSourceId, 'data', fog);
      await map.style.setStyleSourceProperty(_kFogEdgeSourceId, 'data', edges);
    } catch (e, st) {
      logError(e, st, context: 'map.pushFog');
    }
  }

  // ── Zone-hover highlight ──────────────────────────────────────────────────

  @override
  Future<void> setZoneHighlight(List<List<List<double>>> rings) async {
    _zoneRings = rings;
    _zoneDirty = true;
    if (_layersReady) await _pushZoneHighlight();
  }

  @override
  Future<void> clearZoneHighlight() async {
    if (_zoneRings.isEmpty && !_zoneDirty) return;
    _zoneRings = const [];
    _zoneDirty = true;
    if (_layersReady) await _pushZoneHighlight();
  }

  Future<void> _pushZoneHighlight() async {
    final map = _mapboxMap;
    if (map == null) return;
    _zoneDirty = false;

    String data;
    if (_zoneRings.isEmpty) {
      data = _kEmptyFeatureCollection;
    } else {
      // One MultiPolygon feature; rings arrive as [[lat,lng],...] and GeoJSON
      // wants closed [lng,lat] rings.
      final polygons = <List<List<List<double>>>>[];
      for (final ring in _zoneRings) {
        if (ring.length < 3) continue;
        final coords = ring.map((p) => [p[1], p[0]]).toList();
        if (coords.first[0] != coords.last[0] ||
            coords.first[1] != coords.last[1]) {
          coords.add(coords.first);
        }
        polygons.add([coords]);
      }
      data = jsonEncode({
        'type': 'Feature',
        'properties': <String, dynamic>{},
        'geometry': {
          'type': 'MultiPolygon',
          'coordinates': polygons,
        },
      });
    }

    try {
      await map.style.setStyleSourceProperty(_kZoneSourceId, 'data', data);
    } catch (e, st) {
      logError(e, st, context: 'map.pushZoneHighlight');
    }
  }

  /// Generate geo-circle points (lat, lng) around a center.
  static List<(double, double)> geoCircle(double lat, double lng, double radiusM, int segments) {
    const earthRadius = 6371000.0;
    final latRad = lat * math.pi / 180;
    final lngRad = lng * math.pi / 180;
    final d = radiusM / earthRadius;
    final points = <(double, double)>[];
    for (var i = 0; i <= segments; i++) {
      final bearing = 2 * math.pi * i / segments;
      final pLat = math.asin(
        math.sin(latRad) * math.cos(d) + math.cos(latRad) * math.sin(d) * math.cos(bearing),
      );
      final pLng = lngRad + math.atan2(
        math.sin(bearing) * math.sin(d) * math.cos(latRad),
        math.cos(d) - math.sin(latRad) * math.sin(pLat),
      );
      points.add((pLat * 180 / math.pi, pLng * 180 / math.pi));
    }
    return points;
  }

  @override
  void dispose() {
    _radiusManager = null;
    _unlockedAreasManager = null;
    _mapboxMap = null;
  }
}

/// Creates a [PlatformMapController] (mobile implementation).
PlatformMapController createMapController({required String token}) {
  return PlatformMapController();
}

/// Renders a map pin as PNG bytes: tier-colored stroke around a category
/// icon, with an optional black upward arrow above when [selected].
Future<Uint8List> _renderMarkerIcon({
  required Color tierColor,
  required IconData icon,
  required bool locked,
  required bool selected,
  int size = 96,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Reserve top space for the selection arrow
  final arrowBaseY = size * 0.18;
  final circleCenter = Offset(size / 2, size * 0.55);
  final circleRadius = size * 0.3;

  // 1) Selection arrow (small black upward triangle) — above the circle
  if (selected) {
    final tipY = size * 0.03;
    final arrowPath = Path()
      ..moveTo(size / 2 - size * 0.09, arrowBaseY)
      ..lineTo(size / 2, tipY)
      ..lineTo(size / 2 + size * 0.09, arrowBaseY)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = Colors.black);
  }

  // 2) Drop shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  canvas.drawCircle(
      circleCenter.translate(0, 2), circleRadius, shadowPaint);

  // 3) Circle fill — muted for locked, light-tinted for unlocked
  final fillColor = locked
      ? const Color(0xFF2A2A2A)
      : Color.lerp(Colors.white, tierColor, 0.1) ?? Colors.white;
  canvas.drawCircle(circleCenter, circleRadius, Paint()..color = fillColor);

  // 4) Tier-colored stroke
  canvas.drawCircle(
    circleCenter,
    circleRadius,
    Paint()
      ..color = tierColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.075,
  );

  // 5) Category icon in the middle
  final iconColor = locked ? tierColor.withValues(alpha: 0.85) : tierColor;
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: circleRadius * 1.2,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      circleCenter.dx - textPainter.width / 2,
      circleCenter.dy - textPainter.height / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// Converts a [Color] to an ARGB int for the Mapbox SDK.
int _colorToArgbInt(Color c) {
  return (c.a * 255).round() << 24 |
      (c.r * 255).round() << 16 |
      (c.g * 255).round() << 8 |
      (c.b * 255).round();
}

/// Mobile map view using Mapbox Maps SDK with native vector tiles.
class PlatformMapViewWidget extends StatefulWidget {
  final PlatformMapController controller;
  final VoidCallback? onMapReady;

  const PlatformMapViewWidget({super.key, required this.controller, this.onMapReady});

  @override
  State<PlatformMapViewWidget> createState() => _PlatformMapViewWidgetState();
}

class _PlatformMapViewWidgetState extends State<PlatformMapViewWidget> {
  MapboxMap? _map;
  bool _layersReady = false;
  bool _syncing = false;
  bool _resyncQueued = false;

  /// Style-image ids already registered with the map, so each distinct pin
  /// look (color × icon × locked × selected) is rasterized exactly once.
  final Set<String> _registeredIcons = {};

  /// Signature of the last pushed feature set (marker ids + selection) so
  /// unchanged updates skip the JSON re-encode entirely.
  String? _lastFeatureSignature;

  @override
  void initState() {
    super.initState();
    widget.controller.onStateChanged = () {
      if (mounted) _syncMarkers();
    };
    widget.controller._onSelectionChanged = (_, __) {
      if (mounted) _syncMarkers();
    };
  }

  // ── Style setup ───────────────────────────────────────────────────────────

  void _onMapCreated(MapboxMap mapboxMap) async {
    _map = mapboxMap;
    widget.controller.attachMap(mapboxMap);

    // No rotation (always north-up) and no pitch *gestures* — the camera
    // still pitches programmatically for cinematic fly-ins.
    await mapboxMap.gestures.updateSettings(GesturesSettings(
      rotateEnabled: false,
      pitchEnabled: false,
      simultaneousRotateAndPinchToZoomEnabled: false,
    ));

    // Enable user location puck
    await mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
      pulsingColor: _colorToArgbInt(AppColors.info),
    ));

    widget.onMapReady?.call();
  }

  void _onStyleLoaded(StyleLoadedEventData data) async {
    final map = _map;
    if (map == null) return;
    try {
      await _applyBrandStyle(map);
      await _createFogLayers(map);
      await _createZoneHighlightLayers(map);
      await _createMarkerLayers(map);
      _layersReady = true;
      await widget.controller.markLayersReady();
      await _syncMarkers();
    } catch (e, st) {
      logError(e, st, context: 'map.styleSetup', report: true);
    }
  }

  /// Tint the stock dark style toward the app palette and switch the
  /// projection to a globe so zooming out lands on a planet, not a wall map.
  Future<void> _applyBrandStyle(MapboxMap map) async {
    try {
      await map.style
          .setProjection(StyleProjection(name: StyleProjectionName.globe));
    } catch (e, st) {
      logError(e, st, context: 'map.setProjection');
    }

    // Best-effort recolors — layer ids vary between style versions, so each
    // tweak is independent and non-fatal.
    Future<void> tryPaint(String layerId, String property, String value) async {
      try {
        if (await map.style.styleLayerExists(layerId)) {
          await map.style.setStyleLayerProperty(layerId, property, value);
        }
      } catch (_) {
        // Layer/property not present in this style — skip.
      }
    }

    await tryPaint('water', 'fill-color', '"#0E2438"');
    await tryPaint('land', 'background-color', '"#0B1120"');
    await tryPaint('background', 'background-color', '"#0B1120"');
  }

  Future<void> _createFogLayers(MapboxMap map) async {
    await map.style.addSource(GeoJsonSource(
      id: _kFogSourceId,
      data: _kEmptyFeatureCollection,
    ));
    await map.style.addSource(GeoJsonSource(
      id: _kFogEdgeSourceId,
      data: _kEmptyFeatureCollection,
    ));

    await map.style.addLayer(FillLayer(
      id: _kFogLayerId,
      sourceId: _kFogSourceId,
      fillColor: _colorToArgbInt(AppColors.bgDark),
      fillOpacity: _kFogOpacity,
      fillAntialias: true,
    ));

    // Soft teal glow along the border between explored and unexplored.
    await map.style.addLayer(LineLayer(
      id: _kFogEdgeLayerId,
      sourceId: _kFogEdgeSourceId,
      lineColor: _colorToArgbInt(AppColors.primaryLight),
      lineWidth: 1.6,
      lineBlur: 4.0,
      lineOpacity: 0.7,
    ));
  }

  /// Zone-hover highlight — sits above the fog (the inspected zone should
  /// stay visible even in unexplored areas) and below the markers.
  Future<void> _createZoneHighlightLayers(MapboxMap map) async {
    await map.style.addSource(GeoJsonSource(
      id: _kZoneSourceId,
      data: _kEmptyFeatureCollection,
    ));

    await map.style.addLayer(FillLayer(
      id: _kZoneFillLayerId,
      sourceId: _kZoneSourceId,
      fillColor: _colorToArgbInt(AppColors.primary),
      fillOpacity: 0.10,
      fillAntialias: true,
    ));

    await map.style.addLayer(LineLayer(
      id: _kZoneLineLayerId,
      sourceId: _kZoneSourceId,
      lineColor: _colorToArgbInt(AppColors.primaryLight),
      lineWidth: 2.0,
      lineBlur: 2.5,
      lineOpacity: 0.9,
    ));
  }

  Future<void> _createMarkerLayers(MapboxMap map) async {
    await map.style.addSource(GeoJsonSource(
      id: _kMarkerSourceId,
      data: _kEmptyFeatureCollection,
      cluster: true,
      clusterRadius: 55,
      clusterMaxZoom: 13,
    ));

    // Halo behind cluster bubbles.
    await map.style.addLayer(CircleLayer(
      id: _kClusterGlowLayerId,
      sourceId: _kMarkerSourceId,
      filter: ['has', 'point_count'],
      circleColor: _colorToArgbInt(AppColors.primary),
      circleOpacity: 0.22,
      circleBlur: 0.7,
      circleRadiusExpression: [
        'step', ['get', 'point_count'],
        24, 25, 30, 100, 38,
      ],
    ));

    // Cluster bubble.
    await map.style.addLayer(CircleLayer(
      id: _kClusterCoreLayerId,
      sourceId: _kMarkerSourceId,
      filter: ['has', 'point_count'],
      circleColor: _colorToArgbInt(AppColors.primary),
      circleStrokeColor: _colorToArgbInt(AppColors.primaryLight),
      circleStrokeWidth: 1.5,
      circleRadiusExpression: [
        'step', ['get', 'point_count'],
        15, 25, 19, 100, 25,
      ],
    ));

    // Cluster count label.
    await map.style.addLayer(SymbolLayer(
      id: _kClusterCountLayerId,
      sourceId: _kMarkerSourceId,
      filter: ['has', 'point_count'],
      textFieldExpression: ['get', 'point_count_abbreviated'],
      textFont: ['DIN Pro Medium', 'Arial Unicode MS Regular'],
      textSize: 13,
      textColor: _colorToArgbInt(Colors.white),
      textAllowOverlap: true,
      textIgnorePlacement: true,
    ));

    // Individual pins — icon image chosen per-feature, sized by zoom so pins
    // gently grow as you approach street level (selected pins run larger).
    await map.style.addLayer(SymbolLayer(
      id: _kPinLayerId,
      sourceId: _kMarkerSourceId,
      filter: [
        '!', ['has', 'point_count'],
      ],
      iconImageExpression: ['get', 'icon'],
      iconAllowOverlap: true,
      iconIgnorePlacement: true,
      iconSizeExpression: [
        'interpolate', ['linear'], ['zoom'],
        3, ['case', ['==', ['get', 'selected'], 1], 0.36, 0.28],
        10, ['case', ['==', ['get', 'selected'], 1], 0.52, 0.42],
        16, ['case', ['==', ['get', 'selected'], 1], 0.64, 0.52],
      ],
    ));
  }

  // ── Marker sync ───────────────────────────────────────────────────────────

  String _iconKey(MapMarkerItem item, bool selected) {
    return 'tb-pin-${item.pinColor.toARGB32()}-${item.iconData.codePoint}-'
        '${item.isLocked ? 1 : 0}-${selected ? 1 : 0}';
  }

  Future<void> _ensureIconRegistered(MapMarkerItem item, bool selected) async {
    final map = _map;
    if (map == null) return;
    final key = _iconKey(item, selected);
    if (_registeredIcons.contains(key)) return;

    final png = await _renderMarkerIcon(
      tierColor: item.pinColor,
      icon: item.iconData,
      locked: item.isLocked,
      selected: selected,
    );
    await map.style.addStyleImage(
      key,
      1.0,
      MbxImage(width: 96, height: 96, data: png),
      false,
      const [],
      const [],
      null,
    );
    _registeredIcons.add(key);
  }

  /// Push the current marker list into the GeoJSON source. The Mapbox engine
  /// takes it from there (clustering, layout, rendering) — no per-annotation
  /// bookkeeping.
  Future<void> _syncMarkers() async {
    final map = _map;
    if (map == null || !_layersReady) return;
    if (_syncing) {
      _resyncQueued = true;
      return;
    }
    _syncing = true;

    try {
      final items = widget.controller.markers;
      final selectedId = widget.controller._selectedMarkerId;

      final signature = StringBuffer()..write(selectedId ?? '');
      for (final m in items) {
        signature.write('|${m.hashCode}');
      }
      final sig = signature.toString();
      if (sig == _lastFeatureSignature) return;

      final features = <Map<String, dynamic>>[];
      for (final item in items) {
        final selected = item.id == selectedId;
        await _ensureIconRegistered(item, selected);
        features.add({
          'type': 'Feature',
          'id': item.id.hashCode,
          'properties': {
            'id': item.id,
            'type': item.type.name,
            'icon': _iconKey(item, selected),
            'selected': selected ? 1 : 0,
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [item.longitude, item.latitude],
          },
        });
      }

      await map.style.setStyleSourceProperty(
        _kMarkerSourceId,
        'data',
        jsonEncode({'type': 'FeatureCollection', 'features': features}),
      );
      _lastFeatureSignature = sig;
    } catch (e, st) {
      logError(e, st, context: 'map.syncMarkers', report: true);
    } finally {
      _syncing = false;
      if (_resyncQueued) {
        _resyncQueued = false;
        Future.microtask(_syncMarkers);
      }
    }
  }

  // ── Tap routing ───────────────────────────────────────────────────────────

  /// Hit-test pins and clusters around the touch point. Clusters zoom in,
  /// pins notify the screen, anything else falls through to onMapClick.
  Future<void> _handleTap(MapContentGestureContext context) async {
    final map = _map;
    final coords = context.point.coordinates;

    if (map != null && _layersReady) {
      try {
        final touch = context.touchPosition;
        final features = await map.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenBox(ScreenBox(
            min: ScreenCoordinate(x: touch.x - 22, y: touch.y - 22),
            max: ScreenCoordinate(x: touch.x + 22, y: touch.y + 22),
          )),
          RenderedQueryOptions(
            layerIds: [_kPinLayerId, _kClusterCoreLayerId],
            filter: null,
          ),
        );

        for (final f in features) {
          if (f == null) continue;
          final feature = f.queriedFeature.feature;
          final props =
              (feature['properties'] as Map?)?.cast<Object?, Object?>() ?? {};

          if (props['cluster'] == true) {
            await _expandCluster(map, feature);
            return;
          }

          final markerId = props['id'] as String?;
          final typeName = props['type'] as String?;
          if (markerId != null && typeName != null) {
            final type = MapMarkerType.values.asNameMap()[typeName];
            if (type != null) {
              widget.controller.onMarkerClick?.call(markerId, type);
              return;
            }
          }
        }
      } catch (e, st) {
        logError(e, st, context: 'map.tapQuery');
      }
    }

    widget.controller.onMapClick?.call(
      coords.lat.toDouble(),
      coords.lng.toDouble(),
    );
  }

  Future<void> _expandCluster(MapboxMap map, Map<Object?, Object?> feature) async {
    try {
      final geometry = (feature['geometry'] as Map?)?.cast<Object?, Object?>();
      final coordinates = (geometry?['coordinates'] as List?)?.cast<num>();
      if (coordinates == null || coordinates.length < 2) return;

      final expansion = await map.getGeoJsonClusterExpansionZoom(
        _kMarkerSourceId,
        feature.map((k, v) => MapEntry(k?.toString(), v)),
      );
      final zoom = double.tryParse(expansion.value ?? '') ?? 0;
      final state = await map.getCameraState();

      await map.easeTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              coordinates[0].toDouble(),
              coordinates[1].toDouble(),
            ),
          ),
          zoom: math.max(zoom + 0.4, state.zoom + 1),
        ),
        MapAnimationOptions(duration: 550),
      );
    } catch (e, st) {
      logError(e, st, context: 'map.expandCluster');
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerLng = 0.0;
    final centerLat = 20.0;
    final defaultZoom = 1.0;

    return MapWidget(
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: defaultZoom,
      ),
      styleUri: MapboxStyles.DARK,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
      onCameraChangeListener: (_) {
        widget.controller.onCameraChanged?.call();
      },
      onTapListener: _handleTap,
      onLongTapListener: (context) {
        final coords = context.point.coordinates;
        widget.controller.onMapLongPress?.call(
          coords.lat.toDouble(),
          coords.lng.toDouble(),
        );
      },
    );
  }
}
