/// Supabase configuration.
///
/// Values are injected at build time via --dart-define:
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
/// ```
///
/// You can also create a `.env` file and use --dart-define-from-file:
///
/// ```
/// flutter run --dart-define-from-file=.env
/// ```
class SupabaseConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Whether Supabase was successfully initialized at startup.
  /// Set by main.dart after Supabase.initialize() completes.
  static bool initialized = false;

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty && initialized;
}
