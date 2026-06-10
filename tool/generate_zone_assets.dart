// Generates the bundled zone-boundary assets that make the hover-highlight
// instant (no network) for the common cases:
//
//   assets/data/world_countries.geojson   country layer, worldwide
//   assets/data/israel_districts.geojson  area/district layer (מחוזות)
//   assets/data/israel_cities.geojson     city layer (all municipalities)
//
// Inputs:
//   tool/data/countries.geojson      Natural Earth admin-0 countries
//   tool/data/lookup_lv4_0.json      Nominatim lookup: admin_level=4 polygons
//   tool/data/lookup_lv8_*.json      Nominatim lookup: admin_level=8 polygons
//
// Run:  dart run tool/generate_zone_assets.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main() {
  _generateCountries();
  _generateIsraelLayer(
    pattern: RegExp(r'lookup_lv4_\d+\.json$'),
    output: 'assets/data/israel_districts.geojson',
    simplifyTolerance: 2e-3,
  );
  _generateIsraelLayer(
    pattern: RegExp(r'lookup_lv8_\d+\.json$'),
    output: 'assets/data/israel_cities.geojson',
    simplifyTolerance: 5e-4,
  );
}

void _generateCountries() {
  final json = jsonDecode(
          File('tool/data/countries.geojson').readAsStringSync())
      as Map<String, dynamic>;

  final features = <Map<String, dynamic>>[];
  for (final f in (json['features'] as List)) {
    final props = (f as Map<String, dynamic>)['properties']
        as Map<String, dynamic>;
    final name = (props['NAME_HE'] ?? props['NAME']) as String?;
    if (name == null) continue;

    final rings = _outerRings(f['geometry'] as Map<String, dynamic>)
        .map((r) => _simplify(r, 1e-2))
        .where((r) => r.length >= 4)
        .toList();
    if (rings.isEmpty) continue;

    features.add({
      'type': 'Feature',
      'properties': {
        'name': name,
        'name_en': props['NAME'],
      },
      'geometry': {
        'type': 'MultiPolygon',
        'coordinates': rings.map((r) => [_closed(r)]).toList(),
      },
    });
  }
  _write('assets/data/world_countries.geojson', features);
}

void _generateIsraelLayer({
  required RegExp pattern,
  required String output,
  required double simplifyTolerance,
}) {
  final files = Directory('tool/data')
      .listSync()
      .whereType<File>()
      .where((f) => pattern.hasMatch(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final features = <Map<String, dynamic>>[];
  final seen = <int>{};
  for (final file in files) {
    final rows = jsonDecode(file.readAsStringSync()) as List;
    for (final row in rows) {
      final r = row as Map<String, dynamic>;
      final address = (r['address'] ?? const {}) as Map<String, dynamic>;
      if (address['country_code'] != 'il') continue; // neighbors in the bbox
      final osmId = r['osm_id'] as int;
      if (!seen.add(osmId)) continue;
      // Bilingual OSM names ("ירושלים | القدس") → first segment for the pill.
      final name = (r['name'] as String?)?.split('|').first.trim();
      final geojson = r['geojson'] as Map<String, dynamic>?;
      if (name == null || name.isEmpty || geojson == null) continue;

      final rings = _outerRings(geojson)
          .map((ring) => _simplify(ring, simplifyTolerance))
          .where((ring) => ring.length >= 4)
          .toList();
      if (rings.isEmpty) continue;

      features.add({
        'type': 'Feature',
        'properties': {'name': name, 'osm_id': osmId},
        'geometry': {
          'type': 'MultiPolygon',
          'coordinates': rings.map((ring) => [_closed(ring)]).toList(),
        },
      });
    }
  }
  _write(output, features);
}

void _write(String path, List<Map<String, dynamic>> features) {
  final out = const JsonEncoder()
      .convert({'type': 'FeatureCollection', 'features': features});
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(out);
  print('$path: ${features.length} zones, '
      '${(out.length / 1024).toStringAsFixed(0)} KB');
}

/// Outer rings of Polygon/MultiPolygon as [lng, lat] lists (holes dropped).
List<List<List<double>>> _outerRings(Map<String, dynamic> geometry) {
  final type = geometry['type'] as String;
  final coords = geometry['coordinates'] as List;
  List<List<double>> toRing(List raw) => raw
      .map<List<double>>(
          (p) => [(p[0] as num).toDouble(), (p[1] as num).toDouble()])
      .toList();

  if (type == 'Polygon') return [toRing(coords[0] as List)];
  if (type == 'MultiPolygon') {
    return [for (final poly in coords) toRing((poly as List)[0] as List)];
  }
  return const [];
}

List<List<double>> _closed(List<List<double>> ring) {
  if (ring.first[0] == ring.last[0] && ring.first[1] == ring.last[1]) {
    return ring;
  }
  return [...ring, ring.first];
}

/// Douglas–Peucker simplification (same as generate_netanya_zones.dart).
List<List<double>> _simplify(List<List<double>> ring, double tolerance) {
  if (ring.length <= 4) return ring;
  final keep = List<bool>.filled(ring.length, false);
  keep[0] = true;
  keep[ring.length - 1] = true;

  void dp(int start, int end) {
    if (end <= start + 1) return;
    final ax = ring[start][0], ay = ring[start][1];
    final bx = ring[end][0], by = ring[end][1];
    final dx = bx - ax, dy = by - ay;
    final len = math.sqrt(dx * dx + dy * dy);
    var maxDist = -1.0;
    var maxIdx = -1;
    for (var i = start + 1; i < end; i++) {
      final d = len < 1e-12
          ? math.sqrt(math.pow(ring[i][0] - ax, 2) +
              math.pow(ring[i][1] - ay, 2))
          : ((ring[i][0] - ax) * dy - (ring[i][1] - ay) * dx).abs() / len;
      if (d > maxDist) {
        maxDist = d;
        maxIdx = i;
      }
    }
    if (maxDist > tolerance) {
      keep[maxIdx] = true;
      dp(start, maxIdx);
      dp(maxIdx, end);
    }
  }

  dp(0, ring.length - 1);
  final out = <List<double>>[];
  for (var i = 0; i < ring.length; i++) {
    if (keep[i]) out.add(ring[i]);
  }
  return out.length >= 3 ? out : ring;
}
