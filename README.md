# Pika Patrol

Pika Patrol is a Flutter mobile app for recording, caching, and uploading pika observations with images, audio, and location metadata.

## Current App Version

- Version name: `3.3.8`
- Version code / build number: `331`

## Release Baselines

These values are configured in this repository for current App Store / Google Play submissions:

- Android `minSdkVersion`: `23`
- Android `targetSdkVersion`: `35`
- Android `compileSdkVersion`: `35`
- iOS deployment target: `16.0`

## Build Commands

Run from project root unless noted.

### Install dependencies

```zsh
flutter pub get
cd ios
pod install
cd ..
```

### Android (Google Play)

Preferred output for Play Console:

```zsh
flutter build appbundle --release
```

Optional APK output:

```zsh
flutter build apk --release
```

### iOS (App Store)

```zsh
flutter build ios --release
```

Then archive and upload in Xcode (`Product` -> `Archive`) using the `Runner` scheme.

## Localization Notes

- "Cached Observations" user-facing text has been renamed to "My Observations" for all supported locales.
- Observation card button text ("View Observation") now refreshes to match the selected locale.
