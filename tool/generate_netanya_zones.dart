// Generates assets/data/netanya_neighborhoods.geojson — complete
// neighborhood zones for Netanya.
//
// OSM has Netanya's neighborhoods mostly as *point* nodes (place=suburb/
// neighbourhood), not polygons, so there is nothing to highlight at the
// neighbourhood zoom band. This tool partitions the official city polygon
// into Voronoi cells around those points: every spot in the city belongs to
// exactly one neighborhood — full coverage by construction.
//
// Inputs (fetched from OSM, committed alongside for reproducibility):
//   tool/data/netanya_city.json          Nominatim lookup R1383391 (polygon)
//   tool/data/netanya_suburb_nodes.json  Overpass place nodes (bbox)
//
// Run:  dart run tool/generate_netanya_zones.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main() {
  final cityJson = jsonDecode(
      File('tool/data/netanya_city.json').readAsStringSync()) as List;
  final nodesJson = jsonDecode(
          File('tool/data/netanya_suburb_nodes.json').readAsStringSync())
      as Map<String, dynamic>;

  // ── City polygon (largest outer ring, [lng, lat] GeoJSON order) ──────────
  final geojson = (cityJson.first as Map<String, dynamic>)['geojson']
      as Map<String, dynamic>;
  final cityRing = _largestOuterRing(geojson);
  print('City ring: ${cityRing.length} points');

  // ── Neighborhood seed points inside the city ─────────────────────────────
  final sites = <_Site>[];
  for (final el in (nodesJson['elements'] as List)) {
    final tags = (el['tags'] ?? const {}) as Map<String, dynamic>;
    final name = tags['name'] as String?;
    if (name == null || name.isEmpty) continue;
    final lat = (el['lat'] as num).toDouble();
    final lng = (el['lon'] as num).toDouble();
    if (!_pointInRing(lng, lat, cityRing)) continue; // outside Netanya
    sites.add(_Site(
      name: name,
      nameEn: tags['name:en'] as String?,
      lng: lng,
      lat: lat,
    ));
  }
  print('Seed points inside city: ${sites.length}');
  if (sites.length < 3) {
    stderr.writeln('Too few seed points — aborting.');
    exit(1);
  }

  // Planar approximation: scale lng by cos(mean lat) so distances are
  // isotropic (Netanya spans ~10 km — error is negligible).
  final lat0 = sites.map((s) => s.lat).reduce((a, b) => a + b) / sites.length;
  final kx = math.cos(lat0 * math.pi / 180);
  List<double> proj(double lng, double lat) => [lng * kx, lat];

  final projectedCity = cityRing.map((p) => proj(p[0], p[1])).toList();
  final cityArea = _ringArea(projectedCity);

  // Bounding box (padded) as the initial cell for every site.
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final p in projectedCity) {
    minX = math.min(minX, p[0]);
    minY = math.min(minY, p[1]);
    maxX = math.max(maxX, p[0]);
    maxY = math.max(maxY, p[1]);
  }
  const pad = 0.01;
  final bbox = [
    [minX - pad, minY - pad],
    [maxX + pad, minY - pad],
    [maxX + pad, maxY + pad],
    [minX - pad, maxY + pad],
  ];

  // ── Voronoi cell per site: clip bbox by the bisector half-plane against
  //    every other site, then clip the (concave) city polygon to the convex
  //    cell. ─────────────────────────────────────────────────────────────────
  final features = <Map<String, dynamic>>[];
  var coveredArea = 0.0;

  for (final site in sites) {
    final s = proj(site.lng, site.lat);
    var cell = bbox.map((p) => [p[0], p[1]]).toList();

    for (final other in sites) {
      if (identical(other, site)) continue;
      final o = proj(other.lng, other.lat);
      // Half-plane of points closer to s than o: n·p <= n·m, with n = o - s
      // and m the bisector midpoint.
      final nx = o[0] - s[0], ny = o[1] - s[1];
      final mx = (o[0] + s[0]) / 2, my = (o[1] + s[1]) / 2;
      final c = nx * mx + ny * my;
      cell = _clipHalfPlane(cell, nx, ny, c);
      if (cell.length < 3) break;
    }
    if (cell.length < 3) {
      print('WARN: empty Voronoi cell for ${site.name}');
      continue;
    }

    // City ∩ cell — Sutherland–Hodgman with the convex cell as clip region.
    var zone = projectedCity.map((p) => [p[0], p[1]]).toList();
    for (var i = 0; i < cell.length; i++) {
      final a = cell[i];
      final b = cell[(i + 1) % cell.length];
      // Inside = left of edge a→b (cell is CCW after area normalization).
      final nx = b[1] - a[1], ny = a[0] - b[0];
      final c = nx * a[0] + ny * a[1];
      zone = _clipHalfPlane(zone, nx, ny, c);
      if (zone.length < 3) break;
    }
    if (zone.length < 3) {
      print('WARN: zone for ${site.name} clipped away entirely');
      continue;
    }

    coveredArea += _ringArea(zone).abs();
    final simplified = _simplify(zone, 1.5e-4);

    // Back to [lng, lat] GeoJSON ring (closed).
    final ring = simplified.map((p) => [p[0] / kx, p[1]]).toList()
      ..add([simplified.first[0] / kx, simplified.first[1]]);

    features.add({
      'type': 'Feature',
      'properties': {
        'name': site.name,
        if (site.nameEn != null) 'name_en': site.nameEn,
        'city': 'נתניה',
      },
      'geometry': {
        'type': 'Polygon',
        'coordinates': [ring],
      },
    });
  }

  final coverage = coveredArea / cityArea.abs() * 100;
  print('Zones: ${features.length}');
  print('Coverage: ${coverage.toStringAsFixed(1)}% of city area');
  if (coverage < 97.0) {
    stderr.writeln('Coverage below 97% — investigate before shipping.');
    exit(1);
  }

  final out = const JsonEncoder().convert({
    'type': 'FeatureCollection',
    'features': features,
  });
  File('assets/data/netanya_neighborhoods.geojson')
    ..createSync(recursive: true)
    ..writeAsStringSync(out);
  print('Wrote assets/data/netanya_neighborhoods.geojson '
      '(${(out.length / 1024).toStringAsFixed(1)} KB)');
}

