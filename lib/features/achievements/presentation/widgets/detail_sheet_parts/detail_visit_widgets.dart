part of '../achievement_detail_sheet.dart';

/// Tier-colored gradient banner used when no cover photo is available.
class _BannerGradient extends StatelessWidget {
  final Color color;
  const _BannerGradient({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.7),
            color.withValues(alpha: 0.3),
            AppColors.bgCard,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.trophy,
          size: 80,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

/// Pick a date, return it. Returns null if cancelled.
Future<DateTime?> _pickVisitDate(BuildContext context, DateTime initial) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  );
}

/// Visit + revisit log. Shows first visit (retroactive if edited) + each
/// revisit. Each entry has an edit button. A "+ Add revisit" CTA at the
/// bottom lets the user add a past visit retroactively.
class _VisitHistoryCard extends ConsumerWidget {
  final Achievement achievement;
  final Locale locale;

  const _VisitHistoryCard({required this.achievement, required this.locale});

  DateTime? get _firstVisit => achievement.visitDate ?? achievement.unlockedAt;

  bool get _firstIsRetroactive => achievement.isRetroactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = _firstVisit;
    final history = achievement.revisitHistory;
    if (first == null && history.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.footprints, size: 14, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                achievement.visitCount <= 1
                    ? 'Visit history'
                    : '${achievement.visitCount} visits',
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // First visit
          if (first != null)
            _VisitRow(
              label: 'First visit',
              date: first,
              locale: locale,
              retroactive: _firstIsRetroactive,
              onEdit: () => _editFirstVisit(context, ref),
            ),
          // Subsequent revisits (index 0 == visit #2, etc.)
          for (var i = 0; i < history.length; i++) ...[
            const SizedBox(height: 6),
            _VisitRow(
              label: 'Visit #${i + 2}',
              date: history[i],
              locale: locale,
              retroactive: true,
              onEdit: () => _editRevisit(context, ref, i),
            ),
          ],
          const SizedBox(height: 12),
          // Add revisit CTA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addRevisit(context, ref),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add revisit (retroactive)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: BorderSide(color: AppColors.info.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editFirstVisit(BuildContext context, WidgetRef ref) async {
    final picked = await _pickVisitDate(
        context, _firstVisit ?? DateTime.now());
    if (picked == null) return;
    await ref
        .read(achievementsProvider.notifier)
        .updateVisitDetails(achievement.id, visitDate: picked);
  }

  Future<void> _editRevisit(BuildContext context, WidgetRef ref, int index) async {
    final current = achievement.revisitHistory[index];
    final picked = await _pickVisitDate(context, current);
    if (picked == null) return;
    await ref
        .read(achievementsProvider.notifier)
        .updateRevisitEntry(achievement.id, index, picked);
  }

  Future<void> _addRevisit(BuildContext context, WidgetRef ref) async {
    final picked = await _pickVisitDate(context, DateTime.now());
    if (picked == null) return;
    await ref
        .read(achievementsProvider.notifier)
        .addRetroactiveRevisit(achievement.id, picked);
  }
}

class _VisitRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final Locale locale;
  final bool retroactive;
  final VoidCallback onEdit;

  const _VisitRow({
    required this.label,
    required this.date,
    required this.locale,
    required this.retroactive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.info,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            DateFormat.yMMMd(locale.languageCode).format(date),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        if (retroactive)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(LucideIcons.history,
                size: 12, color: AppColors.warning.withValues(alpha: 0.8)),
          ),
        GestureDetector(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(LucideIcons.pencil,
                size: 14, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

