import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/features/map/services/zone_boundary_service.dart';

/// Bundled neighborhood zones for places where OSM has no polygon data.
///
/// Netanya's neighborhoods exist in OSM only as point nodes, so the live
/// Nominatim lookup returns nothing at the neighbourhood band. These zones
/// are generated offline (tool/generate_netanya_zones.dart) as a Voronoi
/// partition of the official city polygon around those points — together
/// they cover 100% of the city.
class LocalZoneRegistry {
  static const _assets = ['assets/data/netanya_neighborhoods.geojson'];

  List<ZoneBoundary>? _zones;
  Future<List<ZoneBoundary>>? _loading;

  Future<List<ZoneBoundary>> _load() async {
    final zones = <ZoneBoundary>[];
    for (final asset in _assets) {
      try {
        final raw = await rootBundle.loadString(asset);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        for (final feature in (json['features'] as List)) {
          final f = feature as Map<String, dynamic>;
          final props = f['properties'] as Map<String, dynamic>;
          final name = props['name'] as String?;
          final geometry = f['geometry'] as Map<String, dynamic>;
          if (name == null || geometry['type'] != 'Polygon') continue;

          // GeoJSON [lng, lat] → ours [lat, lng]; outer ring only.
          final ring = ((geometry['coordinates'] as List)[0] as List)
              .map<List<double>>((p) => [
                    (p[1] as num).toDouble(),
                    (p[0] as num).toDouble(),
                  ])
              .toList();
          if (ring.length < 4) continue;

          zones.add(ZoneBoundary(
            id: 'local/${props['city'] ?? asset}/$name',
            name: name,
            adminZoom: 14,
            rings: [ring],
          ));
        }
      } catch (e, st) {
        logError(e, st, context: 'map.localZones.load', report: true);
      }
    }
    return zones;
  }

  /// The bundled zone containing (lat, lng), or null. Loads lazily once.
  Future<ZoneBoundary?> boundaryAt(double lat, double lng) async {
    _zones ??= await (_loading ??= _load());
    for (final zone in _zones!) {
      if (zone.containsPoint(lat, lng)) return zone;
    }
    return null;
  }
}
