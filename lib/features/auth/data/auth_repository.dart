import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthRepository {
  final sb.SupabaseClient _client;
  AuthRepository(this._client);

  Stream<sb.AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  sb.User? get currentUser => _client.auth.currentUser;

  Future<void> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signUp(String email, String password, String displayName) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

  Future<void> signOut() => _client.auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(sb.Supabase.instance.client),
);
