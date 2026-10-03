import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/achievements/data/achievement_detail_provider.dart';
import 'package:travel_buddy_mobile/features/achievements/data/collection_helpers.dart'
    as ch;
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/achievement_detail.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/achievement_unlock_popup.dart';
import 'package:url_launcher/url_launcher.dart';

// Detail sheet sub-widgets - split out of this file as `part` libraries.
// They share this files imports and private scope.
part 'detail_sheet_parts/detail_claim_widgets.dart';
part 'detail_sheet_parts/detail_visit_widgets.dart';
part 'detail_sheet_parts/detail_action_buttons.dart';

/// Shows a rich detail bottom sheet for an achievement.
/// Fetches additional data (photos, hours, website) from Supabase on demand,
/// with graceful fallback to local data only.
class AchievementDetailSheet extends ConsumerWidget {
  final Achievement achievement;

  const AchievementDetailSheet({super.key, required this.achievement});

  /// Opens the canonical achievement detail page. [outlineColor] tints the
  /// banner, X button, and status accents to match the pin-type color used
  /// by the map popup. Defaults to the tier color when omitted.
  ///
  /// Uses a fade + scale transition so the page reads as the map popup
  /// expanding into full-screen detail rather than a horizontal page push.
  static Future<void> show(
    BuildContext context,
    Achievement achievement, {
    Color? outlineColor,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => _SheetContent(
          achievement: achievement,
          outlineColor: outlineColor,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}

class _SheetContent extends ConsumerWidget {
  final Achievement achievement;
  final Color? outlineColor;

  const _SheetContent({required this.achievement, this.outlineColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    // Read fresh state so revisit data is up-to-date
    final achievement = ref.watch(achievementsProvider).allAchievements
        .firstWhere((a) => a.id == this.achievement.id,
            orElse: () => this.achievement);

    final detailAsync = ref.watch(achievementDetailProvider(achievement.id));

    final tierColor = switch (achievement.tier) {
      AchievementTier.bronze => AppColors.bronze,
      AchievementTier.silver => AppColors.silver,
      AchievementTier.gold => AppColors.gold,
      AchievementTier.platinum => AppColors.platinum,
    };
    final accentColor = outlineColor ?? tierColor;

    final tierLabel = switch (achievement.tier) {
      AchievementTier.bronze => l10n.tierBronzeLabel,
      AchievementTier.silver => l10n.tierSilverLabel,
      AchievementTier.gold => l10n.tierGoldLabel,
      AchievementTier.platinum => l10n.tierPlatinumLabel,
    };

    final detail = detailAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
        // ── Big banner with X button overlay ──
        SizedBox(
          height: 240,
          child: Stack(
            children: [
              // Banner image or gradient fallback
              Positioned.fill(
                child: detail?.coverPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: detail!.coverPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                        errorWidget: (_, __, ___) =>
                            _BannerGradient(color: accentColor),
                      )
                    : _BannerGradient(color: accentColor),
              ),
              // Dark gradient scrim at bottom for contrast
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.bgCard.withValues(alpha: 0.9),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Close (X) button — rim tinted to match the pin-type accent
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.x,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
              // Locked/unlocked status indicator
              Positioned(
                bottom: 16,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? AppColors.success.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        achievement.isUnlocked
                            ? LucideIcons.check
                            : LucideIcons.lock,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        achievement.isUnlocked ? 'Unlocked' : 'Locked',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Content padding wrapper
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

        // Title
        Text(
          RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // Description (prefer Supabase detail if available)
        Text(
          detail?.description ??
              RegistryL10n.achievementDescription(
                locale, achievement.id, achievement.description,
              ),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Tier + XP badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tierColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                tierLabel,
                style: TextStyle(
                  color: tierColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.xpGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.xpGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.zap, size: 12, color: AppColors.xpGreen),
                  const SizedBox(width: 4),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: TextStyle(
                      color: AppColors.xpGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Claim button for pending achievements
        if (achievement.isPendingClaim && !achievement.isUnlocked) ...[
          const SizedBox(height: 20),
          _ClaimButton(achievementId: achievement.id),
        ],

        // Retroactive claim button for locked achievements (even without pending/GPS).
        // One-tap unlock with today's date — user can refine details afterwards
        // by tapping "Edit visit" from the unlocked state.
        if (!achievement.isUnlocked && !achievement.isPendingClaim) ...[
          const SizedBox(height: 20),
          _RetroactiveClaimButton(achievementId: achievement.id),
        ],

        // Add photo / Add remark buttons for unlocked achievements
        if (achievement.isUnlocked) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _AddPhotoButton(achievement: achievement)),
              const SizedBox(width: 8),
              Expanded(child: _AddRemarkButton(achievement: achievement)),
            ],
          ),
        ],

        // Collection progress cascade
        _buildCollectionProgress(ref),

        // Visit history — handles first visit + revisits + retroactive adds
        if (achievement.isUnlocked) ...[
          const SizedBox(height: 16),
          _VisitHistoryCard(achievement: achievement, locale: locale),
        ],

        // User notes
        if (achievement.notes != null && achievement.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              achievement.notes!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        // ── Rich data from Supabase ──
        if (detail != null) ...[
          // Location info (city, country)
          if (detail.city != null || detail.country != null) ...[
            const SizedBox(height: 20),
            _InfoRow(
              icon: LucideIcons.mapPin,
              text: [detail.city, detail.country].whereType<String>().join(', '),
            ),
          ],

          // Opening hours
          if (detail.openingHours.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildOpeningHours(context, detail),
          ],

          // Website
          if (detail.website != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(detail.website!),
              child: _InfoRow(
                icon: LucideIcons.globe,
                text: detail.website!,
                isLink: true,
              ),
            ),
          ],

          // Phone
          if (detail.phone != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl('tel:${detail.phone}'),
              child: _InfoRow(
                icon: LucideIcons.phone,
                text: detail.phone!,
                isLink: true,
              ),
            ),
          ],

          // Photo gallery
          if (detail.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildPhotoGallery(detail),
          ],
        ],

        // Loading indicator for rich data
        if (detailAsync.isLoading) ...[
          const SizedBox(height: 20),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
            ], // close inner Column children
          ), // close Column
        ), // close Padding
      ], // close ListView children
    ), // close ListView
  ); // close Scaffold
  }

