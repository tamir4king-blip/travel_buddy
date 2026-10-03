import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:travel_buddy_mobile/shared/providers/leaderboard_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);

    // Loading state — first load with no data
    if (state.isLoading && state.entries.isEmpty) {
      return SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Error state — no data available
    if (state.errorMessage != null && state.entries.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => notifier.refresh(),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasFullPodium = state.entries.length >= 3;
    final top3 = hasFullPodium ? state.entries.where((e) => e.rank <= 3).toList() : <LeaderboardEntry>[];
    final rest = hasFullPodium ? state.entries.where((e) => e.rank > 3).toList() : state.entries;

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.accent,
          child: RefreshIndicator(
          onRefresh: () => notifier.refresh(),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.leaderboard,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.participants(state.totalParticipants),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _TimeChip(
                            label: l10n.weekly,
                            isSelected: state.timeRange == TimeRange.weekly,
                            onTap: () => notifier.setTimeRange(TimeRange.weekly),
                          ),
                          const SizedBox(width: 8),
                          _TimeChip(
                            label: l10n.monthly,
                            isSelected: state.timeRange == TimeRange.monthly,
                            onTap: () => notifier.setTimeRange(TimeRange.monthly),
                          ),
                          const SizedBox(width: 8),
                          _TimeChip(
                            label: l10n.allTime,
                            isSelected: state.timeRange == TimeRange.allTime,
                            onTap: () => notifier.setTimeRange(TimeRange.allTime),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (state.currentUserEntry != null)
                        _YourRankCard(entry: state.currentUserEntry!, l10n: l10n),
                      const SizedBox(height: 16),

                      if (top3.length >= 3) _Podium(entries: top3),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: rest.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = rest[index];
                  return _RankTile(entry: entry)
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (index * 60).ms);
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        ),
        ),
      ),
    );
  }
}

class _YourRankCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final AppLocalizations l10n;

  const _YourRankCard({required this.entry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      glowColor: AppColors.primary,
      borderRadius: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.2),
              AppColors.primaryLight.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AnimatedCounter(
                  value: entry.rank,
                  prefix: '#',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ProfileAvatar(
              avatarUrl: entry.avatarUrl,
              displayName: entry.displayName,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.yourRank,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${entry.displayName} \u2022 ${l10n.levelN(entry.level)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCounter(
              value: entry.totalXp,
              suffix: ' XP',
              style: const TextStyle(
                color: AppColors.xpGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Sort: 2nd, 1st, 3rd for podium layout
    final first = entries.firstWhere((e) => e.rank == 1);
    final second = entries.firstWhere((e) => e.rank == 2);
    final third = entries.firstWhere((e) => e.rank == 3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumSpot(entry: second, height: 100, color: AppColors.silver)
              .animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumSpot(entry: first, height: 130, color: AppColors.gold)
              .animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3).scale(begin: const Offset(0.9, 0.9)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumSpot(entry: third, height: 80, color: AppColors.bronze)
              .animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3),
        ),
      ],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;

  const _PodiumSpot({required this.entry, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    final isFirst = entry.rank == 1;
    return Column(
      children: [
        ProfileAvatar(
          avatarUrl: entry.avatarUrl,
          displayName: entry.displayName,
          radius: isFirst ? 28 : 22,
        ),
        const SizedBox(height: 8),
        Text(entry.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        AnimatedCounter(
          value: entry.totalXp,
          suffix: ' XP',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        Text(
          'Lv ${entry.level}',
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        GlowContainer(
          glowColor: color,
          borderRadius: 12,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(
                isFirst ? LucideIcons.crown : LucideIcons.trophy,
                color: color,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const _RankTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: entry.isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: entry.isCurrentUser
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.isCurrentUser ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            ProfileAvatar(
              avatarUrl: entry.avatarUrl,
              displayName: entry.displayName,
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: TextStyle(fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.w500),
                  ),
                  Text(
                    'Lv ${entry.level}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            AnimatedCounter(
              value: entry.totalXp,
              suffix: ' XP',
              style: const TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
