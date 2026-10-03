import 'package:flutter/material.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

/// Returns the fill color to use when drawing the claim polygon of [a] on
/// the map overlay. Designed so each continent is visually distinct and each
/// country gets a unique hue — even neighboring countries read as separate.
Color colorForArea(Achievement a) {
  // Continents: hand-picked palette for max contrast with each other
  if (a.id.startsWith('continent-')) {
    return _continentColors[a.id] ?? Colors.grey;
  }
  // Country / zone / state: hash the id to a hue so every polygon gets a
  // unique color. High saturation + mid lightness = strong, visible shade.
  final hue = (a.id.hashCode.abs() % 360).toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.75, 0.48).toColor();
}

/// Returns a single color representing a collection on the map (used for
/// the collection-level "hull" overlay that bounds all member areas).
Color colorForCollection(String collectionId) {
  final preset = _collectionColors[collectionId];
  if (preset != null) return preset;
  final hue = (collectionId.hashCode.abs() % 360).toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.7, 0.45).toColor();
}

const _collectionColors = <String, Color>{
  'continents': Color(0xFF7E57C2), // purple
  'europe': Color(0xFF3866BE), // blue
  'africa': Color(0xFFCB5A38), // terracotta
  'asia': Color(0xFFBC3535), // red
  'americas': Color(0xFF46A455), // green
  'south-america': Color(0xFFCC8128), // amber
  'oceania': Color(0xFF26A69E), // teal
  'antarctica': Color(0xFFB0BEC5), // pale ice blue-grey
  'zones': Color(0xFF8D6E63), // brown
  'capitals': Color(0xFFD4AC0D), // gold
  'national-parks': Color(0xFF2E7D32), // deep green
  'ski-resorts': Color(0xFF00BCD4), // cyan
  'landmarks': Color(0xFF5D4037), // brown
  'beaches': Color(0xFF00ACC1), // cyan
  'parks': Color(0xFF558B2F), // olive green
  'culture': Color(0xFFD81B60), // magenta
  'ancient-sites': Color(0xFF8D6E63), // stone
  'holy-sites': Color(0xFFB07A2E), // sacred amber
  'tourist-destinations': Color(0xFFF57C00), // orange
  'lakes': Color(0xFF1E88E5), // bright lake blue
  'seas': Color(0xFF0277BD), // deep ocean blue
  'glaciers': Color(0xFF80DEEA), // pale ice blue
};

const _continentColors = <String, Color>{
  'continent-africa': Color(0xFFCB5A38), // terracotta
  'continent-asia': Color(0xFFBC3535), // warm red
  'continent-europe': Color(0xFF3866BE), // blue
  'continent-americas': Color(0xFF46A455), // green
  'continent-south-america': Color(0xFFCC8128), // amber
  'continent-oceania': Color(0xFF26A69E), // teal
  'continent-antarctica': Color(0xFFB0BEC5), // pale ice blue-grey
};
