import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart'
    show achievementRegistry;
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';

/// Rough region centers — every place must sit within [_maxKmFromRegion] of
/// its region's center, which catches swapped lat/lng and typos.
const _regionCenters = <IsraelRegion, (double, double)>{
  IsraelRegion.golan: (33.00, 35.75),
  IsraelRegion.upperGalilee: (33.05, 35.55),
  IsraelRegion.westernGalilee: (32.98, 35.15),
  IsraelRegion.kinneret: (32.82, 35.57),
  IsraelRegion.lowerGalilee: (32.73, 35.35),
  IsraelRegion.valleys: (32.57, 35.33),
  IsraelRegion.haifaCarmel: (32.72, 35.00),
  IsraelRegion.sharon: (32.28, 34.88),
  IsraelRegion.telAviv: (32.07, 34.82),
  IsraelRegion.shfela: (31.78, 34.80),
  IsraelRegion.judeanHills: (31.77, 35.08),
  IsraelRegion.jerusalem: (31.77, 35.21),
  IsraelRegion.deadSea: (31.40, 35.40),
  IsraelRegion.northernNegev: (31.15, 34.85),
  IsraelRegion.negevHighlands: (30.70, 34.80),
  IsraelRegion.arava: (30.30, 35.10),
  IsraelRegion.eilat: (29.56, 34.94),
};

const _maxKmFromRegion = 50.0;

/// The Arava is a ~170 km valley; one center cannot describe it.
const _maxKmFromArava = 90.0;

void main() {
  test('ids are unique, prefixed and do not collide with other registries', () {
    final ids = israelPlaces.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate Israel id');
    for (final id in ids) {
      expect(id, startsWith('il-'));
      expect(id, matches(RegExp(r'^[a-z0-9-]+$')), reason: id);
    }

    final allIds = achievementRegistry.map((a) => a.id).toList();
    expect(allIds.toSet().length, allIds.length,
        reason: 'Israel id collides with an existing achievement');
  });

  test('every place is inside Israel and near its region', () {
    for (final p in israelPlaces) {
      expect(p.lat, inInclusiveRange(29.45, 33.35), reason: p.id);
      expect(p.lng, inInclusiveRange(34.25, 35.90), reason: p.id);

      final (cLat, cLng) = _regionCenters[p.region]!;
      final km = haversineMeters(p.lat, p.lng, cLat, cLng) / 1000;
      final maxKm = p.region == IsraelRegion.arava
          ? _maxKmFromArava
          : _maxKmFromRegion;
      expect(km, lessThan(maxKm),
          reason: '${p.id} is ${km.round()} km from ${p.region.name}');
    }
  });

  test('no two places share the exact same point', () {
    final seen = <String, String>{};
    for (final p in israelPlaces) {
      final key = '${p.lat},${p.lng}';
      expect(seen.containsKey(key), isFalse,
          reason: '${p.id} sits on ${seen[key]}');
      seen[key] = p.id;
    }
  });

  test('every place has Hebrew and English text and a sane radius', () {
    for (final p in israelPlaces) {
      expect(p.title.trim(), isNotEmpty, reason: p.id);
      expect(p.description.trim(), isNotEmpty, reason: p.id);
      expect(RegExp(r'[֐-׿]').hasMatch(p.he), isTrue,
          reason: '${p.id} Hebrew title "${p.he}"');
      final a = p.toAchievement();
      expect(a.claimRadius, inInclusiveRange(100, 40000), reason: p.id);
      expect(a.hasGeofence, isTrue, reason: p.id);
    }
  });

  test('every list and region is populated, and every region has its own achievement', () {
    for (final l in IsraelList.values) {
      expect(israelPlaces.where((p) => p.list == l), isNotEmpty, reason: l.id);
      expect(getCollectionInfo(l.id), isNotNull, reason: l.id);
    }
    for (final r in IsraelRegion.values) {
      expect(israelPlaces.where((p) => p.region == r).length,
          greaterThanOrEqualTo(3), reason: r.id);
      expect(
          israelPlaces.where(
              (p) => p.list == IsraelList.regions && p.region == r),
          hasLength(1),
          reason: 'region achievement for ${r.id}');
    }
  });

  test('achievements carry region and facet tags', () {
    for (final p in israelPlaces) {
      final a = p.toAchievement();
      expect(IsraelRegion.fromTags(a.tags), p.region, reason: p.id);
      final facets = a.tags.map(IsraelFacet.fromTag).whereType<IsraelFacet>();
      expect(facets, isNotEmpty, reason: p.id);
    }
  });

  test('catalog size (printed for the record)', () {
    final byList = <String, int>{
      for (final l in IsraelList.values)
        l.id: israelPlaces.where((p) => p.list == l).length,
    };
    // ignore: avoid_print
    print('Israel places: ${israelPlaces.length} $byList');
    expect(israelPlaces.length, greaterThanOrEqualTo(250));
  });
}