class _Site {
  final String name;
  final String? nameEn;
  final double lng;
  final double lat;
  _Site({required this.name, this.nameEn, required this.lng, required this.lat});
}

/// Largest outer ring of a Polygon/MultiPolygon, in [lng, lat] order.
List<List<double>> _largestOuterRing(Map<String, dynamic> geojson) {
  final type = geojson['type'] as String;
  final coords = geojson['coordinates'] as List;
  List<List<double>> toRing(List raw) => raw
      .map<List<double>>(
          (p) => [(p[0] as num).toDouble(), (p[1] as num).toDouble()])
      .toList();

  if (type == 'Polygon') return toRing(coords[0] as List);
  if (type == 'MultiPolygon') {
    List<List<double>>? best;
    var bestArea = -1.0;
    for (final poly in coords) {
      final ring = toRing((poly as List)[0] as List);
      final a = _ringArea(ring).abs();
      if (a > bestArea) {
        bestArea = a;
        best = ring;
      }
    }
    return best!;
  }
  throw StateError('Unsupported geometry: $type');
}

bool _pointInRing(double x, double y, List<List<double>> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = ring[i][0], yi = ring[i][1];
    final xj = ring[j][0], yj = ring[j][1];
    if (((yi > y) != (yj > y)) &&
        (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}

/// Shoelace area (signed).
double _ringArea(List<List<double>> ring) {
  var sum = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final a = ring[i];
    final b = ring[(i + 1) % ring.length];
    sum += a[0] * b[1] - b[0] * a[1];
  }
  return sum / 2;
}

/// Sutherland–Hodgman clip of [poly] against half-plane nx*x + ny*y <= c.
List<List<double>> _clipHalfPlane(
    List<List<double>> poly, double nx, double ny, double c) {
  final out = <List<double>>[];
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i];
    final b = poly[(i + 1) % poly.length];
    final da = nx * a[0] + ny * a[1] - c;
    final db = nx * b[0] + ny * b[1] - c;
    final aIn = da <= 0, bIn = db <= 0;

    if (aIn) out.add(a);
    if (aIn != bIn) {
      final t = da / (da - db);
      out.add([a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])]);
    }
  }
  return out;
}

/// Douglas–Peucker simplification.
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
