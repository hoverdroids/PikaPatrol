import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/services/firebase_observations_service.dart';
import 'package:pika_patrol/utils/thumbnails.dart';

void main() {
  test('A photo URL maps to its thumbnail in the thumbs folder', () {
    const url = "https://firebasestorage.googleapis.com/v0/b/${FirebaseObservationsService.STORAGE_BUCKET_NAME}/o/images%2Fabc_photo.jpg?alt=media&token=123";
    expect(
      thumbnailUrl(url),
      "https://firebasestorage.googleapis.com/v0/b/${FirebaseObservationsService.STORAGE_BUCKET_NAME}/o/images%2Fthumbs%2Fabc_photo_400x400.jpg?alt=media",
    );
  });

  test('Files that are not in Storage have no thumbnail', () {
    expect(thumbnailUrl("/data/user/0/photo.jpg"), isNull);
    expect(thumbnailUrl("https://example.com/photo.jpg"), isNull);
  });
}
