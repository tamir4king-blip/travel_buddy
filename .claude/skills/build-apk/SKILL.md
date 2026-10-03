---
name: build-apk
description: Build a release APK with .env secrets embedded
---

Build a release APK with environment variables embedded.

Run this exact command:

```bash
export JAVA_HOME="C:\Program Files\Android\Android Studio\jbr" && cd "C:\Users\tamir\Desktop\travel_buddy_flutter-main\travel_buddy_mobile" && flutter build apk --release --dart-define-from-file=.env
```

After the build completes, report the result and the APK path (`build/app/outputs/flutter-apk/app-release.apk`).
