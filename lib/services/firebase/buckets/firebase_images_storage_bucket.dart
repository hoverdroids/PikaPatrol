import '../../../utils/media_utils.dart';
import 'firebase_storage_bucket.dart';

class FirebaseImagesStorageBucket extends FirebaseStorageBucket {

  static const String NAME = "images";

  FirebaseImagesStorageBucket(
    super.bucket,
    {
      super.name = NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_IMAGE_RASTER
    }
  );
}