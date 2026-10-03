/// Adds achievement definitions for every country in Natural Earth that is
/// not already covered by our existing registry. Creates a new row in
/// `achievement_definitions` with polygon + centroid pin.
///
/// Skips: existing achievements, Antarctica, open-ocean entries, non-country
/// types (dependencies, indeterminate).
///
/// Usage:
///   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... dart run tool/add_missing_countries.dart
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// ISO_A2 codes already represented by our hardcoded/imported achievements.
const existingIso = <String>{
  // Europe
  'FR', 'IT', 'ES', 'DE', 'GB', 'NL', 'GR', 'CH', 'PT', 'CZ', 'AT',
  'SE', 'NO', 'DK', 'PL', 'IE', 'HR', 'HU', 'BE', 'TR', 'FI', 'RO',
  'IS', 'SI', 'SK', 'RS', 'BG', 'CY', 'MT', 'LU',
  // Asia
  'JP', 'CN', 'KR', 'TH', 'VN', 'IN', 'ID', 'PH', 'MY', 'SG', 'KH',
  'LK', 'NP', 'JO', 'AE', 'IL', 'SA',
  // Africa
  'ZA', 'MA', 'EG', 'KE', 'TZ', 'NG', 'ET', 'GH', 'TN', 'MG',
  // South America
  'BR', 'AR', 'CO', 'PE', 'CL', 'EC', 'UY', 'BO',
  // Oceania
  'AU', 'NZ', 'FJ', 'PF', 'PG',
  // North America
  'US', 'CA', 'MX',
};

/// Map Natural Earth CONTINENT → our collection_id + tag.
const continentMap = <String, ({String collection, String tag})>{
  'Africa': (collection: 'africa', tag: 'africa'),
  'Asia': (collection: 'asia', tag: 'asia'),
  'Europe': (collection: 'europe', tag: 'europe'),
  'North America': (collection: 'americas', tag: 'americas'),
  'South America': (collection: 'south-america', tag: 'south-america'),
  'Oceania': (collection: 'oceania', tag: 'oceania'),
};

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (url == null || key == null) {
    stderr.writeln('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
    exit(1);
  }

  final file = File('tool/data/countries.geojson');
  if (!file.existsSync()) {
    stderr.writeln('Missing tool/data/countries.geojson');
    exit(1);
  }
  final geo = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final features = (geo['features'] as List<dynamic>).cast<Map<String, dynamic>>();

  // Two-pass ring loading (real ISO_A2 first, EH fallback second).
  final isoToRings = <String, List<List<List<double>>>>{};
  final isoToProps = <String, Map<String, dynamic>>{};

  void loadRings(Map<String, dynamic> f, String iso) {
    final geom = f['geometry'] as Map<String, dynamic>?;
    if (geom == null) return;
    final type = geom['type'] as String;
    final coords = geom['coordinates'] as List<dynamic>;
    if (type == 'Polygon') {
      final outer = (coords[0] as List).cast<List<dynamic>>();
      isoToRings[iso] = [_ringAsLatLng(outer)];
    } else if (type == 'MultiPolygon') {
      final rings = <List<List<double>>>[];
      for (final poly in coords) {
        final outer = ((poly as List)[0] as List).cast<List<dynamic>>();
        rings.add(_ringAsLatLng(outer));
      }
      isoToRings[iso] = rings;
    }
  }

  for (final f in features) {
    final props = f['properties'] as Map<String, dynamic>;
    final iso = props['ISO_A2'] as String?;
    if (iso == null || iso == '-99') continue;
    loadRings(f, iso);
    isoToProps[iso] = props;
  }
  for (final f in features) {
    final props = f['properties'] as Map<String, dynamic>;
    final realIso = props['ISO_A2'] as String?;
    if (realIso != null && realIso != '-99') continue;
    final iso = props['ISO_A2_EH'] as String?;
    if (iso == null || iso == '-99') continue;
    if (isoToRings.containsKey(iso)) continue;
    loadRings(f, iso);
    isoToProps[iso] = props;
  }

  final client = HttpClient();
  var added = 0, skip = 0, fail = 0;
  final seenIds = <String>{};

  for (final iso in isoToRings.keys) {
    if (existingIso.contains(iso)) {
      skip++;
      continue;
    }
    final props = isoToProps[iso]!;
    final type = props['TYPE'] as String?;
    // Only include real countries (sovereign + non-sovereign countries like
    // Greenland). Skip dependencies, indeterminate territories, etc.
    if (type != 'Sovereign country' && type != 'Country') {
      skip++;
      continue;
    }
    final continent = props['CONTINENT'] as String?;
    final continentInfo = continentMap[continent];
    if (continentInfo == null) {
      skip++;
      continue;
    }

    final name = (props['NAME'] as String?) ?? (props['ADMIN'] as String?);
    if (name == null) {
      skip++;
      continue;
    }

    // Generate achievement id from continent prefix + slug
    final slug = _slugify(name);
    final achId = '${continentInfo.tag}-$slug';
    if (seenIds.contains(achId)) {
      // Already added under this id in this run (unlikely but defensive)
      skip++;
      continue;
    }
    seenIds.add(achId);

    // Pick largest ring + simplify
    final rings = isoToRings[iso]!;
    rings.sort((a, b) => _bboxArea(b).compareTo(_bboxArea(a)));
    var ring = rings.first;
    var epsilon = 0.2;
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
      skip++;
      continue;
    }
    final centroid = _centroid(simplified);

    // Upsert achievement definition
    try {
      final uri = Uri.parse('$url/rest/v1/achievement_definitions');
      final request = await client.postUrl(uri);
      request.headers.set('apikey', key);
      request.headers.set('Authorization', 'Bearer $key');
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Prefer', 'resolution=merge-duplicates');
      // Must use utf8.encode() — HttpClientRequest.write defaults to latin-1
      // which breaks non-ASCII country names (São Tomé, Curaçao, Åland, Côte d'Ivoire).
      request.add(utf8.encode(jsonEncode([
        {
          'id': achId,
          'title': name,
          'description': 'Set foot in $name',
          'tier': 'silver',
          'xp_reward': 20,
          'latitude': centroid[0],
          'longitude': centroid[1],
          'claim_polygon': simplified,
          'collection_id': continentInfo.collection,
          'tags': [continentInfo.tag, 'country'],
          'is_active': true,
        }
      ])));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('ADD  $achId ($iso) $name — ${simplified.length} verts');
        added++;
      } else {
        print('FAIL $achId ($iso) — ${response.statusCode}: $body');
        fail++;
      }
    } catch (e) {
      print('FAIL $achId ($iso) — $e');
      fail++;
    }
  }

  client.close();
  print('\nDone. ADDED=$added, SKIP=$skip, FAIL=$fail');
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
