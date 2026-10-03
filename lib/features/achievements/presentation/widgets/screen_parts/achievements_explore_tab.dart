part of '../../screens/achievements_screen.dart';

// ══════════════════════════════════════════════════════════════
// Explore Tab
// ══════════════════════════════════════════════════════════════

class _ExploreTab extends ConsumerStatefulWidget {
  const _ExploreTab();

  @override
  ConsumerState<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<_ExploreTab> {
  String? _selectedContinent;
  String? _selectedCountry;

  bool _matchesFilter(Achievement a) {
    if (_localCollectionIds.contains(a.collectionId)) return true;
    if (a.collectionId == 'continents' || a.collectionId == 'zones') return true;
    if (_selectedContinent != null) {
      if (_continentKey(a) != _selectedContinent) return false;
    }
    if (_selectedCountry != null) {
      if (_countryKey(a) != _selectedCountry) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(achievementsProvider).allAchievements;

    // Build dynamic country labels from Countries collection IDs
    final countryLabelsMap = <String, String>{..._countryLabels};
    for (final a in all) {
      if (_continentCollectionIds.contains(a.collectionId)) {
        final key = _countryKey(a);
        if (key != null) countryLabelsMap.putIfAbsent(key, () => a.title);
      }
    }

    // Available countries for selected continent
    List<MapEntry<String, String>> availableCountries = [];
    if (_selectedContinent != null) {
      final countryKeys = <String>{};
      for (final a in all) {
        if (_localCollectionIds.contains(a.collectionId)) continue;
        if (_continentKey(a) != _selectedContinent) continue;
        final ck = _countryKey(a);
        if (ck != null) countryKeys.add(ck);
      }
      availableCountries = countryKeys
          .map((k) => MapEntry(k, countryLabelsMap[k] ?? k))
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
    }

    // Apply filter
    final filtered = all.where(_matchesFilter).toList();

    // ── Group achievements by geographic tier ──

    // GLOBAL: Countries collection + themed collections
    final globalAchievements = filtered
        .where((a) =>
            _continentCollectionIds.contains(a.collectionId) ||
            _themedCollectionIds.contains(a.collectionId))
        .toList();

    // CONTINENTAL: continents collection
    final continentalAchievements = filtered
        .where((a) => a.collectionId == 'continents')
        .toList();

    // COUNTRY: Countries collection grouped per-country (reuse from global)
    final countryAchievements = filtered
        .where((a) => _continentCollectionIds.contains(a.collectionId))
        .toList();

    // ZONE: zones + local collections
    final zoneAchievements = filtered
        .where((a) =>
            a.collectionId == 'zones' ||
            _localCollectionIds.contains(a.collectionId))
        .toList();

    // Build themed sub-collections for global tier
    final themed = <String, List<Achievement>>{};
    for (final a in filtered) {
      if (_themedCollectionIds.contains(a.collectionId)) {
        themed.putIfAbsent(a.collectionId!, () => []).add(a);
      }
    }

    // Build local sub-collections for zone tier
    final local = <String, List<Achievement>>{};
    for (final a in filtered) {
      if (_localCollectionIds.contains(a.collectionId)) {
        local.putIfAbsent(a.collectionId!, () => []).add(a);
      }
    }

    final zonesOnly = filtered
        .where((a) => a.collectionId == 'zones')
        .toList();

    final totalAll = all.length;
    final unlockedAll = all.where((a) => a.isUnlocked).length;

    final hasFilter = _selectedContinent != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // Filter bar
        _FilterBar(
          selectedContinent: _selectedContinent,
          selectedCountry: _selectedCountry,
          availableCountries: availableCountries,
          onContinentChanged: (c) => setState(() {
            _selectedContinent = c;
            _selectedCountry = null;
          }),
          onCountryChanged: (c) => setState(() {
            _selectedCountry = c;
          }),
        ),
        const SizedBox(height: 12),

        // Progress card
        _GlobalProgressCard(
          total: hasFilter
              ? filtered.length
              : totalAll,
          unlocked: hasFilter
              ? filtered.where((a) => a.isUnlocked).length
              : unlockedAll,
          label: hasFilter ? 'Filtered Progress' : 'Overall Progress',
        ),
        const SizedBox(height: 16),

        // ── GLOBAL tier ──
        if (globalAchievements.isNotEmpty)
          _TierSection(
            tier: _GeoTier.global,
            achievements: globalAchievements,
            collections: [
              if (countryAchievements.isNotEmpty)
                _CollectionInfo(
                  label: 'All Countries on Earth',
                  icon: LucideIcons.flag,
                  achievements: countryAchievements,
                  isCountryCollection: true,
                ),
              for (final id in const [
                'holy-sites', 'ancient-sites', 'seas', 'national-parks',
                'capitals', 'ski-resorts', 'tourist-destinations',
              ])
                if (themed.containsKey(id))
                  _CollectionInfo(
                    label: _themedLabels[id] ?? id,
                    icon: _themedIcons[id] ?? LucideIcons.star,
                    achievements: themed[id]!,
                    isCountryCollection: false,
                  ),
            ],
          ),

        // ── CONTINENTAL tier ──
        if (continentalAchievements.isNotEmpty)
          _TierSection(
            tier: _GeoTier.continent,
            achievements: continentalAchievements,
            collections: [
              _CollectionInfo(
                label: 'All Continents on Earth',
                icon: LucideIcons.globe,
                achievements: continentalAchievements,
                isCountryCollection: false,
              ),
            ],
          ),

        // ── COUNTRY tier ──
        if (countryAchievements.isNotEmpty)
          _TierSection(
            tier: _GeoTier.country,
            achievements: countryAchievements,
            collections: [
              // Group by continent, each continent is a "collection"
              for (final cInfo in _continents)
                ..._buildCountryContinent(cInfo, countryAchievements),
            ],
          ),

        // ── ZONE tier ──
        if (zoneAchievements.isNotEmpty)
          _TierSection(
            tier: _GeoTier.zone,
            achievements: zoneAchievements,
            collections: [
              // Split zones by country tag → "Israeli Zones", "Bulgarian Zones"
              ..._buildZonesByCountry(zonesOnly),
              for (final entry in local.entries)
                _CollectionInfo(
                  label: _localLabels[entry.key] ?? entry.key,
                  icon: _localIcons[entry.key] ?? LucideIcons.star,
                  achievements: entry.value,
                  isCountryCollection: false,
                ),
            ],
          ),
      ],
    );
  }

