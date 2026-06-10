import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';

/// An administrative boundary (country / state / city / neighbourhood)
/// resolved from OpenStreetMap for the zone-hover highlight.
class ZoneBoundary {
  /// Stable OSM identity, e.g. `relation/1382494`.
  final String id;

  /// Localized display name from OSM (e.g. "ישראל", "Netanya").
  final String name;

  /// The Nominatim admin zoom band this was fetched at (3..14) — a boundary
  /// only "matches" while the map stays in the same band.
  final int adminZoom;

  /// Outer rings as `[[lat, lng], ...]` — one entry per polygon part
  /// (countries with islands are MultiPolygons).
  final List<List<List<double>>> rings;

  const ZoneBoundary({
    required this.id,
    required this.name,
    required this.adminZoom,
    required this.rings,
  });

  bool containsPoint(double lat, double lng) =>
      rings.any((ring) => isPointInPolygon(lat, lng, ring));

  /// Parses a Nominatim `/reverse?polygon_geojson=1` response. Returns null
  /// when the result has no usable polygon (ocean, node-only results).
  static ZoneBoundary? fromNominatim(Map<String, dynamic> json, int adminZoom) {
    final osmType = json['osm_type'] as String?;
    final osmId = json['osm_id'];
    final geojson = json['geojson'] as Map<String, dynamic>?;
    if (osmType == null || osmId == null || geojson == null) return null;

    final type = geojson['type'] as String?;
    final coords = geojson['coordinates'];
    if (coords == null) return null;

    // GeoJSON positions are [lng, lat]; we keep only outer rings.
    List<List<double>> ringFrom(List<dynamic> raw) => raw
        .map<List<double>>((p) => [
              (p[1] as num).toDouble(),
              (p[0] as num).toDouble(),
            ])
        .toList();

    final rings = <List<List<double>>>[];
    if (type == 'Polygon') {
      rings.add(ringFrom(coords[0] as List));
    } else if (type == 'MultiPolygon') {
      for (final polygon in coords as List) {
        rings.add(ringFrom((polygon as List)[0] as List));
      }
    } else {
      return null; // Point / LineString — nothing to highlight
    }
    rings.removeWhere((r) => r.length < 4);
    if (rings.isEmpty) return null;

    final name = (json['name'] as String?)?.isNotEmpty == true
        ? json['name'] as String
        : (json['display_name'] as String? ?? '');

    return ZoneBoundary(
      id: '$osmType/$osmId',
      name: name,
      adminZoom: adminZoom,
      rings: rings,
    );
  }
}

/// Resolves the admin boundary under a map point via OSM Nominatim, with an
/// LRU cache and request throttling (Nominatim policy: max 1 req/s).
class ZoneBoundaryService {
  ZoneBoundaryService({HttpClient? client}) : _http = client ?? HttpClient() {
    _http.connectionTimeout = const Duration(seconds: 6);
  }

  final HttpClient _http;

  /// LRU of resolved boundaries, keyed by `osmId@adminZoom` (the same
  /// relation is simplified differently per band).
  final _cache = LinkedHashMap<String, ZoneBoundary>();
  static const _cacheCap = 60;

  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Maps the Mapbox camera zoom to a Nominatim admin "zoom band":
  /// 3=country, 5=state, 8=county/district, 10=city, 12=town/borough,
  /// 14=neighbourhood.
  static int adminZoomFor(double mapZoom) {
    if (mapZoom < 4.0) return 3;
    if (mapZoom < 6.5) return 5;
    if (mapZoom < 9.0) return 8;
    if (mapZoom < 11.5) return 10;
    if (mapZoom < 13.5) return 12;
    return 14;
  }

  /// Polygon simplification tolerance (degrees) per band — keeps country
  /// outlines light without visibly cutting corners on neighbourhoods.
  static double _thresholdFor(int adminZoom) {
    switch (adminZoom) {
      case 3:
        return 0.01;
      case 5:
        return 0.005;
      case 8:
        return 0.002;
      case 10:
        return 0.001;
      case 12:
        return 0.0005;
      default:
        return 0.0002;
    }
  }

  /// Returns the boundary containing (lat, lng) at the given map zoom.
  /// Cache hits (point inside an already-fetched boundary of the same band)
  /// return synchronously without touching the network.
  Future<ZoneBoundary?> boundaryAt(double lat, double lng, double mapZoom) async {
    final band = adminZoomFor(mapZoom);

    for (final cached in _cache.values) {
      if (cached.adminZoom == band && cached.containsPoint(lat, lng)) {
        // Refresh LRU position
        final key = '${cached.id}@$band';
        _cache.remove(key);
        _cache[key] = cached;
        return cached;
      }
    }

    return _fetch(lat, lng, band);
  }

  Future<ZoneBoundary?> _fetch(double lat, double lng, int band) async {
    // Throttle to 1 req/s per Nominatim usage policy.
    final sinceLast = DateTime.now().difference(_lastRequestAt);
    if (sinceLast < const Duration(milliseconds: 1100)) {
      await Future.delayed(const Duration(milliseconds: 1100) - sinceLast);
    }
    _lastRequestAt = DateTime.now();

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': lat.toStringAsFixed(6),
      'lon': lng.toStringAsFixed(6),
      'zoom': '$band',
      'polygon_geojson': '1',
      'polygon_threshold': _thresholdFor(band).toString(),
    });

    try {
      final request = await _http.getUrl(uri);
      // Nominatim requires an identifying UA; default Dart UA gets blocked.
      request.headers.set(HttpHeaders.userAgentHeader,
          'TravelBuddyMobile/1.0 (contact: tamir4king@gmail.com)');
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        await response.drain<void>();
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      // Country-size polygons run to hundreds of KB — decode + ring
      // conversion happens off the UI thread.
      final boundary = await compute(_parseBoundary, (body, band));
      if (boundary == null) return null;

      final key = '${boundary.id}@$band';
      _cache.remove(key);
      _cache[key] = boundary;
      if (_cache.length > _cacheCap) {
        _cache.remove(_cache.keys.first);
      }
      return boundary;
    } catch (e, st) {
      // Network failure — hover highlight just doesn't appear; not worth Sentry.
      logError(e, st, context: 'map.zoneBoundary');
      return null;
    }
  }

  void dispose() {
    _http.close(force: true);
  }
}

/// Isolate entry: decode the Nominatim response body and build the boundary.
ZoneBoundary? _parseBoundary((String, int) args) {
  final (body, band) = args;
  final json = jsonDecode(body);
  if (json is! Map<String, dynamic> || json.containsKey('error')) {
    return null; // ocean / unable to geocode
  }
  return ZoneBoundary.fromNominatim(json, band);
}
