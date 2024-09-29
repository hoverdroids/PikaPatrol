import 'package:pika_patrol/utils/media_utils.dart';

import '../../../model/firebase_value_exception_pair.dart';
import 'firebase_storage_bucket.dart';

class FirebaseAudioStorageBucket extends FirebaseStorageBucket {

  static const String FOLDER_NAME = "audio";

  FirebaseAudioStorageBucket(
    super.bucket,
    {
      super.folderName = FOLDER_NAME,
      super.restrictMimeTypesTo,
      super.restrictFileTypesTo = MediaUtils.FILE_FORMATS_AUDIO
    }
  );

  Future<FirebaseValueExceptionPair<String>> uploadAudioFile(String localFilepath) async {
    return await super.uploadFile(localFilepath);
  }

  Future<Map<String, FirebaseValueExceptionPair<String>>> uploadAudioFiles(List<String> localFilepaths) async {
    return await super.uploadFiles(localFilepaths);
  }
}