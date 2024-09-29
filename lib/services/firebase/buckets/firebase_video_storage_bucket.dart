import 'package:pika_patrol/utils/media_utils.dart';

import '../../../model/firebase_value_exception_pair.dart';
import 'firebase_storage_bucket.dart';

class FirebaseVideoStorageBucket extends FirebaseStorageBucket {

  static const String FOLDER_NAME = "video";

  FirebaseVideoStorageBucket(
    super.bucket,
    {
      super.folderName = FOLDER_NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_VIDEO
    }
  );

  Future<FirebaseValueExceptionPair<String>> uploadVideo(String localFilepath) async {
    return await super.uploadFile(localFilepath);
  }

  Future<Map<String, FirebaseValueExceptionPair<String>>> uploadVideos(List<String> localFilepaths) async {
    return await super.uploadFiles(localFilepaths);
  }
}