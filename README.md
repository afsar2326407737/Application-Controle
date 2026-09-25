# Unloop

Unloop is a calm, private, Android-first Flutter app for reducing unplanned smartphone use. It emphasizes awareness and small, reversible actions rather than guilt, streaks used as punishment, or aggressive blocking.

## What is implemented

- Five-step onboarding with optional name, daily intention, focus duration, and app selection
- Permission education that works correctly when Usage Access or notifications are denied
- Coach Mode dashboard with daily app-time progress, most-used apps, focus totals, and calm risk copy
- Timestamp-based 15/25/45/60-minute focus sessions that recover after backgrounding and process restarts
- Urge intervention with feeling check-in, 5/10/20-minute cooldown, grounding alternatives, and nonjudgmental decisions
- Seven-day insights using `fl_chart`, focus history, app-open events, and trend suggestions
- Light and dark Material 3 themes with accessible labels, 48 dp targets, and restrained motion
- Optional Personal Blocker accessibility service that redirects whole selected apps back to the Unloop urge flow
- Android Digital Wellbeing guidance for Coach Mode
- Local SQLite history, `SharedPreferences` settings, Workmanager reminders, JSON export, and complete data deletion
- No account, cloud service, advertisement, analytics identifier, AI feature, or release `INTERNET` permission

## Architecture

The Flutter code follows MVVM with repository-backed data sources:

```text
lib/
├── core/
│   ├── constants/
│   ├── routing/
│   ├── services/
│   ├── theme/
│   └── utils/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── presentation/
│   ├── viewmodels/
│   ├── views/
│   └── widgets/
├── app.dart
└── main.dart
```

- `ChangeNotifier` view models own screen state and user actions.
- Views render state and forward actions.
- Repositories coordinate local and platform data sources.
- Android APIs are isolated behind the `com.unloop.app/native` method channel.
- Focus timing stores accumulated elapsed time plus the last resume timestamp, avoiding drift and surviving restarts.

Android-native code is under:

```text
android/app/src/main/kotlin/com/example/my_first_app/
├── MainActivity.kt
└── AppBlockerService.kt
```

The physical directory name is inherited from the Flutter starter; Kotlin package declarations and the Android namespace are `com.unloop.app`.

## Requirements

- Flutter 3.47+ / Dart 3.13+
- Android SDK 36
- JDK 17
- Android device or emulator running API 24+

Current validated toolchain:

```text
Flutter 3.47.2
Dart 3.13.2
Android compile/target SDK 36
Gradle 9.5
AGP 9.1
```

## Run

```bash
flutter pub get
flutter run -d <android-device-id>
```

The package/application ID is `com.unloop.app`.

## Validate

```bash
flutter analyze
flutter test
flutter build apk --release
```

The generated release artifact is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The current release build is signed with the local debug key so it can be installed directly for personal testing. Configure a private release keystore before any public distribution.

## Android permissions

Unloop requests capabilities only from an explained user action:

- **Usage Access:** reads launchable package names and Android foreground usage durations after explicit opt-in. It does not read app content.
- **Notifications:** optional focus and daily-reflection messages.
- **Vibration:** optional focus-session alert feedback.
- **Accessibility:** optional, Personal Blocker Mode only. It checks window package transitions and cannot retrieve window content.
- **No camera, microphone, contacts, photos, or location.**

The packaged release manifest was audited and contains no `android.permission.INTERNET`. Workmanager contributes network-state and scheduling capabilities, but Unloop does not open a network connection.

## Modes

### Coach Mode

Recommended default and suitable for a Play Store-oriented product direction:

- Local usage insights
- Focus sessions and urge interventions
- Gentle reminders
- Direct links to Android Digital Wellbeing and Usage Access settings

### Personal Blocker Mode

Optional personal-installation feature:

- Redirects the entire selected app to the Unloop urge flow
- Cannot block only YouTube Shorts
- Includes an in-app emergency stop
- Can always be disabled by Android or from Unloop settings
- Should be omitted or reconsidered for Play Store distribution because accessibility services require prominent disclosure and policy review

## Local data

Unloop stores settings in Android `SharedPreferences` and history in `unloop.db`. The export action creates a JSON copy in the app cache and opens Android’s share sheet. “Clear all data” removes Unloop history and preferences; it does not revoke Android system permissions.

## Manual Android test checklist

1. Complete onboarding while denying every permission.
2. Grant Usage Access and confirm app durations appear on Today.
3. Start a focus session, background the app, wait, reopen it, and verify the remaining time is accurate.
4. Force-stop and relaunch during a session and confirm the session can be resumed.
5. Complete the urge cooldown and verify no streak is punished.
6. In Personal Blocker Mode, enable Unloop in Android Accessibility settings and open a selected app.
7. Confirm the Unloop urge flow appears and the emergency stop disables redirection.
8. Export data, clear all data, and confirm onboarding restarts with empty history.
9. Test light/dark themes and TalkBack labels.

Automated tests and an Android 17 emulator smoke test are included in the current validation. OEM-specific Usage Access and background-notification behavior should still be checked on a physical device before wider personal use.
