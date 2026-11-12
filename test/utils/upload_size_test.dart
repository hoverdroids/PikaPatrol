import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/utils/upload_size.dart';

void main() {
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('upload_size'));
  tearDown(() => folder.deleteSync(recursive: true));

  String fileOf(int bytes) {
    final file = File('${folder.path}/f$bytes')..writeAsBytesSync(List.filled(bytes, 0));
    return file.path;
  }

  test('the limit matches the 50 MB in storage.rules', () {
    expect(maxUploadBytes, 50 * 1024 * 1024);
    expect(File('firebase/storage.rules').readAsStringSync(), contains('request.resource.size < 50 * 1024 * 1024'));
  });

  test('files at or over the limit are too large', () {
    final small = fileOf(1024);
    expect(isTooLargeToUpload(small), isFalse);
    final file = File('${folder.path}/big');
    file.openSync(mode: FileMode.write)
      ..setPositionSync(maxUploadBytes - 1)
      ..writeByteSync(0)
      ..closeSync();
    expect(isTooLargeToUpload(file.path), isTrue);
    expect(sizeInMegabytes(file.path), '50.0');
  });

  test('a missing file counts as empty', () {
    expect(isTooLargeToUpload('${folder.path}/missing'), isFalse);
  });
}
