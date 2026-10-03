import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';

/// Fixed-position popup that slides down from the top of the screen when a
/// map pin is tapped. Persists through map pan/zoom — only closes via the
/// X button or when another pin is selected.
///
/// Visual language:
/// - [outlineColor] is the type-color of the pin (country → gold, beach →
///   cyan, quest → red, etc.) and is used for the card border, glow shadow,
///   banner gradient, and CTA tint.
/// - [color] is the pin's inner color (tier/difficulty/rarity) and fills
///   the icon disc inside the banner.
class MapPinPopup extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color outlineColor;
  final IconData icon;
  final Animation<double> animation;
  final VoidCallback onViewMore;
  final VoidCallback onDismiss;
  final int? xpReward;
  final bool isUnlocked;
  final int visitCount;
  final bool isPendingClaim;

  const MapPinPopup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.animation,
    required this.onViewMore,
    required this.onDismiss,
    Color? outlineColor,
    this.xpReward,
    this.isUnlocked = false,
    this.visitCount = 0,
    this.isPendingClaim = false,
  }) : outlineColor = outlineColor ?? color;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    final slide = Tween<Offset>(
      begin: const Offset(0, -1.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    final fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    return Positioned(
      top: topInset + 12,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: fade,
          child: GestureDetector(
            onTap: () {},
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _card(),
                Positioned(
                  top: -10,
                  right: -10,
                  child: _closeButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outlineColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: outlineColor.withValues(alpha: 0.45),
            blurRadius: 26,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _banner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                _viewMoreButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              outlineColor.withValues(alpha: 0.45),
              outlineColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: _iconDisc()),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            if (_bannerBadges().isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _bannerBadges(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconDisc() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: outlineColor.withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Icon(icon, size: 24, color: Colors.white),
    );
  }

  List<Widget> _bannerBadges() {
    final badges = <Widget>[];
    if (isPendingClaim) {
      badges.add(_badge(
        label: 'Tap to claim',
        icon: LucideIcons.sparkles,
        bg: AppColors.accent,
        fg: Colors.white,
      ));
    } else if (isUnlocked) {
      badges.add(_badge(
        label: visitCount > 1 ? '$visitCount× visits' : 'Unlocked',
        icon: LucideIcons.check,
        bg: AppColors.success.withValues(alpha: 0.22),
        fg: AppColors.success,
      ));
    }
    if (xpReward != null) {
      if (badges.isNotEmpty) badges.add(const SizedBox(height: 5));
      badges.add(_xpChip(xpReward!));
    }
    return badges;
  }

  Widget _badge({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _xpChip(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppGradients.gradientWarm,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.zap, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            '+$xp XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _closeButton() {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(6),
        color: Colors.transparent,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgCardLight,
            border: Border.all(color: outlineColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: outlineColor.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.x,
            size: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _viewMoreButton() {
    return GestureDetector(
      onTap: onViewMore,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: outlineColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineColor.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View more',
              style: TextStyle(
                color: outlineColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.arrowRight, size: 14, color: outlineColor),
          ],
        ),
      ),
    );
  }
}
