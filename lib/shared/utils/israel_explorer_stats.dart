/// Turns a person's unlocked Israel places into profile data points: list
/// progress, regional coverage, a facet mix ("Traveler DNA") with an
/// archetype, a rank, geographic extremes and signature places.
///
/// Pure Dart so it can be unit tested without widgets.
library;

import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';

/// Explorer ranks, earned by the number of distinct Israel places visited.
enum ExplorerRank {
  newcomer(0, 'Newcomer', 'עולה חדש', '🌱'),
  wanderer(5, 'Wanderer', 'משוטט', '🚶'),
  explorer(20, 'Explorer', 'חוקר', '🧭'),
  trailblazer(50, 'Trailblazer', 'פורץ דרך', '🥾'),
  expert(100, 'Israel Expert', 'מומחה ארץ ישראל', '🏅'),
  legend(200, 'Legend of the Land', 'אגדת הארץ', '👑');

  const ExplorerRank(this.minPlaces, this.name, this.he, this.emoji);

  final int minPlaces;
  final String name;
  final String he;
  final String emoji;

  String label(String languageCode) => languageCode == 'he' ? he : name;

  static ExplorerRank forPlaces(int places) {
    var rank = ExplorerRank.newcomer;
    for (final r in values) {
      if (places >= r.minPlaces) rank = r;
    }
    return rank;
  }

  /// The next rank up, or null at the top.
  ExplorerRank? get next =>
      index + 1 < values.length ? values[index + 1] : null;
}

class ListProgress {
  const ListProgress(this.list, this.unlocked, this.total);

  final IsraelList list;
  final int unlocked;
  final int total;

  double get fraction => total == 0 ? 0 : unlocked / total;
  bool get isComplete => total > 0 && unlocked == total;
}

class FacetShare {
  const FacetShare(this.facet, this.count, this.share);

  final IsraelFacet facet;
  final int count;

  /// Share of all facet hits, 0..1.
  final double share;
}

class IsraelExplorerStats {
  const IsraelExplorerStats({
    required this.visited,
    required this.total,
    required this.lists,
    required this.regionCounts,
    required this.dna,
    required this.rank,
    this.northernmost,
    this.southernmost,
    this.mostRevisited,
    this.rarest = const [],
  });

  /// Distinct Israel places unlocked.
  final int visited;
  final int total;

  /// Progress per list, in list order.
  final List<ListProgress> lists;

  /// Unlocked places per region (regions with none are absent).
  final Map<IsraelRegion, int> regionCounts;

  /// Facet mix, strongest first. Empty until something is unlocked.
  final List<FacetShare> dna;

  final ExplorerRank rank;
  final Achievement? northernmost;
  final Achievement? southernmost;

  /// The place revisited most (only when visited more than once).
  final Achievement? mostRevisited;

  /// Highest-tier unlocked places, best first (up to 3).
  final List<Achievement> rarest;

  int get regionsVisited => regionCounts.length;
  int get regionsTotal => IsraelRegion.values.length;
  double get fraction => total == 0 ? 0 : visited / total;

  IsraelFacet? get primaryFacet => dna.isEmpty ? null : dna.first.facet;
  IsraelFacet? get secondaryFacet => dna.length < 2 ? null : dna[1].facet;

  /// North-to-south span between the extremes, in km.
  double? get spanKm {
    final n = northernmost, s = southernmost;
    if (n == null || s == null || identical(n, s)) return null;
    return haversineMeters(n.latitude!, n.longitude!, s.latitude!, s.longitude!) /
        1000;
  }

  /// Archetype title — "Desert Wanderer" or "Desert Wanderer × Time
  /// Traveler" when a second facet is close behind.
  String? archetype(String languageCode) {
    final p = primaryFacet;
    if (p == null) return null;
    final s = secondaryFacet;
    final primaryLabel = p.archetypeLabel(languageCode);
    // A strong second facet (at least 60% of the first) joins the title.
    if (s != null && dna[1].count >= dna[0].count * 0.6) {
      return '$primaryLabel × ${s.archetypeLabel(languageCode)}';
    }
    return primaryLabel;
  }

  static IsraelExplorerStats fromAchievements(Iterable<Achievement> all) {
    final israel = all.where(isIsraelAchievement).toList();
    final unlocked = israel.where((a) => a.isUnlocked).toList();

    final lists = [
      for (final l in IsraelList.values)
        ListProgress(
          l,
          unlocked.where((a) => a.collectionId == l.id).length,
          israel.where((a) => a.collectionId == l.id).length,
        ),
    ];

    final regionCounts = <IsraelRegion, int>{};
    final facetCounts = <IsraelFacet, int>{};
    for (final a in unlocked) {
      final region = IsraelRegion.fromTags(a.tags);
      if (region != null) {
        regionCounts[region] = (regionCounts[region] ?? 0) + 1;
      }
      for (final tag in a.tags) {
        final f = IsraelFacet.fromTag(tag);
        if (f != null) facetCounts[f] = (facetCounts[f] ?? 0) + 1;
      }
    }

    final facetTotal = facetCounts.values.fold<int>(0, (s, c) => s + c);
    final dna = [
      for (final e in facetCounts.entries)
        FacetShare(e.key, e.value, facetTotal == 0 ? 0 : e.value / facetTotal),
    ]..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        // Stable, deterministic tie-break by enum order.
        return byCount != 0 ? byCount : a.facet.index.compareTo(b.facet.index);
      });

    // Extremes ignore the wide region geofences — a region's center says
    // nothing about how far north or south the person actually went.
    final pinned = unlocked
        .where((a) => a.collectionId != IsraelList.regions.id && a.latitude != null)
        .toList();
    Achievement? north, south;
    for (final a in pinned) {
      if (north == null || a.latitude! > north.latitude!) north = a;
      if (south == null || a.latitude! < south.latitude!) south = a;
    }

    Achievement? mostRevisited;
    for (final a in unlocked) {
      if (a.visitCount < 2) continue;
      if (mostRevisited == null || a.visitCount > mostRevisited.visitCount) {
        mostRevisited = a;
      }
    }

    final rarest = [...pinned]
      ..sort((a, b) {
        final byTier = b.tier.index.compareTo(a.tier.index);
        if (byTier != 0) return byTier;
        final byXp = b.xpReward.compareTo(a.xpReward);
        return byXp != 0 ? byXp : a.id.compareTo(b.id);
      });

    return IsraelExplorerStats(
      visited: unlocked.length,
      total: israel.length,
      lists: lists,
      regionCounts: regionCounts,
      dna: dna,
      rank: ExplorerRank.forPlaces(unlocked.length),
      northernmost: north,
      southernmost: south,
      mostRevisited: mostRevisited,
      rarest: rarest.take(3).toList(),
    );
  }
}
