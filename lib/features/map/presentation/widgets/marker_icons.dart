import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Maps an achievement `collectionId` to the icon drawn inside its map pin.
/// Unknown collections fall back to a generic map-pin icon.
IconData iconForCollection(String? collectionId) {
  return switch (collectionId) {
    // Local collections
    'landmarks' => LucideIcons.landmark,
    'beaches' => LucideIcons.umbrella,
    'parks' => LucideIcons.palmtree,
    'culture' => LucideIcons.palette,
    // Themed / global collections
    'national-parks' => LucideIcons.trees,
    'ski-resorts' => LucideIcons.snowflake,
    'capitals' => LucideIcons.building2,
    'ancient-sites' => LucideIcons.church,
    'holy-sites' => LucideIcons.church,
    'seas' => LucideIcons.waves,
    'glaciers' => LucideIcons.snowflake,
    'tourist-destinations' => LucideIcons.mapPin,
    // Continent + country collections → flag
    'continents' => LucideIcons.globe,
    'europe' => LucideIcons.flag,
    'asia' => LucideIcons.flag,
    'africa' => LucideIcons.flag,
    'americas' => LucideIcons.flag,
    'south-america' => LucideIcons.flag,
    'oceania' => LucideIcons.flag,
    // Zones
    'zones' => LucideIcons.mapPin,
    _ => LucideIcons.mapPin,
  };
}
