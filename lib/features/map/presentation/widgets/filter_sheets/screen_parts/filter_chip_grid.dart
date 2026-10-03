part of '../unified_filter_sheet.dart';

class _ChipData {
  final String id;
  final String label;
  final bool selected;
  const _ChipData(
      {required this.id, required this.label, required this.selected});
}

class _ChipGrid extends StatelessWidget {
  final List<_ChipData> items;
  final Color color;
  final ValueChanged<String> onTap;

  const _ChipGrid({
    required this.items,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.map((item) {
          return GestureDetector(
            onTap: () => onTap(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: item.selected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.selected
                      ? color.withValues(alpha: 0.4)
                      : AppColors.textMuted.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.selected) ...[
                    Icon(LucideIcons.check, size: 11, color: color),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          item.selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          item.selected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

