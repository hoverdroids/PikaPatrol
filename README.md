# Pika Patrol

Pika Patrol is a Flutter mobile app for recording, caching, and uploading pika observations with images, audio, and location metadata.

## Current App Version

- Version name: `3.5.0`
- Version code / build number: `335`

## Release Baselines

These values are configured in this repository for current App Store / Google Play submissions:

- Flutter: `3.47.7`, pinned with [FVM](https://fvm.app) in `.fvmrc`
- Android `minSdk`: `24` (Flutter default)
- Android `targetSdk`: `36` (Google Play requirement from Aug 31, 2026)
- Android `compileSdk`: `37` (needed by `permission_handler_android`)
- Android toolchain: AGP `9.2.1`, Gradle `9.4.1`, Kotlin `2.4.0`, Java 17
- iOS deployment target: `16.0`
- iOS plugins come from Swift Package Manager (no CocoaPods)

## Build Commands

Run from project root unless noted. Install FVM once with `brew install fvm`, then use `fvm flutter` so the pinned Flutter version is used.

### Install dependencies

```zsh
fvm install
fvm flutter pub get
```

### Android (Google Play)

Preferred output for Play Console:

```zsh
fvm flutter build appbundle --release
```

Optional APK output:

```zsh
fvm flutter build apk --release
```

Release signing reads `android/key.properties` (not committed).

### iOS (App Store)

```zsh
fvm flutter build ipa --release
```

Upload the `.ipa` from `build/ios/ipa` with Xcode Organizer or Transporter. Building from the command line lets `permission_handler` read the camera, microphone, photo, location and media library permissions from `ios/Runner/Info.plist`.

## Localization Notes

- "Cached Observations" user-facing text has been renamed to "My Observations" for all supported locales.
- Observation card button text ("View Observation") now refreshes to match the selected locale.

## Spending Kill Switch

Firestore and Cloud Storage have no spend caps, so a kill switch guards against a surprise bill. When the project's monthly budget is reached, it locks Firestore and Storage so only admins can get in. The app stops reading, downloading and uploading, and nothing is deleted. Observations still save on the phone and upload once it reopens. It trips at most once a month.

The switch is a separate Cloud Function from the `firebase-billing-kill-switch` repo. Full setup is in `docs/firebase-runbook.md`.

- **Turn it on:** deploy the kill switch function and connect it to the budget.
- **Turn it off:** disconnect it from the budget, or delete the `killSwitch` function in the Firebase console.
- **Reopen after it trips:** from the `firebase/` folder, deploy the normal rules again with `firebase deploy --only firestore:rules,storage`.
