import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/home/presentation/screens/home_screen.dart';

/// The app's menu: a bottom sheet floating over the full-screen map.
/// Collapsed it's just a grab handle — the map stays the star. Swipe up for
/// the destinations grid and the full dashboard (welcome card, XP, stats).
/// This replaces the bottom navigation bar.
class HomeMapSheet extends ConsumerStatefulWidget {
  const HomeMapSheet({super.key});

  @override
  ConsumerState<HomeMapSheet> createState() => _HomeMapSheetState();
}

class _HomeMapSheetState extends ConsumerState<HomeMapSheet> {
  /// Sheet anchor points: collapsed shows the handle + menu icon row (map
  /// fully exposed), peek adds the dashboard, full opens it entirely.
  static const _collapsed = 0.118;
  static const _peek = 0.46;
  static const _full = 0.94;

  final _sheetController = DraggableScrollableController();
  double _lastSettled = _collapsed;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  bool _onSheetNotification(DraggableScrollableNotification notification) {
    // Tick when the sheet settles on a new anchor — makes the snap physical.
    for (final anchor in const [_collapsed, _peek, _full]) {
      if ((notification.extent - anchor).abs() < 0.006 &&
          (_lastSettled - anchor).abs() > 0.02) {
        _lastSettled = anchor;
        HapticFeedback.selectionClick();
        break;
      }
    }
    return false;
  }

  void _openDestination(String route) {
    HapticFeedback.selectionClick();
    context.go(route);
    // Collapse so the map greets the user when they come back.
    _sheetController.animateTo(
      _collapsed,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleSheet() {
    HapticFeedback.selectionClick();
    final target = _sheetController.size < (_collapsed + _peek) / 2
        ? _peek
        : _collapsed;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final destinations = <_MenuDestination>[
      _MenuDestination(LucideIcons.bookOpen, l10n.navLog, '/log'),
      _MenuDestination(LucideIcons.swords, l10n.quests, '/quests'),
      _MenuDestination(LucideIcons.medal, l10n.achievements, '/achievements'),
      _MenuDestination(LucideIcons.sparkles, l10n.skills, '/skills'),
      _MenuDestination(LucideIcons.trophy, l10n.navRankings, '/leaderboard'),
      _MenuDestination(LucideIcons.user, l10n.navProfile, '/profile'),
    ];

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _onSheetNotification,
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _collapsed,
        minChildSize: _collapsed,
        maxChildSize: _full,
        snap: true,
        snapSizes: const [_peek],
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
              child: Column(
                children: [
                  // Tapping the handle toggles collapsed <-> menu.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleSheet,
                    child: const _GrabHandle(),
                  ),
                  _MenuGrid(
                    destinations: destinations,
                    onTap: _openDestination,
                  ),
                  Expanded(
                    child: HomeScreen(
                      sheetScrollController: scrollController,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _MenuDestination {
  final IconData icon;
  final String label;
  final String route;
  const _MenuDestination(this.icon, this.label, this.route);
}

/// The navigation grid that replaced the bottom bar — one row of evenly
/// spaced destinations right under the handle, so they're reachable the
/// moment the sheet peeks open.
class _MenuGrid extends StatelessWidget {
  final List<_MenuDestination> destinations;
  final void Function(String route) onTap;

  const _MenuGrid({required this.destinations, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final d in destinations)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(d.route),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgCardLight,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        d.icon,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
