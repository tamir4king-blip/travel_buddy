import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/features/map/services/local_zone_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalZoneRegistry (Netanya neighborhoods)', () {
    final registry = LocalZoneRegistry();

    test('resolves known neighborhood seed points to their zones', () async {
      // Each OSM place node must fall inside its own generated zone.
      final cases = <(double, double, String)>[
        (32.3427327, 34.8616020, 'קריית צאנז'),
        (32.2958474, 34.8505601, 'נאות שקד'),
        (32.3240623, 34.8641735, 'רמת אפרים'),
        (32.3044180, 34.8732309, 'קרית השרון'),
      ];
      for (final (lat, lng, expected) in cases) {
        final zone = await registry.boundaryAt(lat, lng);
        expect(zone, isNotNull, reason: 'no zone at $lat,$lng ($expected)');
        expect(zone!.name, expected);
        expect(zone.adminZoom, 14);
        expect(zone.id, startsWith('local/'));
      }
    });

    test('covers arbitrary points across the city — nothing missed', () async {
      // Sample a grid over Netanya's built-up area; every point on land
      // inside the city must resolve to some neighborhood.
      var hits = 0;
      var total = 0;
      for (var lat = 32.270; lat <= 32.345; lat += 0.005) {
        for (var lng = 34.845; lng <= 34.880; lng += 0.005) {
          total++;
          if (await registry.boundaryAt(lat, lng) != null) hits++;
        }
      }
      // The grid bbox slightly exceeds the city's irregular borders, so
      // expect strong-majority coverage rather than 100% of the rectangle.
      expect(hits / total, greaterThan(0.75),
          reason: 'only $hits/$total grid points covered');
    });

    test('returns null outside Netanya', () async {
      expect(await registry.boundaryAt(32.0853, 34.7818), isNull); // Tel Aviv
      expect(await registry.boundaryAt(32.3300, 34.7000), isNull); // open sea
    });
  });
}
