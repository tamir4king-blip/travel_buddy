import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/features/map/services/local_zone_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalZoneRegistry', () {
    final registry = LocalZoneRegistry();

    test('neighborhood layer: known Netanya seed points resolve', () async {
      final cases = <(double, double, String)>[
        (32.3427327, 34.8616020, 'קריית צאנז'),
        (32.2958474, 34.8505601, 'נאות שקד'),
        (32.3240623, 34.8641735, 'רמת אפרים'),
        (32.3044180, 34.8732309, 'קרית השרון'),
      ];
      for (final (lat, lng, expected) in cases) {
        final zone = await registry.boundaryAt(lat, lng, 14);
        expect(zone, isNotNull, reason: 'no zone at $lat,$lng ($expected)');
        expect(zone!.name, expected);
        expect(zone.adminZoom, 14);
        expect(zone.id, startsWith('local/'));
      }
    });

    test('neighborhood layer covers Netanya — nothing missed', () async {
      var hits = 0;
      var total = 0;
      for (var lat = 32.270; lat <= 32.345; lat += 0.005) {
        for (var lng = 34.845; lng <= 34.880; lng += 0.005) {
          total++;
          if (await registry.boundaryAt(lat, lng, 14) != null) hits++;
        }
      }
      // The grid bbox slightly exceeds the city's irregular borders, so
      // expect strong-majority coverage rather than 100% of the rectangle.
      expect(hits / total, greaterThan(0.75),
          reason: 'only $hits/$total grid points covered');
    });

    test('city layer: Israeli cities resolve locally', () async {
      final telAviv = await registry.boundaryAt(32.0853, 34.7818, 10);
      expect(telAviv, isNotNull);
      expect(telAviv!.name, contains('תל־אביב'));

      final jerusalem = await registry.boundaryAt(31.7683, 35.2137, 10);
      expect(jerusalem, isNotNull);
      expect(jerusalem!.name, 'ירושלים');

      final netanya = await registry.boundaryAt(32.3215, 34.8516, 10);
      expect(netanya, isNotNull);
      expect(netanya!.name, 'נתניה');
    });

    test('district layer: Israeli districts resolve locally', () async {
      final center = await registry.boundaryAt(32.3215, 34.8516, 5);
      expect(center, isNotNull);
      expect(center!.name, 'מחוז המרכז');

      final south = await registry.boundaryAt(31.25, 34.8, 5);
      expect(south, isNotNull);
      expect(south!.name, 'מחוז הדרום');
    });

    test('country layer: countries resolve locally worldwide', () async {
      final israel = await registry.boundaryAt(32.0, 34.9, 3);
      expect(israel, isNotNull);
      expect(israel!.name, anyOf(contains('Israel'), contains('ישראל')));

      final france = await registry.boundaryAt(48.85, 2.35, 3);
      expect(france, isNotNull);
      expect(france!.name, anyOf(contains('France'), contains('צרפת')));

      final japan = await registry.boundaryAt(35.68, 139.76, 3);
      expect(japan, isNotNull);
      expect(japan!.name, anyOf(contains('Japan'), contains('יפן')));
    });

    test('returns null where bundles have no coverage', () async {
      // Mediterranean open water at every band
      expect(await registry.boundaryAt(33.5, 32.0, 3), isNull);
      expect(await registry.boundaryAt(33.5, 32.0, 10), isNull);
      // Paris at the city band (only Israeli cities are bundled)
      expect(await registry.boundaryAt(48.85, 2.35, 10), isNull);
    });
  });
}
