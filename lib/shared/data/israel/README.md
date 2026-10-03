# Israel Explorer data

MTP-style lists of places across Israel. Each place becomes a normal
geofenced achievement (`il-` id), so GPS detection, claiming, revisits, XP
and sync work without special cases. Each place also has a region and a set
of facets, which the profile turns into per-person data.

| File | What's in it |
| --- | --- |
| `israel_catalog.dart` | The model: `IsraelList` (14 lists), `IsraelRegion` (17 regions), `IsraelFacet` (12 Traveler-DNA facets), `IsraelPlace` |
| `israel_places_cities.dart` | Region achievements, cities & towns, villages |
| `israel_places_north.dart` | Golan, Galilee, Kinneret, valleys, Haifa & Carmel |
| `israel_places_center.dart` | Sharon, Tel Aviv & Gush Dan, Judean Lowlands |
| `israel_places_jerusalem.dart` | Jerusalem and the Judean Hills |
| `israel_places_south.dart` | Dead Sea, Negev, Arava, Eilat |
| `israel_places_more.dart` | Second and third waves across all regions |
| `israel_master_achievements.dart` | Combo, region, facet and list masters, with Hebrew text |
| `israel_activity_quests.dart` | Israel activities (side quests), with Hebrew text |

## Adding a place

1. Add an `IsraelPlace` to the file for its area: `il-` id, English title,
   Hebrew title, list, region, lat/lng, short description. Set `radius` for
   anything that isn't a point (parks, craters, beaches). Set `tier` for
   must-sees, and `facets` beyond the list's defaults.
2. Run `flutter test test/israel_catalog_test.dart`. It checks ids,
   coordinates against the region, duplicate points and Hebrew text.
3. Regenerate the server seed with
   `dart run tool/generate_israel_seed_migration.dart`. The server only
   awards XP for ids it knows. Then apply the migration file to Supabase.

Don't duplicate places that already exist in the other registries. The
Netanya spots, the Western Wall, the Holy Sepulchre, Al-Aqsa, the Bahá'í
Gardens, the Sea of Galilee and the Dead Sea are all there already.
