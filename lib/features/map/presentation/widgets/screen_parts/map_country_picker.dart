part of '../../screens/map_screen.dart';

/// Tappable selector that opens a search dialog for picking any
/// country achievement. Falls back to the user's current country when
/// none is explicitly chosen.
class _CountryPicker extends StatelessWidget {
  final List<Achievement> achievements;
  final Achievement? currentCountry;
  final Achievement? selected;
  final ValueChanged<String?> onPick;

  const _CountryPicker({
    required this.achievements,
    required this.currentCountry,
    required this.selected,
    required this.onPick,
  });

  static const _countryCollections = <String>{
    'europe', 'asia', 'africa', 'americas', 'south-america', 'oceania',
  };

  @override
  Widget build(BuildContext context) {
    final countries = achievements
        .where((a) => _countryCollections.contains(a.collectionId))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    final effective = selected ?? currentCountry;
    final label = effective?.title ??
        (currentCountry == null
            ? 'Waiting for your location…'
            : 'Pick a country');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<String?>(
              context: context,
              builder: (_) => _CountrySearchDialog(
                countries: countries,
                hasSelection: selected != null,
              ),
            );
            if (picked == null) return;
            if (picked == '__clear__') {
              // Explicit clear — null out the selection AND any current
              // country so the picker truly shows nothing.
              onPick(null);
            } else if (picked == '') {
              // Use current country.
              onPick(null);
            } else {
              onPick(picked);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.flag,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected != null) ...[
                  GestureDetector(
                    onTap: () => onPick(null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(LucideIcons.x,
                          size: 13, color: AppColors.textMuted),
                    ),
                  ),
                ],
                Icon(LucideIcons.chevronDown,
                    size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (selected != null && currentCountry != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Current: ${currentCountry!.title}',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// Searchable country list dialog. Returns the selected achievement id,
/// or empty string to clear the override (use current country).
class _CountrySearchDialog extends StatefulWidget {
  final List<Achievement> countries;
  final bool hasSelection;
  const _CountrySearchDialog({
    required this.countries,
    this.hasSelection = false,
  });

  @override
  State<_CountrySearchDialog> createState() => _CountrySearchDialogState();
}

class _CountrySearchDialogState extends State<_CountrySearchDialog> {
  String _query = '';
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.countries
        : widget.countries
            .where((c) => c.title.toLowerCase().contains(query))
            .toList();
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 380,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.flag,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pick a country',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(LucideIcons.x,
                          size: 16, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                autofocus: true,
                controller: _textController,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search countries…',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(LucideIcons.search,
                      size: 16, color: AppColors.textMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : GestureDetector(
                          onTap: () {
                            _textController.clear();
                            setState(() => _query = '');
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Icon(LucideIcons.x,
                              size: 14, color: AppColors.textMuted),
                        ),
                  filled: true,
                  fillColor:
                      AppColors.bgCardLight.withValues(alpha: 0.4),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(''),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.crosshair,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Use my current country',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Clear selected country — pops a sentinel ('clear') so the
            // caller can null out the selection.
            if (widget.hasSelection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop('__clear__'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(LucideIcons.eraser,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'Clear selection',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Divider(height: 1, color: Color(0x22FFFFFF)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(c.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        c.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Inline 6-button continent picker. Tap one to set [selected]; selecting
/// a continent doesn't require also picking a country.
class _ContinentPicker extends StatelessWidget {
  final List<Achievement> achievements;
  final Achievement? selected;
  final ValueChanged<String?> onPick;

  const _ContinentPicker({
    required this.achievements,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final continents = achievements
        .where((a) => a.collectionId == 'continents')
        .toList();
    if (continents.isEmpty) {
      return const Text(
        'No continent data available',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: continents.map((c) {
        final isSelected = selected?.id == c.id;
        final shortName = c.title
            .replaceFirst('Visit ', '')
            .replaceAll('!', '');
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onPick(isSelected ? null : c.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.bgCardLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.textMuted.withValues(alpha: 0.2),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(LucideIcons.check,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                ],
                Text(
                  shortName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
