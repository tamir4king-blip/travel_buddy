part of '../../screens/map_screen.dart';

/// Compact badge used in map detail sheets.
class _SheetBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SheetBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Requirement row with check/empty circle.
class _RequirementRow extends StatelessWidget {
  final String text;
  final bool met;

  const _RequirementRow({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? LucideIcons.checkCircle : LucideIcons.circle,
            size: 14,
            color: met ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: met ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 13,
                decoration: met ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading shimmer shown while the map widget initializes.
class _MapLoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgCard,
              ),
              child: const Icon(
                LucideIcons.globe,
                size: 32,
                color: AppColors.primary,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 1200.ms)
                .fade(begin: 0.5, end: 1.0, duration: 1200.ms),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.searchAchievements ??
                  'Loading map...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
