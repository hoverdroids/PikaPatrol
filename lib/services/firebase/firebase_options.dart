// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:pika_patrol/project_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: FirebaseProjectConfig.ANDROID_API_KEY,
    appId: FirebaseProjectConfig.ANDROID_APP_ID,
    messagingSenderId: FirebaseProjectConfig.MESSAGING_SENDER_ID,
    projectId: FirebaseProjectConfig.PROJECT_ID,
    databaseURL: FirebaseProjectConfig.DATABASE_URL,
    storageBucket: FirebaseProjectConfig.STORAGE_BUCKET,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: FirebaseProjectConfig.IOS_API_KEY,
    appId: FirebaseProjectConfig.IOS_APP_ID,
    messagingSenderId: FirebaseProjectConfig.MESSAGING_SENDER_ID,
    projectId: FirebaseProjectConfig.PROJECT_ID,
    databaseURL: FirebaseProjectConfig.DATABASE_URL,
    storageBucket: FirebaseProjectConfig.STORAGE_BUCKET,
    androidClientId: FirebaseProjectConfig.ANDROID_CLIENT_ID,
    iosClientId: FirebaseProjectConfig.IOS_CLIENT_ID,
    iosBundleId: FirebaseProjectConfig.IOS_BUNDLE_ID,
  );
}
