import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralised error logging used in place of silent `catch (_) {}` blocks.
///
/// In debug builds every call prints the error (and stack trace) to the
/// console so failures are visible during development.
///
/// Set [report] to `true` for *unexpected* failures that should be tracked in
/// Sentry — e.g. remote sync errors, data-integrity / parse failures. Leave it
/// `false` (the default) for *expected*, high-frequency failures such as
/// offline geocoding, a map annotation that was already removed, or a denied
/// permission; reporting those would flood the Sentry quota and bury real
/// signal.
///
/// [context] is a short tag (e.g. `'achievements.sync'`) that identifies where
/// the error came from, making both console output and Sentry events easier to
/// triage.
void logError(
  Object error,
  StackTrace? stackTrace, {
  String? context,
  bool report = false,
}) {
  if (kDebugMode) {
    debugPrint('[${context ?? 'error'}] $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  if (report) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: context == null
          ? null
          : (scope) => scope.setTag('context', context),
    );
  }
}
