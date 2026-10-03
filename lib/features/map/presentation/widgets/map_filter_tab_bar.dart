import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';

/// Single filter button that sits above the bottom nav bar on the map screen.
/// Shows an active-filter count badge when subfilters are applied.
class MapFilterButton extends ConsumerWidget {
  final VoidCallback onTap;

  const MapFilterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    final hasFilters = filter.hasActiveFilters;
    final count = filter.activeFilterCount;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          // Matches the right-side map control buttons (location/zoom/etc.)
          // — same translucency so the button feels like part of the map UI.
          color: hasFilters
              ? AppColors.primaryLight.withValues(alpha: 0.15)
              : AppColors.bgCard.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasFilters
                ? AppColors.primaryLight.withValues(alpha: 0.4)
                : AppColors.textMuted.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.slidersHorizontal,
              size: 18,
              color: hasFilters ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Filters',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasFilters ? AppColors.primaryLight : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
