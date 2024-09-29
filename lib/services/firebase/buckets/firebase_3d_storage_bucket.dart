import 'package:pika_patrol/utils/media_utils.dart';

import '../../../model/firebase_value_exception_pair.dart';
import 'firebase_storage_bucket.dart';

class Firebase3dStorageBucket extends FirebaseStorageBucket {

  static const String FOLDER_NAME = "3D";

  Firebase3dStorageBucket(
    super.bucket,
    {
      super.folderName = FOLDER_NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_3D
    }
  );

  Future<FirebaseValueExceptionPair<String>> upload3dFile(String localFilepath) async {
    return await super.uploadFile(localFilepath);
  }

  Future<Map<String, FirebaseValueExceptionPair<String>>> upload3dFiles(List<String> localFilepaths) async {
    return await super.uploadFiles(localFilepaths);
  }
}