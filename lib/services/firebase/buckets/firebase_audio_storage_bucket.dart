import 'package:pika_patrol/utils/media_utils.dart';
import 'firebase_storage_bucket.dart';

class FirebaseAudioStorageBucket extends FirebaseStorageBucket {

  static const String NAME = "audio";

  FirebaseAudioStorageBucket(
    super.bucket,
    {
      super.name = NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_AUDIO
    }
  );
}