part of '../achievement_detail_sheet.dart';

/// "Add photo" tile — opens image picker, appends to achievement.photos.
class _AddPhotoButton extends ConsumerWidget {
  final Achievement achievement;
  const _AddPhotoButton({required this.achievement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final url = await _promptAddPhoto(context);
        if (url == null || url.isEmpty) return;
        await ref
            .read(achievementsProvider.notifier)
            .addPhoto(achievement.id, url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo added'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      icon: const Icon(LucideIcons.imagePlus, size: 14),
      label: const Text('Add photo', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Very minimal prompt — asks for a URL. A future iteration can swap in the
  /// full photo picker / camera flow.
  Future<String?> _promptAddPhoto(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Add photo URL',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// "Add remark" tile — opens a text field, replaces the achievement.notes.
class _AddRemarkButton extends ConsumerWidget {
  final Achievement achievement;
  const _AddRemarkButton({required this.achievement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final text = await _promptEditRemark(context);
        if (text == null) return;
        await ref
            .read(achievementsProvider.notifier)
            .setNotes(achievement.id, text.isEmpty ? null : text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remark saved'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      icon: const Icon(LucideIcons.messageSquarePlus, size: 14),
      label: Text(
        achievement.notes != null && achievement.notes!.isNotEmpty
            ? 'Edit remark'
            : 'Add remark',
        style: const TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<String?> _promptEditRemark(BuildContext context) async {
    final ctrl = TextEditingController(text: achievement.notes ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Remark',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Leave a note about this visit...',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
