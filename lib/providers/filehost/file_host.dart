import '../../model/value_exception_pair.dart';

abstract interface class FileHost<T,E> {

  Future<ValueExceptionPair<T, E>> uploadFile(String localFilepath);
  Future<Map<String, ValueExceptionPair<T, E>>> uploadFiles(List<String> localFilepaths);

  Future<ValueExceptionPair<T, E>> downloadFile(String url);
  Future<Map<String, ValueExceptionPair<T, E>>> downloadFiles(List<String> urls);

  Future<ValueExceptionPair<T,E>> deleteFile(String url);
  Future<Map<String, ValueExceptionPair>> deleteFiles(List<String> urls);
}