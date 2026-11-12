import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/services/duplicate_observation_finder.dart';
import 'package:pika_patrol/services/firebase_observations_service.dart';

const bucket = FirebaseObservationsService.STORAGE_BUCKET_NAME;

String url(String path, {String token = 't'}) =>
    'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media&token=$token';

void main() {
  final started = DateTime(2025, 7, 20, 9, 30);

  Observation obs(String uid, {String observer = 'u1', DateTime? date, String location = 'Pika Peak',
      double? lat, double? lon, List<String>? images, DateTime? saved, List<String>? projects}) =>
      Observation(uid: uid, observerUid: observer, date: date ?? started, location: location,
          latitude: lat, longitude: lon, imageUrls: images, dateUpdatedInGoogleSheets: saved, sharedWithProjects: projects);

  test('copies of one observation form a group', () {
    final groups = DuplicateObservationFinder.find([
      obs('a'),
      obs('b', date: started.add(const Duration(seconds: 5))),
      obs('c', date: started.add(const Duration(hours: 2))),
    ]);
    expect(groups.single.observations.map((o) => o.uid), ['a', 'b']);
  });

  test('different people, places or times are never grouped', () {
    final groups = DuplicateObservationFinder.find([
      obs('a'),
      obs('b', observer: 'u2'),
      obs('c', location: 'Other Talus'),
      obs('d', date: started.add(const Duration(minutes: 5))),
    ]);
    expect(groups, isEmpty);
  });

  test('a renamed copy still matches by coordinates', () {
    final groups = DuplicateObservationFinder.find([
      obs('a', lat: 39.12345, lon: -105.54321),
      obs('b', location: 'Pika Peak (edited)', lat: 39.12346, lon: -105.54322),
    ]);
    expect(groups.single.observations.length, 2);
  });

  test('the copy with the most photos is kept by default', () {
    final groups = DuplicateObservationFinder.find([
      obs('a', images: [url('images/1.jpg')]),
      obs('b', images: [url('images/1.jpg'), url('images/2.jpg')]),
    ]);
    expect(groups.single.keep.uid, 'b');
  });

  test('merging keeps the cover first and adds each file once', () {
    final keep = obs('a', images: [url('images/cover.jpg'), url('images/2.jpg')], projects: ['Utah Pika Watch']);
    final other = obs('b', images: [url('images/2.jpg', token: 'other'), url('images/3.jpg')], projects: ['Canadian Pika Project']);
    final merged = DuplicateObservationFinder.merge(keep, [other], FirebaseObservationsService.storagePathFromUrl);
    expect(merged.imageUrls, [url('images/cover.jpg'), url('images/2.jpg'), url('images/3.jpg')]);
    expect(merged.sharedWithProjects.toSet(), {'Utah Pika Watch', 'Canadian Pika Project'});
  });
}
