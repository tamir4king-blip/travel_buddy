/// Imports simplified country polygons from Natural Earth GeoJSON into
/// Supabase `achievement_definitions.claim_polygon`.
///
/// Usage:
///   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... dart run tool/import_country_polygons.dart
///
/// Source: tool/data/countries.geojson (Natural Earth 1:50m admin 0).
/// - Picks the largest ring for MultiPolygon countries (main landmass).
/// - Simplifies via Douglas-Peucker targeting 15-40 vertices per country.
/// - Computes centroid for pin location.
/// - Uploads via PostgREST PATCH.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// achievement_id -> ISO_A2 country code
const idToIso = <String, String>{
  // Europe
  'europe-france': 'FR',
  'europe-italy': 'IT',
  'europe-spain': 'ES',
  'europe-germany': 'DE',
  'europe-uk': 'GB',
  'europe-netherlands': 'NL',
  'europe-greece': 'GR',
  'europe-switzerland': 'CH',
  'europe-portugal': 'PT',
  'europe-czech': 'CZ',
  'europe-austria': 'AT',
  'europe-sweden': 'SE',
  'europe-norway': 'NO',
  'europe-denmark': 'DK',
  'europe-poland': 'PL',
  'europe-ireland': 'IE',
  'europe-croatia': 'HR',
  'europe-hungary': 'HU',
  'europe-belgium': 'BE',
  'europe-turkey': 'TR',
  'europe-finland': 'FI',
  'europe-romania': 'RO',
  'europe-iceland': 'IS',
  'europe-slovenia': 'SI',
  'europe-slovakia': 'SK',
  'europe-serbia': 'RS',
  'europe-bulgaria': 'BG',
  'europe-cyprus': 'CY',
  'europe-malta': 'MT',
  'europe-luxembourg': 'LU',
  // Asia
  'asia-japan': 'JP',
  'asia-china': 'CN',
  'asia-south-korea': 'KR',
  'asia-thailand': 'TH',
  'asia-vietnam': 'VN',
  'asia-india': 'IN',
  'asia-indonesia': 'ID',
  'asia-philippines': 'PH',
  'asia-malaysia': 'MY',
  'asia-singapore': 'SG',
  'asia-cambodia': 'KH',
  'asia-sri-lanka': 'LK',
  'asia-nepal': 'NP',
  'asia-jordan': 'JO',
  'asia-uae': 'AE',
  'asia-israel': 'IL',
  'asia-saudi-arabia': 'SA',
  // Africa
  'africa-south-africa': 'ZA',
  'africa-morocco': 'MA',
  'africa-egypt': 'EG',
  'africa-kenya': 'KE',
  'africa-tanzania': 'TZ',
  'africa-nigeria': 'NG',
  'africa-ethiopia': 'ET',
  'africa-ghana': 'GH',
  'africa-tunisia': 'TN',
  'africa-madagascar': 'MG',
  // South America
  'south-america-brazil': 'BR',
  'south-america-argentina': 'AR',
  'south-america-colombia': 'CO',
  'south-america-peru': 'PE',
  'south-america-chile': 'CL',
  'south-america-ecuador': 'EC',
  'south-america-uruguay': 'UY',
  'south-america-bolivia': 'BO',
  // Oceania
  'oceania-australia': 'AU',
  'oceania-new-zealand': 'NZ',
  'oceania-fiji': 'FJ',
  'oceania-tahiti': 'PF',
  'oceania-papua-new-guinea': 'PG',
  // Americas (countries)
  'americas-usa': 'US',
  'americas-canada': 'CA',
  'americas-mexico': 'MX',
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
  final features = geo['features'] as List<dynamic>;

  // Build ISO -> polygon rings lookup. Two-pass so real ISO_A2 matches
  // (main country polygons) take precedence over ISO_A2_EH fallbacks
  // (small territories / disputed entries).
  final isoToRings = <String, List<List<List<double>>>>{};

  void loadFeature(Map<String, dynamic> f, String iso) {
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

  // Pass 1: real ISO_A2 codes only
  for (final f in features) {
    final props = f['properties'] as Map<String, dynamic>;
    final iso = props['ISO_A2'] as String?;
    if (iso == null || iso == '-99') continue;
    loadFeature(f as Map<String, dynamic>, iso);
  }

  // Pass 2: ISO_A2_EH fallback only for countries still missing
  for (final f in features) {
    final props = f['properties'] as Map<String, dynamic>;
    final realIso = props['ISO_A2'] as String?;
    if (realIso != null && realIso != '-99') continue;
    final iso = props['ISO_A2_EH'] as String?;
    if (iso == null || iso == '-99') continue;
    if (isoToRings.containsKey(iso)) continue; // already loaded in pass 1
    loadFeature(f as Map<String, dynamic>, iso);
  }

  final client = HttpClient();
  var ok = 0, skip = 0, fail = 0;

  for (final entry in idToIso.entries) {
    final achId = entry.key;
    final iso = entry.value;
    final rings = isoToRings[iso];
    if (rings == null) {
      print('SKIP $achId ($iso) — not in GeoJSON');
      skip++;
      continue;
    }

    // Pick largest ring by bbox area (main landmass)
    rings.sort((a, b) => _bboxArea(b).compareTo(_bboxArea(a)));
    var ring = rings.first;

    // Simplify with adaptive epsilon targeting 15-40 vertices
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

    // Remove closing duplicate (GeoJSON rings are closed)
    if (simplified.length > 1 &&
        simplified.first[0] == simplified.last[0] &&
        simplified.first[1] == simplified.last[1]) {
      simplified = simplified.sublist(0, simplified.length - 1);
    }

    if (simplified.length < 3) {
      print('SKIP $achId ($iso) — only ${simplified.length} vertices after simplify');
      skip++;
      continue;
    }

    // Centroid (for pin)
    final centroid = _centroid(simplified);

    // PATCH to Supabase
    try {
      final uri = Uri.parse('$url/rest/v1/achievement_definitions?id=eq.$achId');
      final request = await client.patchUrl(uri);
      request.headers.set('apikey', key);
      request.headers.set('Authorization', 'Bearer $key');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Prefer', 'return=minimal');
      request.write(jsonEncode({
        'claim_polygon': simplified,
        'latitude': centroid[0],
        'longitude': centroid[1],
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('OK   $achId ($iso) — ${simplified.length} verts');
        ok++;
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
  print('\nDone. OK=$ok, SKIP=$skip, FAIL=$fail');
  exit(0);
}

/// Converts GeoJSON ring ([[lng, lat], ...]) into our format ([[lat, lng], ...]).
List<List<double>> _ringAsLatLng(List<List<dynamic>> ring) {
  return ring
      .map<List<double>>((p) => [
            (p[1] as num).toDouble(), // lat
            (p[0] as num).toDouble(), // lng
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

/// Douglas-Peucker polyline simplification.
/// Treats ring as closed: simplifies then re-closes.
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
