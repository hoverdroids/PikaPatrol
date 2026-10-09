import 'package:firebase_storage/firebase_storage.dart';

// A photo or recording in Firebase Storage, as listed for the admin unused-files cleanup
class StorageFile {
  final Reference ref;
  final bool isImage;
  final int sizeBytes;
  final DateTime? created;

  const StorageFile({required this.ref, required this.isImage, required this.sizeBytes, this.created});
}
