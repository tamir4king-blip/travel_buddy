import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/data/achievement_definitions_repository.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';

/// Admin-only view of achievement definition changes (polygon / radius / pin).
/// Reads from the `achievement_definition_history` table populated by a
/// trigger on `achievement_definitions`.
class ChangeHistoryScreen extends ConsumerStatefulWidget {
  const ChangeHistoryScreen({super.key});

  @override
  ConsumerState<ChangeHistoryScreen> createState() =>
      _ChangeHistoryScreenState();
}

class _ChangeHistoryScreenState extends ConsumerState<ChangeHistoryScreen> {
  String? _filterAchievementId; // null = show everything
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (!SupabaseConfig.isConfigured) return [];
    final client = ref.read(supabaseClientProvider);
    final repo = AchievementDefinitionsRepository(client);
    if (_filterAchievementId != null) {
      return repo.fetchHistory(_filterAchievementId!);
    }
    return repo.fetchRecentHistory(limit: 100);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider).allAchievements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change History'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(achievements),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Failed to load history:\n${snapshot.error}',
                        style: TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final rows = snapshot.data ?? const [];
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'No changes logged yet.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _HistoryRow(
                    row: rows[i],
                    achievementTitle:
                        _titleFor(rows[i]['achievement_id'] as String?, achievements),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(List allAchievements) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.bgCard,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _filterAchievementId,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Filter by achievement',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All achievements'),
                ),
                ...allAchievements.map<DropdownMenuItem<String?>>((a) {
                  return DropdownMenuItem<String?>(
                    value: a.id as String,
                    child: Text(
                      a.title as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (v) {
                setState(() {
                  _filterAchievementId = v;
                  _future = _load();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _titleFor(String? id, List allAchievements) {
    if (id == null) return 'Unknown';
    for (final a in allAchievements) {
      if (a.id == id) return a.title as String;
    }
    return id;
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final String achievementTitle;

  const _HistoryRow({required this.row, required this.achievementTitle});

  @override
  Widget build(BuildContext context) {
    final field = row['field'] as String? ?? '';
    final changedAt = row['changed_at'] as String?;
    final changedByEmail = row['changed_by_email'] as String? ?? 'unknown';
    final oldValue = row['old_value'];
    final newValue = row['new_value'];

    final timestamp = changedAt != null
        ? DateFormat.yMMMd().add_Hm().format(DateTime.parse(changedAt).toLocal())
        : '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _fieldChip(field),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievementTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timestamp,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'by $changedByEmail',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 8),
          _valueBlock('Old', oldValue, AppColors.error),
          const SizedBox(height: 4),
          _valueBlock('New', newValue, AppColors.success),
        ],
      ),
    );
  }

  Widget _fieldChip(String field) {
    final (label, color) = switch (field) {
      'claim_polygon' => ('Polygon', AppColors.accent),
      'claim_radius' => ('Radius', AppColors.info),
      'pin' => ('Pin', AppColors.primary),
      _ => (field, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _valueBlock(String label, dynamic value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            _summarize(value),
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Compact representation. For polygons, just show vertex count so the
  /// row stays readable. For scalars/pins, show the raw JSON.
  String _summarize(dynamic value) {
    if (value == null) return 'null';
    if (value is List) {
      return '${value.length} vertices';
    }
    if (value is Map) {
      return jsonEncode(value);
    }
    return value.toString();
  }
}
