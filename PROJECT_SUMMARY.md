# Travel Buddy — Project Summary

> A gamified travel companion app (Flutter). Explore the real world, unlock
> location-based achievements, complete quests, level up skills, and climb a
> leaderboard — all driven by your actual GPS position.

This document is the onboarding overview for collaborators: what the app does,
how it's put together, where to find things, and a running list of things to
build next.

---

## 1. The app in one paragraph

Travel Buddy turns travel into a game. As you physically move around, the app
detects nearby points of interest and lets you **claim achievements** (trophies)
for places you visit — beaches, landmarks, national parks, capitals, whole
countries and continents. Visiting places earns **XP**, which raises your
**level** and your per-category **skill levels**. **Quests** give structured,
multi-step goals; **quest chains** string quests together for bigger rewards. A
live **map** shows everything around you with rich filtering, and a
**leaderboard** ranks you against other travelers. The whole experience is
location-aware: a background service watches your position and surfaces things
to do in your current **zone**.

---

## 2. Tech stack at a glance

| Area | Choice |
|------|--------|
| Framework | Flutter (Dart) |
| State management | Riverpod (`flutter_riverpod`) |
| Routing | `go_router` (shell route + auth redirect) |
| Backend / auth / data | Supabase (`supabase_flutter`) |
| Maps | Mapbox (`mapbox_maps_flutter`) |
| Location | `geolocator`, `geocoding` |
| Local notifications | `flutter_local_notifications` |
| Background work | `flutter_background_service` |
| Crash/error reporting | Sentry (`sentry_flutter`) |
| Local storage | `shared_preferences` |
| Charts | `fl_chart` |
| Media | `image_picker`, `cached_network_image`, `flutter_svg` |
| Icons / fonts | `lucide_icons`, `google_fonts` |
| Polish | `flutter_animate`, `shimmer`, `confetti` |
| Localization | English + Hebrew (RTL) via `flutter_localizations` |

Secrets (Supabase, Mapbox, Sentry) are injected at build time with
`--dart-define-from-file=.env` — see [Build & run](#8-build--run).

---

## 3. Architecture at a glance

**Feature-first layering.** Code lives under `lib/features/<feature>/` with a
consistent internal split:

```
lib/
  core/            # router, theme, app-wide utils
  features/<name>/
    data/          # repositories, Supabase access
    models/        # feature-local models (where present)
    providers/     # feature-local Riverpod providers (where present)
    presentation/
      screens/     # full screens / routes
      widgets/     # reusable + screen-private widgets
  shared/
    models/        # cross-feature domain models
    providers/     # cross-feature Riverpod providers (the app's "brain")
    services/      # background, notifications, persistence, photos, etc.
    data/          # static registries (achievements, quests, skills, …)
    widgets/       # shared UI (app shell, XP bars, popups, …)
  l10n/            # localization (en / he) + registry translations
```

**State.** Riverpod providers in `lib/shared/providers/` hold the domain state
(achievements, quests, skills, zones, geolocation, user profile, leaderboard,
notifications). Screens watch providers and stay mostly declarative.

**Navigation.** `core/router/app_router.dart` defines a `ShellRoute`
(`AppShell` = bottom nav + persistent map) wrapping the tab screens, plus
top-level routes for auth, profile sub-pages, skill/activity details, and the
dev panel. An auth redirect sends unauthenticated users to `/auth`.

**Static content as "registries."** A lot of the game's content (the catalog of
achievements, quests, skills, collections) is defined as large static data
files in `lib/shared/data/*_registry.dart`. These are intentionally big — they
are data, not logic.

