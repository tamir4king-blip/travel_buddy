import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';
import 'package:travel_buddy_mobile/features/profile/data/profile_repository.dart';

/// Provides a [ProfileRepository] when Supabase is configured, otherwise null.
final profileSyncServiceProvider = Provider<ProfileRepository?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  final client = ref.watch(supabaseClientProvider);
  return ProfileRepository(client);
});
