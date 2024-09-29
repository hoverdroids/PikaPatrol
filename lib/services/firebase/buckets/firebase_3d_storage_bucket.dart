import 'package:pika_patrol/utils/media_utils.dart';

import '../../../model/firebase_value_exception_pair.dart';
import 'firebase_storage_bucket.dart';

class Firebase3dStorageBucket extends FirebaseStorageBucket {

  static const String NAME = "3D";

  Firebase3dStorageBucket(
    super.bucket,
    {
      super.name = NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_3D
    }
  );
}