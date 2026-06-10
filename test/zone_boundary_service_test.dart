import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/features/map/services/zone_boundary_service.dart';

void main() {
  group('ZoneBoundaryService.adminZoomFor', () {
    test('maps camera zoom to admin bands', () {
      expect(ZoneBoundaryService.adminZoomFor(1.0), 3); // world → country
      expect(ZoneBoundaryService.adminZoomFor(3.9), 3);
      expect(ZoneBoundaryService.adminZoomFor(5.0), 5); // state
      expect(ZoneBoundaryService.adminZoomFor(7.0), 8); // county/district
      expect(ZoneBoundaryService.adminZoomFor(10.0), 10); // city
      expect(ZoneBoundaryService.adminZoomFor(12.0), 12); // borough
      expect(ZoneBoundaryService.adminZoomFor(15.0), 14); // neighbourhood
      expect(ZoneBoundaryService.adminZoomFor(20.0), 14);
    });
  });

  group('ZoneBoundary.fromNominatim', () {
    test('parses a Polygon result and swaps to [lat,lng]', () {
      final boundary = ZoneBoundary.fromNominatim({
        'osm_type': 'relation',
        'osm_id': 1382494,
        'name': 'ישראל',
        'display_name': 'Israel',
        'geojson': {
          'type': 'Polygon',
          'coordinates': [
            [
              [34.2, 29.5],
              [35.9, 29.5],
              [35.9, 33.3],
              [34.2, 33.3],
              [34.2, 29.5],
            ],
          ],
        },
      }, 3);

      expect(boundary, isNotNull);
      expect(boundary!.id, 'relation/1382494');
      expect(boundary.name, 'ישראל');
      expect(boundary.adminZoom, 3);
      expect(boundary.rings, hasLength(1));
      // GeoJSON [lng, lat] → ours [lat, lng]
      expect(boundary.rings.first.first, [29.5, 34.2]);
      // Tel Aviv area is inside, Cairo is not
      expect(boundary.containsPoint(32.08, 34.78), isTrue);
      expect(boundary.containsPoint(30.04, 31.24), isFalse);
    });

    test('parses MultiPolygon keeping one outer ring per part', () {
      final boundary = ZoneBoundary.fromNominatim({
        'osm_type': 'relation',
        'osm_id': 42,
        'display_name': 'Islands',
        'geojson': {
          'type': 'MultiPolygon',
          'coordinates': [
            [
              [
                [0.0, 0.0],
                [1.0, 0.0],
                [1.0, 1.0],
                [0.0, 1.0],
                [0.0, 0.0],
              ],
              // hole — must be dropped
              [
                [0.4, 0.4],
                [0.6, 0.4],
                [0.6, 0.6],
                [0.4, 0.6],
                [0.4, 0.4],
              ],
            ],
            [
              [
                [10.0, 10.0],
                [11.0, 10.0],
                [11.0, 11.0],
                [10.0, 11.0],
                [10.0, 10.0],
              ],
            ],
          ],
        },
      }, 10);

      expect(boundary, isNotNull);
      expect(boundary!.rings, hasLength(2));
      expect(boundary.containsPoint(0.5, 0.5), isTrue);
      expect(boundary.containsPoint(10.5, 10.5), isTrue);
      expect(boundary.containsPoint(5.0, 5.0), isFalse);
    });

    test('returns null for Point geometry and missing fields', () {
      expect(
        ZoneBoundary.fromNominatim({
          'osm_type': 'node',
          'osm_id': 7,
          'geojson': {
            'type': 'Point',
            'coordinates': [34.8, 32.1],
          },
        }, 14),
        isNull,
      );
      expect(ZoneBoundary.fromNominatim({'osm_id': 7}, 3), isNull);
      expect(ZoneBoundary.fromNominatim({'error': 'Unable to geocode'}, 3),
          isNull);
    });
  });
}
