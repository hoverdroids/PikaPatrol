import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/model/storage_file.dart';
import 'package:pika_patrol/services/firebase_observations_service.dart';
import 'package:pika_patrol/services/storage_file_correlator.dart';

const bucket = FirebaseObservationsService.STORAGE_BUCKET_NAME;

String url(String path, {String token = 'current'}) =>
    'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(path)}?alt=media&token=$token';

StorageFile file(String path, {DateTime? created}) =>
    StorageFile(path: path, isImage: path.startsWith('images/'), sizeBytes: 1000, created: created);

StorageFileCorrelator correlator(List<Observation> observations, List<StorageFile> files) {
  final usedPaths = {
    for (var o in observations)
      for (var u in [...?o.imageUrls, ...?o.audioUrls])
        if (FirebaseObservationsService.storagePathFromUrl(u) case final p?) p
  };
  return StorageFileCorrelator(
    observations: observations,
    filesByPath: {for (var f in files) f.path: f},
    currentUrlsByPath: {for (var f in files) if (usedPaths.contains(f.path)) f.path: url(f.path)},
    storagePathFromUrl: FirebaseObservationsService.storagePathFromUrl,
  );
}

void main() {
  final saved = DateTime(2024, 6, 1, 12, 0);

  test('reads the Storage path from a download URL', () {
    expect(FirebaseObservationsService.storagePathFromUrl(url('images/a b.jpg')), 'images/a b.jpg');
    expect(FirebaseObservationsService.storagePathFromUrl('/data/user/0/cache/a.jpg'), isNull);
  });

  test('a link whose token changed is refreshed, and the file is not unused', () {
    final o = Observation(uid: 'o1', imageUrls: [url('images/a.jpg', token: 'old')]);
    final result = correlator([o], [file('images/a.jpg')]).correlate();
    expect(result.fixes.single.reason, FileFixReason.refreshLink);
    expect(result.fixes.single.confidence, FileFixConfidence.high);
    expect(result.unmatched, isEmpty);
  });

  test('a working link needs no fix', () {
    final o = Observation(uid: 'o1', imageUrls: [url('images/a.jpg')]);
    final result = correlator([o], [file('images/a.jpg')]).correlate();
    expect(result.fixes, isEmpty);
    expect(result.unmatched, isEmpty);
  });

  test('a phone path is matched to the uploaded file with the same name', () {
    final o = Observation(uid: 'o1', imageUrls: ['/data/user/0/cache/image_picker_ABC.jpg']);
    final other = Observation(uid: 'o2', imageUrls: ['/data/user/0/cache/image_picker_XYZ.jpg'], dateUpdatedInGoogleSheets: saved);
    final result = correlator([o, other], [file('images/image_picker_ABC.jpg', created: saved)]).correlate();
    final fix = result.fixes.single;
    expect(fix.observation, o);
    expect(fix.reason, FileFixReason.sameName);
    expect(fix.brokenUrl, '/data/user/0/cache/image_picker_ABC.jpg');
  });

  test('time matching picks the closest observation and only fills its broken slots', () {
    final near = Observation(uid: 'near', imageUrls: [url('images/gone.jpg')], dateUpdatedInGoogleSheets: saved);
    final far = Observation(uid: 'far', imageUrls: [url('images/gone2.jpg')], dateUpdatedInGoogleSheets: saved.add(const Duration(hours: 5)));
    final files = [
      file('images/x.jpg', created: saved.add(const Duration(minutes: 2))),
      file('images/y.jpg', created: saved.add(const Duration(minutes: 3))),
    ];
    final result = correlator([near, far], files).correlate();
    final nearFix = result.fixes.firstWhere((f) => f.observation == near);
    expect(nearFix.file.path, 'images/x.jpg');
    expect(nearFix.confidence, FileFixConfidence.likely);
    final farFix = result.fixes.firstWhere((f) => f.observation == far);
    expect(farFix.file.path, 'images/y.jpg');
    expect(farFix.confidence, FileFixConfidence.possible);
  });

  test('files far from any broken observation stay unmatched', () {
    final o = Observation(uid: 'o1', imageUrls: [url('images/gone.jpg')], dateUpdatedInGoogleSheets: saved);
    final result = correlator([o], [file('images/x.jpg', created: saved.add(const Duration(days: 3)))]).correlate();
    expect(result.fixes, isEmpty);
    expect(result.unmatched.single.path, 'images/x.jpg');
  });

  test('observations with only working links never get extra files', () {
    final o = Observation(uid: 'o1', imageUrls: [url('images/a.jpg')], dateUpdatedInGoogleSheets: saved);
    final result = correlator([o], [file('images/a.jpg'), file('images/x.jpg', created: saved)]).correlate();
    expect(result.fixes, isEmpty);
    expect(result.unmatched.single.path, 'images/x.jpg');
  });

  test('photos never match recording slots', () {
    final o = Observation(uid: 'o1', audioUrls: [url('audio/gone.m4a')], dateUpdatedInGoogleSheets: saved);
    final result = correlator([o], [file('images/x.jpg', created: saved)]).correlate();
    expect(result.fixes, isEmpty);
  });

  test('fixes replace broken entries in place so the cover stays first', () {
    final broken = '/data/user/0/cache/cover.jpg';
    final o = Observation(uid: 'o1', imageUrls: [broken, url('images/b.jpg')]);
    final fix = FileFix(observation: o, file: file('images/cover.jpg'), isImage: true, brokenUrl: broken,
        reason: FileFixReason.sameName, confidence: FileFixConfidence.high);
    final lists = StorageFileCorrelator.applyFixes(o, [fix], {'images/cover.jpg': url('images/cover.jpg')});
    expect(lists.imageUrls, [url('images/cover.jpg'), url('images/b.jpg')]);
  });

  test('the random upload prefix is ignored when comparing names', () {
    expect(StorageFileCorrelator.baseName('images/AbCdEfGhIjKlMnOpQrSt_photo.jpg'), 'photo.jpg');
    expect(StorageFileCorrelator.baseName(url('images/photo.jpg')), 'photo.jpg');
  });
}
