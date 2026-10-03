import 'dart:math';

import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// Ray-casting point-in-polygon test.
/// [polygon] is a list of [lat, lng] pairs defining the boundary.
/// Returns true if the point (lat, lng) is inside the polygon.
bool isPointInPolygon(double lat, double lng, List<List<double>> polygon) {
  final n = polygon.length;
  if (n < 3) return false;

  var inside = false;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final yi = polygon[i][0], xi = polygon[i][1];
    final yj = polygon[j][0], xj = polygon[j][1];

    if (((yi > lat) != (yj > lat)) &&
        (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}

/// Unified proximity check: polygon takes priority, then radius fallback.
/// Returns true if the user is within the achievement's claim area.
bool isWithinClaimArea(double userLat, double userLng, Achievement achievement) {
  if (achievement.hasPolygon) {
    return isPointInPolygon(userLat, userLng, achievement.claimPolygon!);
  }

  if (achievement.latitude != null &&
      achievement.longitude != null &&
      achievement.claimRadius != null) {
    final distance = haversineMeters(
      userLat, userLng,
      achievement.latitude!, achievement.longitude!,
    );
    return distance <= achievement.claimRadius!;
  }

  return false;
}

/// Haversine distance in meters between two lat/lng points.
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0; // Earth radius in meters
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRad(double deg) => deg * pi / 180;

/// Convex hull of a set of [lat, lng] points using Andrew's monotone chain.
/// Returns the hull as a closed ring of [lat, lng] pairs (first == last).
/// Points are sorted by (lng, lat) so the algorithm operates in (x, y) space
/// where x=lng and y=lat. Good enough for small/medium geographic spans —
/// does NOT handle antimeridian wrap or poles.
List<List<double>> convexHullLatLng(List<List<double>> points) {
  if (points.length < 3) {
    if (points.isEmpty) return const [];
    final closed = List<List<double>>.from(points);
    if (closed.first[0] != closed.last[0] ||
        closed.first[1] != closed.last[1]) {
      closed.add(List<double>.from(closed.first));
    }
    return closed;
  }

  final sorted = List<List<double>>.from(points)
    ..sort((a, b) {
      final cx = a[1].compareTo(b[1]);
      return cx != 0 ? cx : a[0].compareTo(b[0]);
    });

  double cross(List<double> o, List<double> a, List<double> b) {
    return (a[1] - o[1]) * (b[0] - o[0]) - (a[0] - o[0]) * (b[1] - o[1]);
  }

  final lower = <List<double>>[];
  for (final p in sorted) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }

  final upper = <List<double>>[];
  for (final p in sorted.reversed) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }

  lower.removeLast();
  upper.removeLast();
  final hull = [...lower, ...upper];
  if (hull.isNotEmpty) {
    hull.add(List<double>.from(hull.first));
  }
  return hull;
}