  Widget _buildCollectionProgress(WidgetRef ref) {
    final collectionId = achievement.collectionId;
    if (collectionId == null) return const SizedBox.shrink();

    final all = ref.read(achievementsProvider).allAchievements;
    final tiers = <_TierProgress>[];

    if (ch.continentCollectionIds.contains(collectionId)) {
      // ── Countries collection ──
      final continentLabel =
          ch.continentLabels[collectionId] ?? collectionId;

      // Continent tier
      final continentList =
          all.where((a) => a.collectionId == collectionId).toList();
      tiers.add(_TierProgress(
        label: 'Countries ($continentLabel)',
        unlocked: continentList.where((a) => a.isUnlocked).length,
        total: continentList.length,
        color: AppColors.gold,
        tierLabel: 'Continent',
      ));

      // Global tier
      final globalList = all
          .where(
              (a) => ch.continentCollectionIds.contains(a.collectionId))
          .toList();
      tiers.add(_TierProgress(
        label: 'Countries (Global)',
        unlocked: globalList.where((a) => a.isUnlocked).length,
        total: globalList.length,
        color: AppColors.platinum,
        tierLabel: 'Global',
      ));
    } else if (ch.themedCollectionIds.contains(collectionId)) {
      // ── Themed collection ──
      final collLabel = ch.themedLabels[collectionId] ?? collectionId;
      final allInColl =
          all.where((a) => a.collectionId == collectionId).toList();

      // Country tier (only if >1 achievement shares the country)
      final country = ch.countryOf(achievement);
      if (country != null) {
        final countryList =
            allInColl.where((a) => ch.countryOf(a) == country).toList();
        if (countryList.length > 1) {
          final cLabel = ch.countryLabels[country] ?? country;
          tiers.add(_TierProgress(
            label: '$collLabel ($cLabel)',
            unlocked: countryList.where((a) => a.isUnlocked).length,
            total: countryList.length,
            color: AppColors.silver,
            tierLabel: 'Country',
          ));
        }
      }

      // Continent tier
      final continent = ch.continentOfThemed(achievement);
      if (continent != null) {
        final contLabel = ch.continentLabels[continent] ?? continent;
        final contList = allInColl
            .where((a) => ch.continentOfThemed(a) == continent)
            .toList();
        tiers.add(_TierProgress(
          label: '$collLabel ($contLabel)',
          unlocked: contList.where((a) => a.isUnlocked).length,
          total: contList.length,
          color: AppColors.gold,
          tierLabel: 'Continent',
        ));
      }

      // Global tier
      tiers.add(_TierProgress(
        label: '$collLabel (Global)',
        unlocked: allInColl.where((a) => a.isUnlocked).length,
        total: allInColl.length,
        color: AppColors.platinum,
        tierLabel: 'Global',
      ));
    } else if (ch.localCollectionIds.contains(collectionId)) {
      // ── Local collection ──
      final label = ch.localLabels[collectionId] ?? collectionId;
      final localList =
          all.where((a) => a.collectionId == collectionId).toList();
      tiers.add(_TierProgress(
        label: label,
        unlocked: localList.where((a) => a.isUnlocked).length,
        total: localList.length,
        color: AppColors.bronze,
        tierLabel: 'Local',
      ));
    }

    if (tiers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCardLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.layers,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Collection Progress',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < tiers.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildTierRow(tiers[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(_TierProgress tier) {
    final pct = tier.total > 0 ? tier.unlocked / tier.total : 0.0;
    final isComplete = tier.total > 0 && tier.unlocked == tier.total;

    return Row(
      children: [
        // Tier badge
        Container(
          width: 58,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: tier.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: tier.color.withValues(alpha: 0.3)),
          ),
          child: Text(
            tier.tierLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: tier.color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Label + progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 4,
                  backgroundColor:
                      AppColors.bgCardLight.withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation(
                    isComplete ? AppColors.success : tier.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Count
        Text(
          '${tier.unlocked}/${tier.total}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isComplete ? AppColors.success : AppColors.textMuted,
          ),
        ),
        if (isComplete) ...[
          const SizedBox(width: 4),
          Icon(LucideIcons.check, size: 12, color: AppColors.success),
        ],
      ],
    );
  }

  Widget _buildOpeningHours(BuildContext context, AchievementDetail detail) {
    final dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final dayLabels = {
      'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu',
      'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clock, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'Opening Hours',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...dayOrder
              .where((d) => detail.openingHours.containsKey(d))
              .map((day) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            dayLabels[day] ?? day,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          detail.openingHours[day]!,
                          style: TextStyle(
                            color: detail.openingHours[day] == 'closed'
                                ? AppColors.error.withValues(alpha: 0.7)
                                : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(AchievementDetail detail) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: detail.photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: detail.photoUrls[index],
            width: 160,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 160,
              height: 120,
              color: AppColors.bgCardLight,
            ),
            errorWidget: (_, __, ___) => Container(
              width: 160,
              height: 120,
              color: AppColors.bgCardLight,
              child: Icon(LucideIcons.imageOff, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

