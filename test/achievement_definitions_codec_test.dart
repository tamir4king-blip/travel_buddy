import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/utils/achievement_definitions_codec.dart';

Achievement makeDefinition({
  String id = 'spot',
  String title = 'Spot',
  String? iconName,
  double? latitude,
  double? longitude,
  double? claimRadius,
  List<List<double>>? claimPolygon,
  String? collectionId,
  List<String> tags = const [],
}) {
  return Achievement(
    id: id,
    title: title,
    description: 'desc',
    iconName: iconName,
    tier: AchievementTier.silver,
    xpReward: 25,
    latitude: latitude,
    longitude: longitude,
    claimRadius: claimRadius,
    claimPolygon: claimPolygon,
    collectionId: collectionId,
    tags: tags,
  );
}

void main() {
  group('mergeDefinitions', () {
    test('remote overrides hardcoded fields by id', () {
      final merged = mergeDefinitions(
        [makeDefinition(title: 'Old', claimRadius: 100)],
        [makeDefinition(title: 'New', claimRadius: 250)],
      );

      expect(merged, hasLength(1));
      expect(merged.single.title, 'New');
      expect(merged.single.claimRadius, 250);
    });

    test('falls back to hardcoded values remote leaves empty', () {
      final merged = mergeDefinitions(
        [
          makeDefinition(
            iconName: 'beach',
            latitude: 32.3,
            longitude: 34.8,
            claimRadius: 100,
            collectionId: 'netanya',
            tags: const ['sea'],
          ),
        ],
        [makeDefinition()],
      );

      final a = merged.single;
      expect(a.iconName, 'beach');
      expect(a.latitude, 32.3);
      expect(a.longitude, 34.8);
      expect(a.claimRadius, 100);
      expect(a.collectionId, 'netanya');
      expect(a.tags, ['sea']);
      expect(a.hasGeofence, isTrue);
    });

    test('appends remote-only definitions', () {
      final merged = mergeDefinitions(
        [makeDefinition(id: 'a')],
        [makeDefinition(id: 'b', latitude: 1, longitude: 2, claimRadius: 50)],
      );

      expect(merged.map((a) => a.id), ['a', 'b']);
      expect(merged.last.hasGeofence, isTrue);
    });
  });

  test('serialize → parse round-trips definitions including polygons', () {
    final original = [
      makeDefinition(
        id: 'zone',
        claimPolygon: const [
          [32.0, 34.0],
          [32.1, 34.0],
          [32.1, 34.1],
        ],
        collectionId: 'netanya',
        tags: const ['park'],
      ),
    ];

    final parsed = parseDefinitions(serializeDefinitions(original));

    final a = parsed.single;
    expect(a.id, 'zone');
    expect(a.tier, AchievementTier.silver);
    expect(a.xpReward, 25);
    expect(a.claimPolygon, original.single.claimPolygon);
    expect(a.collectionId, 'netanya');
    expect(a.tags, ['park']);
    expect(a.hasPolygon, isTrue);
  });
}