**Screen-splitting convention (`part` libraries).** Several large screens were
refactored so the screen file holds the stateful logic and its sibling widget
classes live in sibling `part` files under a `screen_parts/` (or
`detail_sheet_parts/`) folder. They share one library scope via
`part` / `part of`, so private names and imports are preserved with zero
call-site changes. If you open a screen and see `part '...'` directives at the
top, the widgets are in that adjacent folder. See
[Recent work](#7-recent-work-codebase-health).

---

## 4. Feature list

### Core shell & navigation
The `AppShell` provides the bottom navigation and hosts the map persistently
(so its camera/zoom/native view survive tab switches). Tabs: **Home**, **Map**,
**Quests**, **Skills**, **Achievements**, **Leaderboard**, **Profile**, plus an
**Activity Log**.

### Home dashboard (`/`) — map-first canvas
Home is a **draggable dashboard sheet over the live map** (Bump/Zenly model):
the persistent map shows through as a full-bleed canvas (in "backdrop mode" —
bare map, no chrome; see `mapBackdropProvider`), with floating level/location/
streak chips on the exposed area and the dashboard in a snap-anchored sheet
(collapsed / peek / full). The sheet content is the classic dashboard: unified
profile card (level, XP progress, streak), pending trophy claims, pending
quest-chain claims, a **Nearby Zone** card, top skills, an achievement
breakdown, and the tabbed **Collections** explorer. On a cold start the canvas
opens on the globe and dives to the user's location at first GPS fix.
Tapping Explore opens the full map experience (`/map`) — the canvas never
reloads, only the chrome changes.

### Interactive map (`/map`)
A full Mapbox map centered on the user. Renders achievement/quest/skill markers,
supports tapping pins for popups and detail sheets, search, an immersive
full-screen mode, and a powerful **filter system**:
- **Zone filter** with modes: radius (km around you), country, continent, or
  unlimited.
- **Unified filter sheet** to toggle achievement collections, activities,
  quests, and visibility groups.
- Unlocked-area overlays drawn on the map.

### Achievements (`/achievements`)
The trophy system — the heart of the app.
- Achievements are grouped into **collections** (beaches, landmarks, parks,
  culture, national-parks, ski-resorts, capitals, ancient-sites, holy-sites,
  seas, tourist-destinations, countries, continents, zones).
- Organized by **geographic tier**: Zone → Country → Continent → Global
  (bronze/silver/gold/platinum coloring), shown as an expandable cascade with an
  **Explore** tab and an **Unlock Timeline** tab.
- **Claiming flow:** when you're near an eligible place it becomes a *pending
  claim*; claiming awards XP with an unlock popup (and confetti). Supports
  **claim-all** batching.
- **Revisits:** returning to an already-unlocked place can be acknowledged as a
  repeat visit.
- **Retroactive claims:** claim places you've clearly already been to.
- **Detail sheet** per achievement: rich info pulled from Supabase on demand
  (photos, opening hours, website), visit history, and the ability to **add a
  photo or a personal remark**.

### Quests (`/quests`)
Structured goals with tabs for Active / Claimable / Available / Completed.
- **Quests** have multiple steps; completing steps progresses the quest.
- **Quest chains** link quests in sequence for larger payoffs; chains are
  started manually, steps auto-complete as conditions are met, and finished
  quests become claimable.
- A **quest detail sheet** shows steps and progress.

### Skills & activities (`/skills`)
A character-sheet style progression layer.
- **Skill groups** (categories) each have levels and XP-per-level.
- Browse by category or as a flat list, with a grid/list toggle and column
  picker.
- **Skill detail** (`/skills/:skillId`) and **activity detail**
  (`/skills/:skillId/activity/:activityId`) screens. Activities are the
  "side quests" tied to skills.

### Zones (location context)
A live sense of "where am I and what's here." The zone providers
(`zone_provider`, `zone_content_provider`) compute the current area and the
achievements/activities/quests within it, feeding the Home **Nearby Zone** card
and the map's zone filter.

### Gamification / XP
Cross-cutting reward system: total **XP** and **level**, per-skill levels,
**streaks**, animated counters, XP progress bars, unlock popups, and confetti.

### Leaderboard (`/leaderboard`)
Ranks travelers (backed by Supabase via `leaderboard_service`).

### Profile & settings (`/profile`)
User profile with avatar, stats, and sub-pages: **Edit profile**
(`/profile/edit`), **Privacy settings** (`/profile/privacy`), and **App
settings** (`/profile/settings`).

### Activity log (`/log`)
A running history/timeline of the user's actions and unlocks.

### Notifications & background service
A background service monitors location and fires **proximity notifications**
when you're near claimable content, with cooldowns to avoid spam. (See the
notification/revisit system code map for the full picture.)

### Authentication (`/auth`)
Supabase-backed auth. The router redirects unauthenticated users to `/auth` and
authenticated users away from it.

### Dev panel (`/dev-panel`) — internal tools
Not user-facing. Includes **GPS spoofing**, **achievement editor**, **quest
editor**, **data management**, **debug tools**, a **polygon editor** (for
drawing zone boundaries), and a **change history** view. Invaluable for testing
location-based features without physically traveling.

