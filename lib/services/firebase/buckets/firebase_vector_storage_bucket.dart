import 'package:pika_patrol/utils/media_utils.dart';
import 'firebase_storage_bucket.dart';

class FirebaseVectorStorageBucket extends FirebaseStorageBucket {

  static const String NAME = "vector";

  FirebaseVectorStorageBucket(
    super.bucket,
    {
      super.name = NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_IMAGE_VECTOR
    }
  );
}