import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/model/storage_file.dart';
import 'package:pika_patrol/model/storage_scan.dart';
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

  test('a link whose token changed is refreshed at 100%, and the file is not unused', () {
    final o = Observation(uid: 'o1', imageUrls: [url('images/a.jpg', token: 'old')]);
    final result = correlator([o], [file('images/a.jpg')]).correlate();
    expect(result.fixes.single.match.signals.single.kind, MatchSignalKind.linkExpired);
    expect(result.fixes.single.certainty, 1);
    expect(result.unmatched, isEmpty);
  });

  test('a working link needs no fix', () {
    final o = Observation(uid: 'o1', imageUrls: [url('images/a.jpg')]);
    final result = correlator([o], [file('images/a.jpg')]).correlate();
    expect(result.fixes, isEmpty);
    expect(result.unmatched, isEmpty);
  });

  test('a phone path is matched at 100% to the uploaded file with the same name', () {
    final o = Observation(uid: 'o1', imageUrls: ['/data/user/0/cache/image_picker_ABC.jpg']);
    final other = Observation(uid: 'o2', imageUrls: ['/data/user/0/cache/image_picker_XYZ.jpg'], dateUpdatedInGoogleSheets: saved);
    final result = correlator([o, other], [file('images/image_picker_ABC.jpg', created: saved)]).correlate();
    final fix = result.fixes.single;
    expect(fix.observation, o);
    expect(fix.certainty, 1);
    expect(fix.match.brokenUrl, '/data/user/0/cache/image_picker_ABC.jpg');
  });

  test('a file uploaded seconds after a file the observation has scores very high', () {
    final o = Observation(uid: 'o1', imageUrls: [url('images/kept.jpg')], date: saved.subtract(const Duration(days: 30)));
    final files = [
      file('images/kept.jpg', created: saved),
      file('images/lost.jpg', created: saved.add(const Duration(seconds: 3))),
    ];
    final fix = correlator([o], files).correlate().fixes.single;
    expect(fix.observation, o);
    expect(fix.certainty, greaterThan(0.9));
    expect(fix.match.signals.first.kind, MatchSignalKind.uploadedWithLinkedFile);
  });

  test('a cropped photo is matched by the time in its name', () {
    final started = DateTime(2024, 6, 1, 9, 0);
    final o = Observation(uid: 'o1', date: started);
    final name = 'images/image_cropper_${started.add(const Duration(minutes: 4)).millisecondsSinceEpoch}.jpg';
    final fix = correlator([o], [file(name, created: started.add(const Duration(days: 20)))]).correlate().fixes.single;
    expect(fix.match.signals.any((s) => s.kind == MatchSignalKind.madeNearObservationStart), isTrue);
    expect(fix.certainty, greaterThan(0.8));
  });

  test('two equally good observations make the match uncertain, with the other as a choice', () {
    final a = Observation(uid: 'a', dateUpdatedInGoogleSheets: saved);
    final b = Observation(uid: 'b', dateUpdatedInGoogleSheets: saved);
    final fix = correlator([a, b], [file('images/x.jpg', created: saved)]).correlate().fixes.single;
    expect(fix.certainty, lessThan(0.5));
    expect(fix.candidates.length, 2);
    expect(fix.match.signals.any((s) => s.kind == MatchSignalKind.closeRunnerUp), isTrue);
  });

  test('a broken link of the same kind raises the score', () {
    final broken = Observation(uid: 'broken', imageUrls: [url('images/gone.jpg')], dateUpdatedInGoogleSheets: saved);
    final plain = Observation(uid: 'plain', dateUpdatedInGoogleSheets: saved.add(const Duration(days: 300)));
    final fix = correlator([broken, plain], [file('images/x.jpg', created: saved.add(const Duration(hours: 1)))]).correlate().fixes.single;
    expect(fix.observation, broken);
    expect(fix.match.signals.any((s) => s.kind == MatchSignalKind.observationHasBrokenLink), isTrue);
  });

  test('files far from every observation are unused', () {
    final o = Observation(uid: 'o1', dateUpdatedInGoogleSheets: saved, date: saved);
    final result = correlator([o], [file('images/x.jpg', created: saved.subtract(const Duration(days: 60)))]).correlate();
    expect(result.unmatched.single.path, 'images/x.jpg');
  });

  test('fixes replace broken entries in place so the cover stays first', () {
    const broken = '/data/user/0/cache/cover.jpg';
    final o = Observation(uid: 'o1', imageUrls: [broken, url('images/b.jpg')]);
    final fix = FileFix(file('images/cover.jpg'), [FileMatch(observation: o, certainty: 1, signals: const [], brokenUrl: broken)]);
    final lists = StorageFileCorrelator.applyFixes(o, [fix], {'images/cover.jpg': url('images/cover.jpg')}, (u) => !u.startsWith('https'), FirebaseObservationsService.storagePathFromUrl);
    expect(lists.imageUrls, [url('images/cover.jpg'), url('images/b.jpg')]);
  });

  test('a time match fills the next broken entry, or goes at the end', () {
    const broken = '/phone/a.jpg';
    final o = Observation(uid: 'o1', imageUrls: [url('images/ok.jpg'), broken]);
    final first = FileFix(file('images/x.jpg'), [FileMatch(observation: o, certainty: 0.7, signals: const [])]);
    final second = FileFix(file('images/y.jpg'), [FileMatch(observation: o, certainty: 0.6, signals: const [])]);
    final lists = StorageFileCorrelator.applyFixes(o, [first, second],
        {'images/x.jpg': url('images/x.jpg'), 'images/y.jpg': url('images/y.jpg')}, (u) => !u.startsWith('https'), FirebaseObservationsService.storagePathFromUrl);
    expect(lists.imageUrls, [url('images/ok.jpg'), url('images/x.jpg'), url('images/y.jpg')]);
  });

  test('the random upload prefix is ignored when comparing names', () {
    expect(StorageFileCorrelator.baseName('images/AbCdEfGhIjKlMnOpQrSt_photo.jpg'), 'photo.jpg');
    expect(StorageFileCorrelator.baseName(url('images/photo.jpg')), 'photo.jpg');
  });

  test('a fix is skipped when the observation already links that file', () {
    final o = Observation(uid: 'o1', imageUrls: [url('images/x.jpg')]);
    final fix = FileFix(file('images/x.jpg'), [FileMatch(observation: o, certainty: 0.7, signals: const [])]);
    final lists = StorageFileCorrelator.applyFixes(o, [fix], {'images/x.jpg': url('images/x.jpg', token: 'new')},
        (u) => !u.startsWith('https'), FirebaseObservationsService.storagePathFromUrl);
    expect(lists.imageUrls, [url('images/x.jpg')]);
  });

  test('a saved scan reads back the same, sharing one observation between fixes', () {
    final o = Observation(uid: 'o1', name: 'Pika Peak', date: saved, imageUrls: [url('images/gone.jpg')], dateUpdatedInGoogleSheets: saved);
    final files = [
      file('images/x.jpg', created: saved.add(const Duration(minutes: 1))),
      file('images/y.jpg', created: saved.add(const Duration(minutes: 2))),
      file('images/old.jpg', created: saved.subtract(const Duration(days: 90))),
    ];
    final result = correlator([o], files).correlate();
    final scan = StorageScan(fixes: result.fixes, unused: result.unmatched, observationCount: 1, totalFileCount: 3,
        missingPaths: {'images/gone.jpg'}, scannedAt: saved);

    final copy = StorageScan.fromJson(jsonDecode(jsonEncode(scan.toJson())) as Map<String, dynamic>)!;
    expect(copy.fixes.length, scan.fixes.length);
    expect(copy.fixes.map((f) => f.file.path), scan.fixes.map((f) => f.file.path));
    expect(copy.fixes.map((f) => f.certainty), scan.fixes.map((f) => f.certainty));
    expect(copy.fixes.first.match.signals.map((s) => s.kind), scan.fixes.first.match.signals.map((s) => s.kind));
    expect(identical(copy.fixes[0].observation, copy.fixes[1].observation), isTrue);
    expect(copy.fixes.first.observation.name, 'Pika Peak');
    expect(copy.fixes.first.observation.date, saved);
    expect(copy.unused.single.path, 'images/old.jpg');
    expect(copy.isBroken(url('images/gone.jpg')), isTrue);
    expect(copy.isBroken(url('images/new-since-scan.jpg')), isFalse);
  });
}
