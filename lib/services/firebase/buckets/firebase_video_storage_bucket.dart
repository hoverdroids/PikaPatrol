import 'package:pika_patrol/utils/media_utils.dart';
import 'firebase_storage_bucket.dart';

class FirebaseVideoStorageBucket extends FirebaseStorageBucket {

  static const String NAME = "video";

  FirebaseVideoStorageBucket(
    super.bucket,
    {
      super.name = NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_VIDEO
    }
  );
}