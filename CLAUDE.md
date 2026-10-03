# Travel Buddy Mobile - Claude Code Instructions

## Building APKs

When asked to build/create an APK:

1. **Always build a RELEASE APK** — never a debug APK unless explicitly asked for debug.
2. **Always embed the `.env` file** using `--dart-define-from-file=.env` so all secrets (Supabase, Mapbox, Sentry) are compiled into the build.
3. The correct command is:
   ```
   flutter build apk --release --dart-define-from-file=.env
   ```
4. The output APK will be at: `build/app/outputs/flutter-apk/app-release.apk`
5. Set `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr` before building.
