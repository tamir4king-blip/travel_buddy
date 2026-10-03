import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/features/map/services/zone_boundary_service.dart';

/// Bundled zone boundaries — the reason the hover-highlight feels instant.
///
/// Instead of asking Nominatim on every zone change (network round-trip +
/// 1 req/s policy), the common layers ship with the app and resolve with a
/// local point-in-polygon test:
///
///   band  3 → world countries (Natural Earth)
///   band  5 → Israel districts (מחוזות, OSM admin_level=4)
///   band 10 → Israel cities (OSM admin_level=8)
///   band 14 → Netanya neighborhoods (generated Voronoi partition)
///
/// Anything not covered here falls back to the live Nominatim lookup.
/// Assets are produced by tool/generate_zone_assets.dart and
/// tool/generate_netanya_zones.dart.
///
/// Performance note: rings are kept as flat [lat,lng,lat,lng,...]
/// Float64Lists — they cross the parse-isolate boundary as a memcpy instead
/// of a deep object-graph copy (the countries layer alone is ~1.6 MB of
/// JSON; nested List copies caused visible main-thread stalls).
class LocalZoneRegistry {
  static const _layerAssets = <int, String>{
    3: 'assets/data/world_countries.geojson',
    5: 'assets/data/israel_districts.geojson',
    10: 'assets/data/israel_cities.geojson',
    14: 'assets/data/netanya_neighborhoods.geojson',
  };

  final _layers = <int, List<_LocalZone>>{};
  final _loading = <int, Future<List<_LocalZone>>>{};

  /// Warm all layers so the first hover doesn't pay the parse cost.
  Future<void> preload() async {
    for (final band in _layerAssets.keys) {
      await _layer(band);
    }
  }

  /// The bundled zone containing (lat, lng) at [band], or null when this
  /// point isn't covered by bundled data (→ caller falls back to network).
  Future<ZoneBoundary?> boundaryAt(double lat, double lng, int band) async {
    final zones = await _layer(band);
    for (final zone in zones) {
      if (zone.contains(lat, lng)) return zone.toBoundary();
    }
    return null;
  }

  Future<List<_LocalZone>> _layer(int band) {
    final asset = _layerAssets[band];
    if (asset == null) return Future.value(const []);
    final cached = _layers[band];
    if (cached != null) return Future.value(cached);
    return _loading[band] ??= () async {
      try {
        final data = await rootBundle.load(asset);
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        // Decode + parse fully off the UI thread; the result is Float64List
        // based, so the trip back to this isolate is cheap.
        final zones = await compute(_parseZones, (bytes, band));
        _layers[band] = zones;
        return zones;
      } catch (e, st) {
        logError(e, st, context: 'map.localZones.load', report: true);
        _layers[band] = const [];
        return const <_LocalZone>[];
      }
    }();
  }
}

/// A zone with flat-array rings and per-ring bboxes for fast containment.
class _LocalZone {
  final String id;
  final String name;
  final int band;

  /// Rings as flat [lat0, lng0, lat1, lng1, ...].
  final List<Float64List> rings;

  /// Flat bboxes, 4 values per ring: [minLat, minLng, maxLat, maxLng, ...].
  final Float64List bboxes;

  ZoneBoundary? _boundary;

  _LocalZone({
    required this.id,
    required this.name,
    required this.band,
    required this.rings,
    required this.bboxes,
  });

  bool contains(double lat, double lng) {
    for (var r = 0; r < rings.length; r++) {
      final b = r * 4;
      if (lat < bboxes[b] ||
          lng < bboxes[b + 1] ||
          lat > bboxes[b + 2] ||
          lng > bboxes[b + 3]) {
        continue;
      }
      if (_pointInFlatRing(lat, lng, rings[r])) return true;
    }
    return false;
  }

  /// Materializes the nested-list [ZoneBoundary] (only for the zone actually
  /// being highlighted — cached after the first call).
  ZoneBoundary toBoundary() {
    return _boundary ??= ZoneBoundary(
      id: id,
      name: name,
      adminZoom: band,
      rings: [
        for (final ring in rings)
          [
            for (var i = 0; i < ring.length; i += 2) [ring[i], ring[i + 1]],
          ],
      ],
    );
  }
}

bool _pointInFlatRing(double lat, double lng, Float64List ring) {
  final n = ring.length ~/ 2;
  if (n < 3) return false;
  var inside = false;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final yi = ring[i * 2], xi = ring[i * 2 + 1];
    final yj = ring[j * 2], xj = ring[j * 2 + 1];
    if (((yi > lat) != (yj > lat)) &&
        (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}

/// Isolate entry: decode bytes and parse a GeoJSON FeatureCollection into
/// flat-array zones.
List<_LocalZone> _parseZones((Uint8List, int) args) {
  final (bytes, band) = args;
  final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final zones = <_LocalZone>[];

  for (final feature in (json['features'] as List)) {
    final f = feature as Map<String, dynamic>;
    final props = f['properties'] as Map<String, dynamic>;
    final name = props['name'] as String?;
    final geometry = f['geometry'] as Map<String, dynamic>;
    if (name == null || name.isEmpty) continue;

    // GeoJSON [lng, lat] → flat [lat, lng, ...]; outer rings only.
    Float64List toFlat(List raw) {
      final out = Float64List(raw.length * 2);
      for (var i = 0; i < raw.length; i++) {
        final p = raw[i] as List;
        out[i * 2] = (p[1] as num).toDouble();
        out[i * 2 + 1] = (p[0] as num).toDouble();
      }
      return out;
    }

    final type = geometry['type'] as String;
    final coords = geometry['coordinates'] as List;
    final rings = <Float64List>[];
    if (type == 'Polygon') {
      rings.add(toFlat(coords[0] as List));
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        rings.add(toFlat((poly as List)[0] as List));
      }
    }
    rings.removeWhere((r) => r.length < 8);
    if (rings.isEmpty) continue;

    final bboxes = Float64List(rings.length * 4);
    for (var r = 0; r < rings.length; r++) {
      final ring = rings[r];
      var minLat = ring[0], maxLat = ring[0];
      var minLng = ring[1], maxLng = ring[1];
      for (var i = 2; i < ring.length; i += 2) {
        if (ring[i] < minLat) minLat = ring[i];
        if (ring[i] > maxLat) maxLat = ring[i];
        if (ring[i + 1] < minLng) minLng = ring[i + 1];
        if (ring[i + 1] > maxLng) maxLng = ring[i + 1];
      }
      bboxes[r * 4] = minLat;
      bboxes[r * 4 + 1] = minLng;
      bboxes[r * 4 + 2] = maxLat;
      bboxes[r * 4 + 3] = maxLng;
    }

    zones.add(_LocalZone(
      id: 'local/$band/${props['osm_id'] ?? name}',
      name: name,
      band: band,
      rings: rings,
      bboxes: bboxes,
    ));
  }
  return zones;
}
