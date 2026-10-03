part of '../achievement_detail_sheet.dart';

class _TierProgress {
  final String label;
  final int unlocked;
  final int total;
  final Color color;
  final String tierLabel;

  const _TierProgress({
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
    required this.tierLabel,
  });
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLink;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isLink ? AppColors.primaryLight : AppColors.textSecondary,
              fontSize: 13,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClaimButton extends ConsumerStatefulWidget {
  final String achievementId;

  const _ClaimButton({required this.achievementId});

  @override
  ConsumerState<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends ConsumerState<_ClaimButton> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    final navContext = Navigator.of(context, rootNavigator: true).context;
    final notifier = ref.read(achievementsProvider.notifier);
    final achievement = ref.read(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == widget.achievementId);

    final success = await notifier.confirmPendingClaim(widget.achievementId);

    if (mounted) setState(() => _claiming = false);

    if (success) {
      // Close the detail sheet first, then show unlock popup
      if (mounted) Navigator.of(context).pop();
      if (navContext.mounted) {
        await AchievementUnlockPopup.show(navContext, achievement);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch fresh state — hide button if already claimed
    final fresh = ref.watch(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == widget.achievementId);
    if (!fresh.isPendingClaim || fresh.isUnlocked) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _claim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.accent],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _claiming
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Claim Achievement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Instant retroactive claim — marks as unlocked with today as visit date.
/// User can refine date/photos/notes afterward via the edit button.
class _RetroactiveClaimButton extends ConsumerStatefulWidget {
  final String achievementId;

  const _RetroactiveClaimButton({required this.achievementId});

  @override
  ConsumerState<_RetroactiveClaimButton> createState() =>
      _RetroactiveClaimButtonState();
}

class _RetroactiveClaimButtonState
    extends ConsumerState<_RetroactiveClaimButton> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    final notifier = ref.read(achievementsProvider.notifier);
    final achievement = ref.read(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == widget.achievementId);

    final success = await notifier.claimAchievement(
      widget.achievementId,
      retroactiveData: RetroactiveClaimData(visitDate: DateTime.now()),
    );

    if (!mounted) return;
    setState(() => _claiming = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claimed "${achievement.title}" retroactively'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _claiming ? null : _claim,
        icon: _claiming
            ? const SizedBox(
                width: 14,
                height: 14,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(LucideIcons.clock, size: 16),
        label: Text(
          _claiming ? 'Claiming...' : 'Claim Retroactively',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

