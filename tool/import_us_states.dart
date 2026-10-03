/// Imports all 50 US states + DC into Supabase as achievement definitions
/// with polygon + centroid pin. Uses Natural Earth admin-1 dataset.
///
/// Existing state achievements (California, Florida, Hawaii) are upserted —
/// their rows get polygon + pin without losing title/description/xp.
///
/// Usage:
///   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... dart run tool/import_us_states.dart
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (url == null || key == null) {
    stderr.writeln('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
    exit(1);
  }

  final file = File('tool/data/us_states_raw.geojson');
  if (!file.existsSync()) {
    stderr.writeln('Missing tool/data/us_states_raw.geojson');
    exit(1);
  }
  final geo = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final features = (geo['features'] as List<dynamic>).cast<Map<String, dynamic>>();

  // Filter to US states + DC
  final stateFeatures = features.where((f) {
    final props = f['properties'] as Map<String, dynamic>;
    final iso = props['iso_a2'] as String?;
    final type = props['type'] as String?;
    if (iso != 'US') return false;
    return type == 'State' || type == 'Federal district';
  }).toList();

  print('Found ${stateFeatures.length} US states/districts in GeoJSON.\n');

  final client = HttpClient();
  var ok = 0, fail = 0;

  for (final f in stateFeatures) {
    final props = f['properties'] as Map<String, dynamic>;
    final name = props['name'] as String;
    final slug = _slugify(name);
    final achId = 'americas-$slug';

    // Pick largest ring from geometry
    final geom = f['geometry'] as Map<String, dynamic>;
    final type = geom['type'] as String;
    final coords = geom['coordinates'] as List<dynamic>;
    List<List<List<double>>> rings;
    if (type == 'Polygon') {
      final outer = (coords[0] as List).cast<List<dynamic>>();
      rings = [_ringAsLatLng(outer)];
    } else if (type == 'MultiPolygon') {
      rings = coords.map((poly) {
        final outer = ((poly as List)[0] as List).cast<List<dynamic>>();
        return _ringAsLatLng(outer);
      }).toList();
    } else {
      print('SKIP $name — unknown geometry type $type');
      continue;
    }

    rings.sort((a, b) => _bboxArea(b).compareTo(_bboxArea(a)));
    var ring = rings.first;

    // Simplify — states tend to be smaller than countries, use tighter epsilon
    var epsilon = 0.1;
    var simplified = _douglasPeucker(ring, epsilon);
    while (simplified.length > 40 && epsilon < 2.0) {
      epsilon *= 1.5;
      simplified = _douglasPeucker(ring, epsilon);
    }
    while (simplified.length < 10 && epsilon > 0.02) {
      epsilon /= 2;
      simplified = _douglasPeucker(ring, epsilon);
    }
    if (simplified.length > 1 &&
        simplified.first[0] == simplified.last[0] &&
        simplified.first[1] == simplified.last[1]) {
      simplified = simplified.sublist(0, simplified.length - 1);
    }
    if (simplified.length < 3) {
      print('SKIP $name — too few vertices');
      continue;
    }

    final centroid = _centroid(simplified);

    // Upsert — matches existing IDs like americas-california, adds new ones
    try {
      final uri = Uri.parse('$url/rest/v1/achievement_definitions');
      final request = await client.postUrl(uri);
      request.headers.set('apikey', key);
      request.headers.set('Authorization', 'Bearer $key');
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Prefer', 'resolution=merge-duplicates');
      request.add(utf8.encode(jsonEncode([
        {
          'id': achId,
          'title': name,
          'description': 'Set foot in $name',
          'tier': 'gold',
          'xp_reward': 35,
          'latitude': centroid[0],
          'longitude': centroid[1],
          'claim_polygon': simplified,
          'collection_id': 'americas',
          'tags': ['americas', 'state', 'usa'],
          'is_active': true,
        }
      ])));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('OK   $achId — $name (${simplified.length} verts)');
        ok++;
      } else {
        print('FAIL $achId — ${response.statusCode}: $body');
        fail++;
      }
    } catch (e) {
      print('FAIL $achId — $e');
      fail++;
    }
  }

  client.close();
  print('\nDone. OK=$ok, FAIL=$fail');
  exit(0);
}

String _slugify(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');
}

List<List<double>> _ringAsLatLng(List<List<dynamic>> ring) {
  return ring
      .map<List<double>>((p) => [
            (p[1] as num).toDouble(),
            (p[0] as num).toDouble(),
          ])
      .toList();
}

double _bboxArea(List<List<double>> ring) {
  if (ring.isEmpty) return 0;
  var minLat = double.infinity, maxLat = -double.infinity;
  var minLng = double.infinity, maxLng = -double.infinity;
  for (final p in ring) {
    if (p[0] < minLat) minLat = p[0];
    if (p[0] > maxLat) maxLat = p[0];
    if (p[1] < minLng) minLng = p[1];
    if (p[1] > maxLng) maxLng = p[1];
  }
  return (maxLat - minLat) * (maxLng - minLng);
}

List<double> _centroid(List<List<double>> ring) {
  var sumLat = 0.0, sumLng = 0.0;
  for (final p in ring) {
    sumLat += p[0];
    sumLng += p[1];
  }
  return [sumLat / ring.length, sumLng / ring.length];
}

List<List<double>> _douglasPeucker(List<List<double>> ring, double epsilon) {
  if (ring.length < 3) return List.from(ring);
  final keep = List<bool>.filled(ring.length, false);
  keep[0] = true;
  keep[ring.length - 1] = true;
  _dpRecurse(ring, 0, ring.length - 1, epsilon, keep);
  final result = <List<double>>[];
  for (var i = 0; i < ring.length; i++) {
    if (keep[i]) result.add(ring[i]);
  }
  return result;
}

void _dpRecurse(List<List<double>> pts, int first, int last, double eps,
    List<bool> keep) {
  if (last - first < 2) return;
  var maxDist = 0.0;
  var maxIdx = first;
  final a = pts[first];
  final b = pts[last];
  for (var i = first + 1; i < last; i++) {
    final d = _perpDist(pts[i], a, b);
    if (d > maxDist) {
      maxDist = d;
      maxIdx = i;
    }
  }
  if (maxDist > eps) {
    keep[maxIdx] = true;
    _dpRecurse(pts, first, maxIdx, eps, keep);
    _dpRecurse(pts, maxIdx, last, eps, keep);
  }
}

double _perpDist(List<double> p, List<double> a, List<double> b) {
  final dx = b[0] - a[0];
  final dy = b[1] - a[1];
  if (dx == 0 && dy == 0) {
    return sqrt(pow(p[0] - a[0], 2) + pow(p[1] - a[1], 2));
  }
  final t = ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy);
  final tClamped = t < 0 ? 0.0 : (t > 1 ? 1.0 : t);
  final projX = a[0] + tClamped * dx;
  final projY = a[1] + tClamped * dy;
  return sqrt(pow(p[0] - projX, 2) + pow(p[1] - projY, 2));
}