  /// Split zone achievements into per-country buckets.
  /// Matches country tags against the known country-label map; anything
  /// without a recognized country tag falls into a generic "Zones" group.
  List<_CollectionInfo> _buildZonesByCountry(List<Achievement> zones) {
    if (zones.isEmpty) return const [];
    final byCountry = <String, List<Achievement>>{};
    final untagged = <Achievement>[];
    for (final z in zones) {
      String? country;
      for (final tag in z.tags) {
        if (_countryLabels.containsKey(tag)) {
          country = tag;
          break;
        }
      }
      if (country != null) {
        byCountry.putIfAbsent(country, () => []).add(z);
      } else {
        untagged.add(z);
      }
    }

    final out = <_CollectionInfo>[];
    // Sort by country label for stable order
    final sortedKeys = byCountry.keys.toList()
      ..sort((a, b) => (_countryLabels[a] ?? a).compareTo(_countryLabels[b] ?? b));
    for (final key in sortedKeys) {
      final countryName = _countryLabels[key] ?? key;
      out.add(_CollectionInfo(
        label: '$countryName Zones',
        icon: LucideIcons.mapPin,
        achievements: byCountry[key]!,
        isCountryCollection: false,
      ));
    }
    if (untagged.isNotEmpty) {
      out.add(_CollectionInfo(
        label: 'Other Zones',
        icon: LucideIcons.mapPin,
        achievements: untagged,
        isCountryCollection: false,
      ));
    }
    return out;
  }

