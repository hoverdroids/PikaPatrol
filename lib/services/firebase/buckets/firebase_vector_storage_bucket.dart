import 'package:pika_patrol/utils/media_utils.dart';

import '../../../model/firebase_value_exception_pair.dart';
import 'firebase_storage_bucket.dart';

class FirebaseVectorStorageBucket extends FirebaseStorageBucket {

  static const String FOLDER_NAME = "vector";

  FirebaseVectorStorageBucket(
    super.bucket,
    {
      super.folderName = FOLDER_NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_IMAGE_VECTOR
    }
  );

  Future<FirebaseValueExceptionPair<String>> uploadVectorFile(String localFilepath) async {
    return await super.uploadFile(localFilepath);
  }

  Future<Map<String, FirebaseValueExceptionPair<String>>> uploadVectorFiles(List<String> localFilepaths) async {
    return await super.uploadFiles(localFilepaths);
  }
}