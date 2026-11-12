import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../services/firebase_observations_service.dart';

// One cache on the phone's disk for observation photos and recordings from Firebase Storage, so
// each file is downloaded once and then played or shown from the phone. Storage files never
// change once uploaded (a new upload gets a new name), so they can be kept for a long time.
class MediaCache {

  static final CacheManager manager = CacheManager(Config(
    "pikaPatrolMedia",
    stalePeriod: const Duration(days: 365),
    maxNrOfCacheObjects: 1000,
  ));

  // Cached by Storage path, not URL: the same file can get a new URL (a refreshed access token),
  // and that shouldn't download it again
  static String keyFor(String url) => FirebaseObservationsService.storagePathFromUrl(url) ?? url;

  static Future<File> file(String url) => manager.getSingleFile(url, key: keyFor(url));
}
