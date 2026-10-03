part of '../../screens/map_screen.dart';

/// Transparent banner shown under the search bar when the zone filter is
/// on. Displays the current zone label and a settings gear that opens
/// an inline popover (zone settings) directly below the banner.
class _ZoneStatusBanner extends ConsumerWidget {
  const _ZoneStatusBanner();

  Achievement? _findById(WidgetRef ref, String id) {
    final achievements = ref.read(achievementsProvider).allAchievements;
    for (final a in achievements) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    if (!filter.zoneFilterEnabled) return const SizedBox.shrink();

    final settingsOpen = ref.watch(mapZoneSettingsOpenProvider);
    final currentCountry = ref.watch(currentCountryProvider);
    final selectedCountry = filter.zoneCountryAchievementId != null
        ? _findById(ref, filter.zoneCountryAchievementId!)
        : null;
    final selectedContinent = filter.zoneContinentAchievementId != null
        ? _findById(ref, filter.zoneContinentAchievementId!)
        : null;
    final String label = switch (filter.zoneMode) {
      ZoneMode.radius =>
        '${filter.zoneRadiusKm.toStringAsFixed(0)} km around you',
      ZoneMode.country =>
        (selectedCountry ?? currentCountry)?.title ?? 'your location',
      ZoneMode.continent =>
        selectedContinent?.title.replaceFirst('Visit ', '').replaceAll('!', '')
            ?? 'pick a continent',
      ZoneMode.unlimited => 'no limit',
    };

    void toggleSettings() {
      HapticFeedback.selectionClick();
      ref.read(mapZoneSettingsOpenProvider.notifier).state = !settingsOpen;
    }

    // White text with a primary-color glow outline. Sits just under the
    // search bar (small top margin) and never grows the top bar — the
    // settings popover renders separately as a map overlay.
    //
    // Layout: a Stack so the text is truly centered across the full width,
    // with the gear icon pinned to the right edge as an overlay. The pin
    // icon is inlined as a WidgetSpan so it stays glued to the text.
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Reserve symmetric horizontal space for the gear so the centered
          // text doesn't overlap it.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: RichText(
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.95),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      blurRadius: 14,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 3,
                    ),
                  ],
                ),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(LucideIcons.mapPin,
                          size: 14,
                          color: AppColors.primary.withValues(alpha: 0.95),
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withValues(alpha: 0.7),
                              blurRadius: 8,
                            ),
                          ]),
                    ),
                  ),
                  const TextSpan(text: 'Showing pinpoints within: '),
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: AppColors.primary,
                          blurRadius: 10,
                        ),
                        Shadow(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          blurRadius: 18,
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.9),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
            onTap: toggleSettings,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                settingsOpen
                    ? LucideIcons.x
                    : LucideIcons.settings2,
                size: 18,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

/// Inline popover (NOT a modal sheet) anchored just below the zone
/// status banner. Mode toggle (country / continent / radius / unlimited)
/// + per-mode controls.
class _ZoneSettingsPopover extends ConsumerWidget {
  final VoidCallback onClose;
  const _ZoneSettingsPopover({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    final notifier = ref.read(mapFilterProvider.notifier);
    final currentCountry = ref.watch(currentCountryProvider);
    final achievements = ref.watch(achievementsProvider).allAchievements;

    Achievement? findById(String id) {
      for (final a in achievements) {
        if (a.id == id) return a;
      }
      return null;
    }

    final selectedCountry = filter.zoneCountryAchievementId != null
        ? findById(filter.zoneCountryAchievementId!)
        : null;
    final selectedContinent = filter.zoneContinentAchievementId != null
        ? findById(filter.zoneContinentAchievementId!)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.settings2,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Zone settings',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(LucideIcons.x,
                      size: 14, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ZoneModeSegmented(
              selected: filter.zoneMode,
              onChanged: (m) {
                HapticFeedback.selectionClick();
                notifier.setZoneMode(m);
              },
            ),
            const SizedBox(height: 12),
            if (filter.zoneMode == ZoneMode.country)
              _CountryPicker(
                achievements: achievements,
                currentCountry: currentCountry,
                selected: selectedCountry,
                onPick: (id) => notifier.setZoneCountry(id),
              ),
            if (filter.zoneMode == ZoneMode.continent)
              _ContinentPicker(
                achievements: achievements,
                selected: selectedContinent,
                onPick: (id) => notifier.setZoneContinent(id),
              ),
            if (filter.zoneMode == ZoneMode.radius) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Radius',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${filter.zoneRadiusKm.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor:
                      AppColors.textMuted.withValues(alpha: 0.25),
                  thumbColor: AppColors.primary,
                  overlayColor:
                      AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: filter.zoneRadiusKm.clamp(10, 2000).toDouble(),
                  min: 10,
                  max: 2000,
                  divisions: 199,
                  onChanged: (v) =>
                      notifier.setZoneRadiusKm(v.roundToDouble()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('10 km',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                  Text('2000 km',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
    );
  }
}

/// Two-button segmented control — "By country" vs "By zone".
class _ZoneModeSegmented extends StatelessWidget {
  final ZoneMode selected;
  final ValueChanged<ZoneMode> onChanged;

  const _ZoneModeSegmented({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          _segment(
            icon: LucideIcons.flag,
            label: 'Country',
            active: selected == ZoneMode.country,
            onTap: () => onChanged(ZoneMode.country),
          ),
          _segment(
            icon: LucideIcons.globe,
            label: 'Continent',
            active: selected == ZoneMode.continent,
            onTap: () => onChanged(ZoneMode.continent),
          ),
          _segment(
            icon: LucideIcons.target,
            label: 'Zone',
            active: selected == ZoneMode.radius,
            onTap: () => onChanged(ZoneMode.radius),
          ),
          _segment(
            icon: LucideIcons.infinity,
            label: 'All',
            active: selected == ZoneMode.unlimited,
            onTap: () => onChanged(ZoneMode.unlimited),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 12,
                  color: active ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
