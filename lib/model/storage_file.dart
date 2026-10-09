// A photo or recording in Firebase Storage, as listed for the admin file tools
class StorageFile {
  // For example "images/image_picker_1234.jpg"
  final String path;
  final bool isImage;
  final int sizeBytes;
  final DateTime? created;

  const StorageFile({required this.path, required this.isImage, required this.sizeBytes, this.created});

  String get name => path.split('/').last;
}

String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  if (bytes >= 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  return "${(bytes / 1024).toStringAsFixed(0)} KB";
}
