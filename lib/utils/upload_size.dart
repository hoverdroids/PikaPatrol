import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// The largest file Firebase Storage accepts from the app. Must match firebase/storage.rules.
const int maxUploadBytes = 50 * 1024 * 1024;

int fileSizeBytes(String path) {
  try {
    return File(path).lengthSync();
  } on FileSystemException {
    return 0;
  }
}

bool isTooLargeToUpload(String path) => fileSizeBytes(path) >= maxUploadBytes;

// "62.4" for a 62.4 MB file
String sizeInMegabytes(String path) => (fileSizeBytes(path) / (1024 * 1024)).toStringAsFixed(1);

// A smaller JPEG copy of a photo that fits under the upload limit, trying gentler settings first.
// Null if it can't be made small enough (or isn't an image the phone can read).
Future<String?> shrinkImageToFit(String path, {int maxBytes = maxUploadBytes}) async {
  const attempts = [(2560, 85), (2048, 80), (1600, 75), (1280, 70)];
  // Not the temporary folder: the phone can clear that before an offline observation uploads
  final folder = (await getApplicationDocumentsDirectory()).path;
  for (final (dimension, quality) in attempts) {
    final target = join(folder, "${basenameWithoutExtension(path)}_$dimension.jpg");
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      target,
      minWidth: dimension,
      minHeight: dimension,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    if (result == null) return null;
    if (await result.length() < maxBytes) return result.path;
  }
  return null;
}
