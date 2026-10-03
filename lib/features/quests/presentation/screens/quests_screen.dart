import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/providers/quest_chain_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

// Quests screen widgets - split out of this file as `part` libraries to keep
// each section focused. They share this files imports and private scope.
part '../widgets/screen_parts/quests_tabs.dart';
part '../widgets/screen_parts/quest_chain_card.dart';
part '../widgets/screen_parts/quest_detail_sheet.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

enum _QuestTab { active, claim, available, completed }

class _QuestsScreenState extends ConsumerState<QuestsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  _QuestTab _tab = _QuestTab.active;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final chainState = ref.watch(questChainProvider);

    final active = chainState.activeQuests;
    final claimable = chainState.claimableQuests;
    final available = chainState.availableQuests;
    final completed = chainState.completedQuests;

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primary,
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(
                      text: l10n.quests,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      gradient: AppGradients.gradientPrimary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${active.length} active  •  ${completed.length} completed',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Tabs ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QuestTabs(
                  selected: _tab,
                  activeCount: active.length,
                  claimCount: claimable.length,
                  availableCount: available.length,
                  completedCount: completed.length,
                  onChanged: (t) => setState(() => _tab = t),
                ),
              ),
              const SizedBox(height: 12),
              // ── Content ──
              Expanded(
                child: _buildTabContent(active, claimable, available, completed),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    List<Quest> active,
    List<Quest> claimable,
    List<Quest> available,
    List<Quest> completed,
  ) {
    final quests = switch (_tab) {
      _QuestTab.active => active,
      _QuestTab.claim => claimable,
      _QuestTab.available => available,
      _QuestTab.completed => completed,
    };

    if (quests.isEmpty) {
      return _buildEmpty();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: quests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _QuestChainCard(
          quest: quest,
          onTap: () => _showQuestDetail(quest),
        )
            .animate()
            .fadeIn(duration: 350.ms, delay: (index * 70).ms)
            .slideY(begin: 0.04);
      },
    );
  }

  Widget _buildEmpty() {
    final msg = switch (_tab) {
      _QuestTab.active => 'No active quests.\nStart one from the Available tab!',
      _QuestTab.claim => 'No quests ready to claim.\nComplete an active quest first!',
      _QuestTab.available => 'No quests available right now.',
      _QuestTab.completed => 'No completed quests yet.\nStart your first quest!',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.scroll, size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestDetail(Quest quest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuestDetailSheet(
        quest: quest,
        onStart: () {
          ref.read(questChainProvider.notifier).startQuest(quest.id);
          Navigator.of(context).pop();
          setState(() => _tab = _QuestTab.active);
        },
        onAbandon: () {
          ref.read(questChainProvider.notifier).abandonQuest(quest.id);
          Navigator.of(context).pop();
        },
        onClaim: () {
          ref.read(questChainProvider.notifier).claimQuest(quest.id);
          Navigator.of(context).pop();
          setState(() => _tab = _QuestTab.completed);
        },
      ),
    );
  }
}

