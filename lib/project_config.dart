import 'package:firebase_auth/firebase_auth.dart';
import 'package:pika_patrol/utils/constants.dart';

import 'services/firebase/firebase_constants.dart';

class ProjectConfig {
  static const ANDROID_APPLICATION_ID = "com.tcubedstudios.pikaPatrol";
  static const IOS_BUNDLE_ID = ANDROID_APPLICATION_ID;
}

class FirebaseProjectConfig {
  static const AUTHENTICATION_USE_EMULATOR = false;
  static const AUTHENTICATION_EMULATOR_IP = Constants.LOCALHOST;
  static const AUTHENTICATION_EMULATOR_PORT = FirebaseConstants.EMULATOR_PORT_AUTHENTICATION;
  static const Persistence? AUTHENTICATION_WEB_PERSISTENCE = null;

  static const FIRESTORE_USE_EMULATOR = false;
  static const FIRESTORE_EMULATOR_IP = Constants.LOCALHOST;
  static const FIRESTORE_EMULATOR_PORT = FirebaseConstants.EMULATOR_PORT_FIRESTORE;
  static const FIRESTORE_PERSISTENCE_ENABLED = true;
  static const FIRESTORE_SSL_ENABLED = false;

  static const PROJECT_ID = "pikajoe-97c5c";
  static const MESSAGING_SENDER_ID = "954700599379";

  static const DATABASE_URL = "${FirebaseConstants.DATABASE_URL_PREFIX}$PROJECT_ID${FirebaseConstants.DATABASE_URL_SUFFIX}";

  static const STORAGE_BUCKET = "$PROJECT_ID${FirebaseConstants.STORAGE_BUCKET_SUFFIX}";
  static const STORAGE_BUCKET_URL = "${FirebaseConstants.STORAGE_BUCKET_URL_PREFIX}$STORAGE_BUCKET";

  static const ANDROID_API_KEY = "AIzaSyD8PRLrNZxWXr7SjmNTKM8sIFldEl-arlE";
  static const ANDROID_APP_ID = "1:954700599379:android:4a351094efe317d98c36a6";
  static const ANDROID_CLIENT_ID = "954700599379-60sbdv04n37o4rjug5hii117cc650sf7.apps.googleusercontent.com";
  static const ANDROID_APPLICATION_ID = ProjectConfig.ANDROID_APPLICATION_ID;

  static const IOS_API_KEY = "AIzaSyBOT98d6WYldKY0UPvt03TGzh5xQaccr1k";
  static const IOS_APP_ID = "1:954700599379:ios:779983c3ccc366828c36a6";
  static const IOS_CLIENT_ID = "954700599379-qp2i96hjt2shcf3hmkoa8dvrb3nvpmp7.apps.googleusercontent.com";
  static const IOS_BUNDLE_ID = ProjectConfig.IOS_BUNDLE_ID;
}
