import '../../model/value_exception_pair.dart';

abstract interface class FileHost<E> {

  late String name;

  Set<String>? restrictMimeTypesTo;
  Set<String>? restrictFileTypesTo;

  // Returns a ValueExceptionPair with a result value path based on:
  // If restrictedMimeTypesTo is provided and the file's mime type is not included, result path will be the input path.
  // If restrictedFileTypesTo is provided and the file's file type is not included, result path will be the input path.
  // If an exception is thrown, result path will be the input path.
  // If the path is an Url, result path will be the input path.
  // Otherwise, the result path will be the upload path returned by the local or remote file host interacting with this wrapper.
  Future<ValueExceptionPair<String, E>> uploadFile(String pathOrUrl);

  // Returns a mapping of the original path to ValueExceptionPair with a result path based on results described in uploadFile
  Future<Map<String, ValueExceptionPair<String, E>>> uploadFiles(List<String> pathsOrUrls);

  // Returns ValueExceptionPair where result the download path if file was successfully downloaded, or the original path if
  // there was a problem downloading.
  // If an exception was thrown, it will be returned along with one of the results listed above
  Future<ValueExceptionPair<String, E>> downloadFile(String pathOrUrl);

  // Returns a mapping of the original path to ValueExceptionPair where result the download path if file was successfully downloaded, or the original path if
  // there was a problem downloading.
  // If an exception was thrown, it will be returned along with one of the results listed above
  Future<Map<String, ValueExceptionPair<String, E>>> downloadFiles(List<String> pathsOrUrls);

  // Returns ValueExceptionPair where result value is true if file was deleted, or false if the file was not deleted.
  // If an exception was thrown, it will be returned along with one of the results listed above
  Future<ValueExceptionPair<bool, E>> deleteFile(String pathOrUrl);

  // Returns a mapping of the original path to ValueExceptionPair where result value is true if file was deleted,
  // or false if the file was not deleted.
  // If an exception was thrown, it will be returned along with one of the results listed above
  Future<Map<String, ValueExceptionPair<bool, E>>> deleteFiles(List<String> pathsOrUrls);
}