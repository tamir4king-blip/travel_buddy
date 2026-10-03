import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:path/path.dart' as path;

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  /// Uploads an avatar image to Supabase Storage.
  /// Returns the public URL on success, or the [localFilePath] as-is in demo mode.
  Future<String?> uploadAvatar(String localFilePath) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return localFilePath;

      final file = File(localFilePath);
      if (!await file.exists()) return localFilePath;

      final ext = path.extension(localFilePath).replaceFirst('.', '');
      final storagePath = '$userId/avatar.$ext';

      await _client.storage.from('photos').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          _client.storage.from('photos').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e, st) {
      logError(e, st, context: 'profileRepository.uploadAvatar', report: true);
      return localFilePath;
    }
  }

  /// Upserts the user profile to the remote `profiles` table.
  ///
  /// total_xp / level / is_premium are deliberately NOT sent: those columns
  /// are server-owned (computed by XP triggers) and the column-level grants
  /// added in 20260610000002_server_authoritative_xp.sql reject any
  /// statement that touches them.
  Future<void> syncProfileToRemote(UserProfile profile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('profiles').upsert({
        'id': userId,
        'display_name': profile.displayName,
        'username': profile.username,
        'bio': profile.bio,
        'avatar_url': profile.avatarUrl,
        'is_public': profile.isPublic,
      });
    } catch (e, st) {
      // Local persistence is primary
      logError(e, st, context: 'profileRepository.syncToRemote', report: true);
    }
  }

  /// Fetches the user profile from the remote `profiles` table.
  Future<UserProfile?> loadProfileFromRemote() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final data =
          await _client.from('profiles').select().eq('id', userId).maybeSingle();

      if (data == null) return null;

      return UserProfile(
        id: userId,
        displayName: data['display_name'] as String? ?? 'Traveler',
        username: data['username'] as String?,
        bio: data['bio'] as String?,
        avatarUrl: data['avatar_url'] as String?,
        totalXp: data['total_xp'] as int? ?? 0,
        level: data['level'] as int? ?? 1,
        isPremium: data['is_premium'] as bool? ?? false,
        isPublic: data['is_public'] as bool? ?? true,
        createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (e, st) {
      logError(e, st, context: 'profileRepository.loadFromRemote',
          report: true);
      return null;
    }
  }
}
