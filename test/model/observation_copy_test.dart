import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/model/observation.dart';

void main() {
  test('editing a copy leaves the original lists alone', () {
    final original = Observation(
      uid: 'a',
      signs: ['scat'],
      imageUrls: ['photo1', 'photo2'],
      audioUrls: ['call1'],
      otherAnimalsPresent: ['marmot'],
      sharedWithProjects: ['RMW'],
      notSharedWithProjects: ['other'],
    );

    final copy = original.copy()
      ..signs!.add('haypile')
      ..imageUrls!.remove('photo1')
      ..audioUrls!.remove('call1')
      ..notSharedWithProjects!.clear();
    copy.otherAnimalsPresent!.add('weasel');
    copy.sharedWithProjects!.add('CPW');

    expect(original.signs, ['scat']);
    expect(original.imageUrls, ['photo1', 'photo2']);
    expect(original.audioUrls, ['call1']);
    expect(original.otherAnimalsPresent, ['marmot']);
    expect(original.sharedWithProjects, ['RMW']);
    expect(original.notSharedWithProjects, ['other']);
  });
}
