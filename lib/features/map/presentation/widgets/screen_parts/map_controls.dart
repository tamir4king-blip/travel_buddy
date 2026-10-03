part of '../../screens/map_screen.dart';

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool highlighted;
  final double size;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.highlighted = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.bgCard.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: highlighted
                ? AppColors.primary.withValues(alpha: 0.4)
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
        child: Icon(
          icon,
          size: size * 0.45,
          color: highlighted ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Close-map button with an "Exit" label underneath so users understand
/// what the X does (leave the map screen).
class _MapExitButton extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;

  const _MapExitButton({required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return _MapControlButton(
      icon: LucideIcons.x,
      onTap: onTap,
      tooltip: tooltip,
      size: 40,
    );
  }
}

/// Search bar for finding map markers by name. Can be minimized to a single
/// search icon to give more of the map back to the user.
class _MapSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;

  const _MapSearchBar({required this.onSearch});

  @override
  State<_MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<_MapSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;
  bool _minimized = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _minimized = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _collapse() {
    _focusNode.unfocus();
    setState(() => _minimized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_minimized) {
      return Align(
        alignment: Alignment.centerRight,
        child: _MapControlButton(
          icon: LucideIcons.search,
          onTap: _expand,
          tooltip: 'Search',
          size: 40,
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasFocus
              ? AppColors.primary.withValues(alpha: 0.5)
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
        children: [
          // Minimize button — now on the LEFT (was on the right). Collapses
          // the bar back to a single search icon at the far right.
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _collapse();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'Search pins...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                widget.onSearch(value);
                _focusNode.unfocus();
              },
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            LucideIcons.search,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
