import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/israel_list_sheet.dart';
import 'package:travel_buddy_mobile/shared/data/israel/israel_catalog.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/utils/israel_explorer_stats.dart';

/// The person's Israel Explorer profile: rank, Traveler DNA archetype,
/// regional coverage, extremes and per-list progress (MTP-style lists).
class IsraelExplorerSection extends ConsumerWidget {
  const IsraelExplorerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(achievementsProvider.select((s) => s.allAchievements));
    return IsraelExplorerView(achievements: all);
  }
}

/// Provider-free body of [IsraelExplorerSection], so it can be rendered in
/// tests with a fixed set of achievements.
class IsraelExplorerView extends StatelessWidget {
  const IsraelExplorerView({super.key, required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final stats = IsraelExplorerStats.fromAchievements(achievements);
    final lang = Localizations.localeOf(context).languageCode;
    String t(String en, String he) => lang == 'he' ? he : en;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RankCard(stats: stats, lang: lang),
        const SizedBox(height: 12),
        if (stats.dna.isNotEmpty) ...[
          _Card(
            title: t('Traveler DNA', 'הדי.אן.איי של המטייל/ת'),
            child: _DnaBars(stats: stats, lang: lang),
          ),
          const SizedBox(height: 12),
        ],
        _Card(
          title: t('Regions — ${stats.regionsVisited}/${stats.regionsTotal}',
              'אזורים — ${stats.regionsVisited}/${stats.regionsTotal}'),
          child: _RegionGrid(stats: stats, lang: lang),
        ),
        if (stats.northernmost != null) ...[
          const SizedBox(height: 12),
          _Card(
            title: t('Signature places', 'המקומות שלך'),
            child: _Signatures(stats: stats, lang: lang),
          ),
        ],
        const SizedBox(height: 12),
        _Card(
          title: t('Lists', 'רשימות'),
          child: _ListGrid(stats: stats, lang: lang),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ── Rank / archetype header ─────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  const _RankCard({required this.stats, required this.lang});

  final IsraelExplorerStats stats;
  final String lang;

  @override
  Widget build(BuildContext context) {
    String t(String en, String he) => lang == 'he' ? he : en;
    final next = stats.rank.next;
    final toNext = next == null ? 0 : next.minPlaces - stats.visited;
    final rankProgress = next == null
        ? 1.0
        : ((stats.visited - stats.rank.minPlaces) /
                (next.minPlaces - stats.rank.minPlaces))
            .clamp(0.0, 1.0);
    final archetype = stats.archetype(lang);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(stats.rank.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.rank.label(lang),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      archetype ??
                          t('Visit places to discover your traveler type',
                              'בקרו במקומות כדי לגלות איזה מטיילים אתם'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: archetype == null
                            ? AppColors.textMuted
                            : AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                value: '${stats.visited}',
                label: t('of ${stats.total} places', 'מתוך ${stats.total} מקומות'),
              ),
              _Stat(
                value: '${stats.regionsVisited}',
                label: t('of ${stats.regionsTotal} regions',
                    'מתוך ${stats.regionsTotal} אזורים'),
              ),
              _Stat(
                value: '${(stats.fraction * 100).toStringAsFixed(stats.fraction < 0.1 ? 1 : 0)}%',
                label: t('of Israel', 'מהארץ'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rankProgress,
              minHeight: 6,
              backgroundColor: AppColors.bgCardLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? t('Top rank reached', 'הגעת לדרגה הגבוהה ביותר')
                : t('$toNext more to ${next.emoji} ${next.label(lang)}',
                    'עוד $toNext עד ${next.emoji} ${next.label(lang)}'),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Traveler DNA ─────────────────────────────────────────────────────────────

class _DnaBars extends StatelessWidget {
  const _DnaBars({required this.stats, required this.lang});

  final IsraelExplorerStats stats;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final top = stats.dna.take(6).toList();
    final max = top.first.share;
    return Column(
      children: [
        for (final f in top)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(f.facet.emoji, style: const TextStyle(fontSize: 16)),
                ),
                SizedBox(
                  width: 82,
                  child: Text(
                    f.facet.label(lang),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: max == 0 ? 0 : f.share / max,
                      minHeight: 8,
                      backgroundColor: AppColors.bgCardLight,
                      valueColor: AlwaysStoppedAnimation(
                        identical(f, top.first)
                            ? AppColors.accent
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(f.share * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Regions ──────────────────────────────────────────────────────────────────

class _RegionGrid extends StatelessWidget {
  const _RegionGrid({required this.stats, required this.lang});

  final IsraelExplorerStats stats;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in IsraelRegion.values)
          _RegionChip(
            label: r.label(lang),
            count: stats.regionCounts[r] ?? 0,
          ),
      ],
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final visited = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: visited
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: visited
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        visited ? '$label · $count' : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: visited ? FontWeight.w700 : FontWeight.w500,
          color: visited ? AppColors.primaryLight : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Signature places ─────────────────────────────────────────────────────────

class _Signatures extends StatelessWidget {
  const _Signatures({required this.stats, required this.lang});

  final IsraelExplorerStats stats;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    String t(String en, String he) => lang == 'he' ? he : en;
    String title(Achievement a) =>
        RegistryL10n.achievementTitle(locale, a.id, a.title);

    final span = stats.spanKm;
    final revisited = stats.mostRevisited;

    return Column(
      children: [
        _SignatureRow(
          emoji: '⬆️',
          label: t('Northernmost', 'הכי צפוני'),
          value: title(stats.northernmost!),
        ),
        _SignatureRow(
          emoji: '⬇️',
          label: t('Southernmost', 'הכי דרומי'),
          value: title(stats.southernmost!),
        ),
        if (span != null)
          _SignatureRow(
            emoji: '📏',
            label: t('North–south span', 'טווח צפון–דרום'),
            value: t('${span.round()} km', '${span.round()} ק"מ'),
          ),
        if (revisited != null)
          _SignatureRow(
            emoji: '🔁',
            label: t('Keeps coming back to', 'חוזר/ת שוב ושוב אל'),
            value: '${title(revisited)} ×${revisited.visitCount}',
          ),
        if (stats.rarest.isNotEmpty)
          _SignatureRow(
            emoji: '💎',
            label: t('Rarest find', 'הממצא הנדיר'),
            value: title(stats.rarest.first),
          ),
      ],
    );
  }
}

class _SignatureRow extends StatelessWidget {
  const _SignatureRow({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 26, child: Text(emoji)),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lists ────────────────────────────────────────────────────────────────────

class _ListGrid extends StatelessWidget {
  const _ListGrid({required this.stats, required this.lang});

  final IsraelExplorerStats stats;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in stats.lists)
              SizedBox(
                width: width,
                child: _ListTile(progress: p, lang: lang),
              ),
          ],
        );
      },
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.progress, required this.lang});

  final ListProgress progress;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final complete = progress.isComplete;
    return Material(
      color: AppColors.bgCardLight.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => IsraelListSheet.show(context, progress.list),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(progress.list.emoji, style: const TextStyle(fontSize: 16)),
                  const Spacer(),
                  Text(
                    '${progress.unlocked}/${progress.total}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: complete ? AppColors.gold : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                progress.list.label(lang),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 4,
                  backgroundColor: AppColors.bgCard,
                  valueColor: AlwaysStoppedAnimation(
                    complete ? AppColors.gold : AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared card shell ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgCardLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
