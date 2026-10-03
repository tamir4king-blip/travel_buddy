import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

class AchievementMarker extends StatelessWidget {
  final Achievement achievement;
  final bool inRange;
  final VoidCallback? onTap;

  const AchievementMarker({
    super.key,
    required this.achievement,
    this.inRange = false,
    this.onTap,
  });

  static Color tierColor(AchievementTier tier) {
    return switch (tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = tierColor(achievement.tier);
    final isUnlocked = achievement.isUnlocked;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring when in range (locked + user nearby)
            if (inRange && !isUnlocked)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 0.8, end: 1.2, duration: 1200.ms)
                  .fadeOut(begin: 0.8, duration: 1200.ms),

            if (isUnlocked)
              _unlockedPin(color)
            else
              _lockedLock(color),
          ],
        ),
      ),
    );
  }

  /// Unlocked state — classic pin with checkmark (existing look).
  Widget _unlockedPin(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.4),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
          ),
          child: const Icon(
            LucideIcons.check,
            size: 18,
            color: Colors.white70,
          ),
        ),
        Positioned(
          bottom: 0,
          child: CustomPaint(
            size: const Size(12, 10),
            painter: _PinTailPainter(color: color.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }

  /// Locked state — big lock icon in tier color, no pin body.
  Widget _lockedLock(Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        LucideIcons.lock,
        size: 22,
        color: color,
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;

  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => color != oldDelegate.color;
}
