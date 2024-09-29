import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:pika_patrol/model/firebase_value_exception_pair.dart';
import 'package:pika_patrol/providers/filehost/file_host.dart';

import '../../../utils/path_utils.dart';
import '../utils/firebase_utils.dart';
import '../firebase_constants.dart';

abstract class FirebaseStorageBucket implements FileHost<FirebaseException> {

  FirebaseStorage? storage;
  FirebaseException? storageInitializationException;

  String bucket;
  late String bucketUrl;

  @override
  String name;

  @override
  Set<String>? restrictMimeTypesTo;

  @override
  Set<String>? restrictFileTypesTo;

  //region Constructors
  FirebaseStorageBucket(this.bucket, {required this.name, this.restrictMimeTypesTo, this.restrictFileTypesTo}) {
    bucketUrl = "${FirebaseConstants.STORAGE_BUCKET_URL_PREFIX}$bucket";

    try {
      storage = FirebaseStorage.instanceFor(bucket: bucketUrl);
    } on FirebaseException catch (e) {
      storageInitializationException = e;
    }
  }
  //endregion

  //region Upload
  @override
  Future<FirebaseValueExceptionPair<String>> uploadFile(String filepathOrUrl) async {
    final returnValue = FirebaseValueExceptionPair(filepathOrUrl, exception: storageInitializationException);

    final storage = this.storage;
    if (storage == null) {
      //return value that is input path and an exception for the storage
      return returnValue;
    }

    final isAlreadyUploadedToBucket = filepathOrUrl.contains(bucket);
    final isUrl = PathUtils.isUrl(filepathOrUrl);

    if (!isAlreadyUploadedToBucket && !isUrl) {
      final mimeType = lookupMimeType(filepathOrUrl) ?? "/";
      final fileType = mimeType.split('/')[1];

      bool isAllowed = restrictMimeTypesTo?.contains(mimeType.toLowerCase()) ?? restrictFileTypesTo?.contains(fileType.toLowerCase()) ?? true;

      if (isAllowed) {
        try {
          final snapshot = await storage.ref().child("$name/${basename(filepathOrUrl)}").putFile(File(filepathOrUrl));

          //return value that is the download url without an exception to indicate all is well and the path can be used
          returnValue.value = await snapshot.ref.getDownloadURL();

        } on FirebaseException catch (e) {
          //return value that is the input path and an exception happened when uploading to Firebase
          returnValue.exception = e;
        }
      } else {
        //return value that is the input path with an exception indicating the type of file is not allowed
        returnValue.exception = createFirebaseMimeTypeException();
      }
    } else {
      //return value that is the input path without an exception since the file is already uploaded online
    }

    return returnValue;
  }

  @override
  Future<Map<String, FirebaseValueExceptionPair<String>>> uploadFiles(List<String> filepathsOrUrls) async {
    final returnValue = Map.fromEntries(filepathsOrUrls.map((filepathOrUrl) => MapEntry(filepathOrUrl, FirebaseValueExceptionPair(filepathOrUrl, exception: storageInitializationException))));

    final storage = this.storage;
    if (filepathsOrUrls.isEmpty || storage == null) return returnValue;

    for (var filepathOrUrl in filepathsOrUrls) {
      returnValue[filepathOrUrl] = await uploadFile(filepathOrUrl);
    }

    return returnValue;
  }
  //endregion

  //region Download
  @override
  Future<FirebaseValueExceptionPair<String>> downloadFile(String url) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, FirebaseValueExceptionPair<String>>> downloadFiles(List<String> urls) async {
    throw UnimplementedError();
  }
  //endregion

  //region Delete
  @override
  Future<FirebaseValueExceptionPair<bool>> deleteFile(String? url, {bool useNameInsteadOfRefFromUrl = false}) async {
    final returnValue = FirebaseValueExceptionPair(false);
    final storage = this.storage;

    if (url == null || url.isEmpty || storage == null) return returnValue;

    try {
      if (useNameInsteadOfRefFromUrl) {
        await storage.ref().child("$name/${basename(url)}").delete();
      } else {
        await storage.refFromURL(url).delete();
      }
      returnValue.value = true;
    } on FirebaseException catch(e) {
      returnValue.exception = e;
    }

    return returnValue;
  }

  @override
  Future<Map<String, FirebaseValueExceptionPair<bool>>> deleteFiles(List<String> urls, {bool useFolderName = false}) async {
    final returnValue = Map.fromEntries(urls.map((url) => MapEntry(url, FirebaseValueExceptionPair(false, exception: storageInitializationException))));

    final storage = this.storage;
    if (urls.isEmpty || storage == null) return returnValue;

    for (var url in urls) {
      returnValue[url] = await deleteFile(url, useNameInsteadOfRefFromUrl: useFolderName);
    }

    return returnValue;
  }
  //endregion
}