### Localization
Full English + Hebrew support, including RTL layout and translated content
registries.

---

## 5. Codebase map (where to find things)

| You want to… | Look in |
|--------------|---------|
| Add/adjust a route | `lib/core/router/app_router.dart` |
| Change theme/colors | `lib/core/theme/app_theme.dart` (`AppColors`) |
| Touch domain state | `lib/shared/providers/*` |
| Edit the achievement/quest/skill catalog | `lib/shared/data/*_registry.dart` |
| Work on a screen | `lib/features/<feature>/presentation/screens/` |
| Find a screen's sub-widgets | adjacent `screen_parts/` / `detail_sheet_parts/` folder |
| Background/notifications/persistence | `lib/shared/services/*` |
| Localization strings | `lib/l10n/*` |

---

## 6. Domain glossary

- **Achievement / trophy** — a claimable reward for visiting a place. Has a
  collection, a tier (bronze→platinum), an XP reward, and unlock/visit state.
- **Collection** — a themed group of achievements (e.g. `beaches`, `capitals`).
- **Geo-tier** — difficulty/scope cascade: Zone → Country → Continent → Global.
- **Quest** — a multi-step goal. **Quest chain** — an ordered series of quests.
- **Activity / side quest** — a smaller task tied to a skill.
- **Skill group** — a category with levels and XP.
- **Zone** — the user's current geographic area and the content inside it.
- **Pending claim / revisit / retroactive claim** — the three ways an
  achievement transitions toward "unlocked."

---

## 7. Recent work (codebase health)

A round of structural refactoring split the largest "god files" — screens that
had grown to 1,000–3,000 lines — into focused `part` libraries. Behavior is
unchanged (verified by `flutter analyze` and a release build); the goal was
navigability. Files addressed: `home_screen`, `map_screen`,
`achievements_screen`, `quests_screen`, `skills_screen`, `unified_filter_sheet`,
`achievement_detail_sheet`.

**Known remaining cleanup (optional):** a few very large `build()` methods still
live inside their state classes (`_MapScreenState`, `_UnifiedFilterSheetState`,
`_SheetContent`). Breaking those up means extracting build sub-trees into new
helper widgets — real refactoring with behavior risk, not a mechanical move — so
it was deliberately left for a focused, separately-tested pass.

**Server-authoritative XP (2026-06-10).** `profiles.total_xp` / `level` /
`is_premium` are now server-owned: clients can no longer write them
(column-level grants), and XP is awarded by database triggers on the rows
clients already sync (`user_achievements`, `user_quest_completions`,
`user_completed_collections`, `user_master_achievements`), priced from seeded
`*_definitions` tables and recorded idempotently in an `xp_ledger`. The
formulas live in `lib/shared/utils/xp_rules.dart` and are mirrored by the SQL
in `supabase/migrations/20260610000002_server_authoritative_xp.sql` — change
both together. Seeds are generated from the Dart registries by
`dart run tool/generate_xp_seed_migration.dart`. First real unit tests landed
alongside (`test/xp_rules_test.dart`, `test/achievement_merge_test.dart`).

---

## 8. Build & run

```bash
flutter pub get
flutter run --dart-define-from-file=.env       # debug, secrets embedded
```

Release APK (per project convention — always release, always embed `.env`):

```bash
# JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
flutter build apk --release --dart-define-from-file=.env
# → build/app/outputs/flutter-apk/app-release.apk
```

`.env` holds `SUPABASE_*`, `MAPBOX_TOKEN`, and `SENTRY_*`. Ask the project owner
for the file — it is not committed.

Branching: `main` (production), `develop` (integration), `feature/*` for work.

---

## 9. Potential updates / TODO

> Collaborator section — add proposed features and tasks below. Suggested format:
> `- [ ] **Title** — what & why. (size: S/M/L)`

### Content / gameplay
- [ ] _e.g._ Populate **Asia / Africa / Oceania** achievements (Home currently
  marks these continents "coming soon"). (size: ?)
- [ ]

### Features
- [ ]

### UX / polish
- [ ]

### Tech / refactoring
- [ ] Decompose the remaining large `build()` methods into helper widgets
  (`_MapScreenState`, `_UnifiedFilterSheetState`, `_SheetContent`). (size: M)
- [ ]

### Bugs / known issues
- [ ]

---

_Last updated: 2026-06-05._
