# Pika Patrol

Pika Patrol is a Flutter mobile app for recording, caching, and uploading pika observations with images, audio, and location metadata.

## Current App Version

- Version name: `3.4.0`
- Version code / build number: `334`

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