  List<_CollectionInfo> _buildCountryContinent(
    _ContinentInfo cInfo,
    List<Achievement> countryAchievements,
  ) {
    final inContinent = countryAchievements
        .where((a) => a.collectionId == cInfo.id)
        .toList();
    if (inContinent.isEmpty) return [];
    final adjective = _continentAdjective[cInfo.id] ?? cInfo.label;
    return [
      _CollectionInfo(
        label: '${cInfo.emoji} $adjective Countries',
        icon: LucideIcons.flag,
        achievements: inContinent,
        isCountryCollection: false,
      ),
    ];
  }
}

// ── Global Progress Card ──

class _GlobalProgressCard extends StatelessWidget {
  final int total;
  final int unlocked;
  final String label;

  const _GlobalProgressCard({
    required this.total,
    required this.unlocked,
    this.label = 'Global Progress',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Text('\u{1F30D}', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlocked / $total achievements unlocked',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            total == 0
                ? '0%'
                : '${(unlocked / total * 100).round()}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Filter Bar
// ══════════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  final String? selectedContinent;
  final String? selectedCountry;
  final List<MapEntry<String, String>> availableCountries;
  final ValueChanged<String?> onContinentChanged;
  final ValueChanged<String?> onCountryChanged;

  const _FilterBar({
    required this.selectedContinent,
    required this.selectedCountry,
    required this.availableCountries,
    required this.onContinentChanged,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Find continent info for selected
    final continentLabel = selectedContinent == null
        ? null
        : _continents
            .where((c) => c.id == selectedContinent)
            .firstOrNull
            ?.label;

    return Row(
      children: [
        // Continent dropdown
        Expanded(
          child: _FilterDropdown(
            icon: LucideIcons.globe2,
            hint: 'Continent',
            value: selectedContinent,
            items: [
              const _DropdownItem(value: null, label: 'All Continents'),
              for (final c in _continents)
                _DropdownItem(
                  value: c.id,
                  label: c.label,
                  leading: c.emoji,
                ),
            ],
            onChanged: onContinentChanged,
          ),
        ),
        const SizedBox(width: 8),
        // Country dropdown (only when continent is selected)
        Expanded(
          child: selectedContinent != null && availableCountries.isNotEmpty
              ? _FilterDropdown(
                  icon: LucideIcons.mapPin,
                  hint: 'Country',
                  value: selectedCountry,
                  items: [
                    _DropdownItem(
                      value: null,
                      label: 'All in ${continentLabel ?? "region"}',
                    ),
                    for (final entry in availableCountries)
                      _DropdownItem(
                        value: entry.key,
                        label: entry.value,
                      ),
                  ],
                  onChanged: onCountryChanged,
                )
              : _FilterDropdown(
                  icon: LucideIcons.mapPin,
                  hint: 'Country',
                  value: null,
                  items: const [],
                  onChanged: (_) {},
                  enabled: false,
                ),
        ),
      ],
    );
  }
}

class _DropdownItem {
  final String? value;
  final String label;
  final String? leading;

  const _DropdownItem({
    required this.value,
    required this.label,
    this.leading,
  });
}

class _FilterDropdown extends StatelessWidget {
  final IconData icon;
  final String hint;
  final String? value;
  final List<_DropdownItem> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const _FilterDropdown({
    required this.icon,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final displayLabel = hasValue
        ? items.where((i) => i.value == value).firstOrNull?.label ?? hint
        : hint;

    return GestureDetector(
      onTap: enabled && items.isNotEmpty
          ? () => _showPicker(context)
          : null,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.bgCardLight.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: hasValue
                  ? AppColors.primaryLight
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue
                      ? AppColors.primaryLight
                      : enabled
                          ? AppColors.textSecondary
                          : AppColors.textMuted.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: enabled
                  ? AppColors.textMuted
                  : AppColors.textMuted.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFF2A2A2A)),
              // Items
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item.value == value;
                    return ListTile(
                      dense: true,
                      leading: item.leading != null
                          ? Text(item.leading!,
                              style: const TextStyle(fontSize: 18))
                          : null,
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(LucideIcons.check,
                              size: 16,
                              color: AppColors.primaryLight)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        onChanged(item.value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

