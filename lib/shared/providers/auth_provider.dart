import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/features/auth/data/auth_repository.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  StreamSubscription<sb.AuthState>? _authSubscription;

  AuthNotifier(this._repo) : super(const AuthState()) {
    if (SupabaseConfig.isConfigured) {
      _initSupabaseAuth();
    }
  }

  void _initSupabaseAuth() {
    final currentUser = _repo.currentUser;
    if (currentUser != null) {
      state = AuthState(
        user: _userProfileFromSupabase(currentUser),
        isAuthenticated: true,
      );
    }

    _authSubscription = _repo.authStateChanges.listen((authState) {
      final user = authState.session?.user;
      if (user != null) {
        state = AuthState(
          user: _userProfileFromSupabase(user),
          isAuthenticated: true,
        );
      } else {
        state = const AuthState();
      }
    });
  }

  UserProfile _userProfileFromSupabase(sb.User user) {
    final meta = user.userMetadata;
    return UserProfile(
      id: user.id,
      displayName: meta?['display_name'] as String? ??
          user.email?.split('@').first ??
          'Traveler',
      username: meta?['username'] as String?,
      bio: meta?['bio'] as String?,
      avatarUrl: meta?['avatar_url'] as String?,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  Future<void> signIn(String email, String password) async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server connection unavailable. Please check your configuration.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.signIn(email, password);
    } on sb.AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> signUp(
      String email, String password, String displayName) async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server connection unavailable. Please check your configuration.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.signUp(email, password, displayName);
    } on sb.AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await _repo.signOut();
    }
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
