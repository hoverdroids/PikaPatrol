import '../../utils/constants.dart';

class FirebaseConstants {
  static const DATABASE_URL_PREFIX = Constants.HTTPS_URL_PREFIX;
  static const DATABASE_URL_SUFFIX = ".firebaseio.com";

  static const STORAGE_BUCKET_URL_PREFIX = "gs://";
  static const STORAGE_BUCKET_SUFFIX = ".appspot.com";

  static const EMULATOR_PORT_FIRESTORE = 8080;
  static const EMULATOR_PORT_AUTHENTICATION = 9099;
}