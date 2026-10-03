part of '../unified_filter_sheet.dart';

// ── Shared Components ──

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool visible;
  final int filterCount;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onClear;
  /// When non-null, renders an expand/collapse chevron. Tap the whole
  /// header row to toggle expansion.
  final bool? expanded;
  final VoidCallback? onToggleExpanded;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    required this.visible,
    required this.filterCount,
    required this.onToggleVisibility,
    this.onClear,
    this.expanded,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: visible ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            if (filterCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$filterCount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: onToggleVisibility,
              child: _VisibilityDot(visible: visible, color: color),
            ),
            if (expanded != null) ...[
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: expanded! ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickFilterRowData {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _QuickFilterRowData({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });
}

/// 2-column grid of compact quick-filter checkbox rows. Used at the top
/// of the advanced filter sheet so the common toggles stay reachable
/// alongside the deeper sections.
class _QuickFilterGrid extends StatelessWidget {
  final List<_QuickFilterRowData> rows;
  const _QuickFilterGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    final pairs = <List<_QuickFilterRowData>>[];
    for (var i = 0; i < rows.length; i += 2) {
      pairs.add(rows.sublist(i, (i + 2).clamp(0, rows.length)));
    }
    return Column(
      children: pairs.map((pair) {
        return Row(
          children: [
            Expanded(child: _QuickFilterRow(data: pair[0])),
            const SizedBox(width: 8),
            Expanded(
              child: pair.length > 1
                  ? _QuickFilterRow(data: pair[1])
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Compact one-line row used inside [_QuickFilterGrid]. Left checkbox
/// shows state + toggles on tap. Tap anywhere on the row to toggle.
class _QuickFilterRow extends StatelessWidget {
  final _QuickFilterRowData data;

  const _QuickFilterRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final active = data.active;
    return GestureDetector(
      onTap: data.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: active ? data.color : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: active
                      ? data.color
                      : AppColors.textMuted.withValues(alpha: 0.5),
                  width: 1.4,
                ),
              ),
              child: active
                  ? const Icon(LucideIcons.check,
                      size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Icon(data.icon,
                size: 14,
                color: active ? data.color : AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityDot extends StatelessWidget {
  final bool visible;
  final Color color;

  const _VisibilityDot({required this.visible, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: visible
            ? color.withValues(alpha: 0.15)
            : AppColors.bgCardLight,
        border: Border.all(
          color: visible
              ? color.withValues(alpha: 0.4)
              : AppColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(
        visible ? LucideIcons.eye : LucideIcons.eyeOff,
        size: 13,
        color: visible ? color : AppColors.textMuted,
      ),
    );
  }
}

