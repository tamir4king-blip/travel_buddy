part of '../../screens/skills_screen.dart';

// ─── Toolbar Widgets ─────────────────────────────────────────────────────────

class _ToolbarToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ToolbarToggle({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.bgCard : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)]
                    : null,
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GridColumnPicker extends StatelessWidget {
  final int columns;
  final ValueChanged<int> onChanged;

  const _GridColumnPicker({
    required this.columns,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gridButton(1, LucideIcons.alignJustify),
          _gridButton(2, LucideIcons.layoutGrid),
          _gridButton(3, LucideIcons.grid),
        ],
      ),
    );
  }

  Widget _gridButton(int cols, IconData icon) {
    final selected = columns == cols;
    return GestureDetector(
      onTap: () => onChanged(cols),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? AppColors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}

