import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/data/country_details_registry.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

class CountryDetailScreen extends StatefulWidget {
  final Achievement achievement;
  final CountryDetail details;
  /// The flag painter widget to reuse from achievements screen.
  final Widget flagWidget;

  const CountryDetailScreen({
    super.key,
    required this.achievement,
    required this.details,
    required this.flagWidget,
  });

  @override
  State<CountryDetailScreen> createState() => _CountryDetailScreenState();
}

class _CountryDetailScreenState extends State<CountryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<_DetailTab> _tabs(AppLocalizations l10n) => [
    _DetailTab(label: l10n.tabCities, emoji: '\u{1F3D9}', icon: LucideIcons.building2),
    _DetailTab(label: l10n.tabLandmarks, emoji: '\u{1F3DB}', icon: LucideIcons.landmark),
    _DetailTab(label: l10n.tabFood, emoji: '\u{1F37D}', icon: LucideIcons.chefHat),
    _DetailTab(label: l10n.tabActivities, emoji: '\u{1F3AF}', icon: LucideIcons.compass),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final details = widget.details;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          // ── Hero header with flag ──
          _buildHero(context, achievement),
          // ── Tab bar ──
          _buildTabBar(AppLocalizations.of(context)!),
          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ItemList(items: details.cities, color: const Color(0xFF3B82F6)),
                _ItemList(items: details.landmarks, color: const Color(0xFFF59E0B)),
                _ItemList(items: details.food, color: const Color(0xFFEF4444)),
                _ItemList(items: details.activities, color: const Color(0xFF10B981)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, Achievement achievement) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Flag background
          widget.flagWidget,
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                      if (achievement.isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.check, size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                AppLocalizations.of(context)!.visited,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Country name
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Stats row
                  Row(
                    children: [
                      _StatPill(
                        icon: LucideIcons.zap,
                        label: '+${achievement.xpReward} XP',
                        color: AppColors.xpGlow,
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: LucideIcons.mapPin,
                        label: AppLocalizations.of(context)!.nCities(widget.details.cities.length),
                        color: const Color(0xFF60A5FA),
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: LucideIcons.landmark,
                        label: AppLocalizations.of(context)!.nLandmarks(widget.details.landmarks.length),
                        color: const Color(0xFFFBBF24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    final tabs = _tabs(l10n);
    return Container(
      color: AppColors.bgDark,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryLight,
        indicatorWeight: 3,
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: AppColors.bgCardLight.withValues(alpha: 0.3),
        tabs: tabs.map((tab) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tab.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(tab.label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailTab {
  final String label;
  final String emoji;
  final IconData icon;
  const _DetailTab({required this.label, required this.emoji, required this.icon});
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Item List for each tab ──
class _ItemList extends StatelessWidget {
  final List<CountryItem> items;
  final Color color;
  const _ItemList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mapPin, size: 40, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.comingSoon,
              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemCard(item: item, color: color, index: index);
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final CountryItem item;
  final Color color;
  final int index;
  const _ItemCard({required this.item, required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Arrow
          Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: color.withValues(alpha: 0.4),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.04);
  }
}
