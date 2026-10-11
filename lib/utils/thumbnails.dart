import 'package:path/path.dart' as p;

import '../services/firebase_observations_service.dart';

// Small copies of observation photos, made by Firebase's "Resize Images" extension. It is set to
// write images/thumbs/<name>_400x400.<ext> next to each upload (see docs/firebase-runbook.md), so
// the gallery can download a few kilobytes per photo instead of the whole photo.
const String thumbnailFolder = "thumbs";
const String thumbnailSize = "400x400";

// The thumbnail's public URL for a photo's download URL, or null if the photo isn't in Storage.
// Storage rules allow public reads, so the URL needs no access token.
String? thumbnailUrl(String url) {
  final path = FirebaseObservationsService.storagePathFromUrl(url);
  final uri = Uri.tryParse(url);
  if (path == null || uri == null) return null;
  final directory = p.posix.dirname(path);
  final name = "${p.posix.basenameWithoutExtension(path)}_$thumbnailSize${p.posix.extension(path)}";
  final thumbnailPath = p.posix.join(directory, thumbnailFolder, name);
  final index = uri.pathSegments.indexOf("o");
  return uri.replace(
    pathSegments: [...uri.pathSegments.take(index + 1), thumbnailPath],
    queryParameters: {"alt": "media"},
  ).toString();
}
