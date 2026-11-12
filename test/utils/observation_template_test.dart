import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/services/firebase_observations_service.dart';
import 'package:pika_patrol/utils/observation_utils.dart';

void main() {
  test('the default template keeps the Indigenous territories with its coordinates', () {
    final template = Observation(latitude: 40.1, longitude: -105.2)
      ..indigenousTerritories = ['Ute|https://native-land.ca/maps/territories/ute']
      ..indigenousLanguages = ['Arapaho|'];

    final observation = observationFromTemplateJson(template.toTemplateJson());

    expect(observation.latitude, 40.1);
    expect(observation.indigenousTerritories, template.indigenousTerritories);
    expect(observation.indigenousLanguages, template.indigenousLanguages);
  });

  test('an uploaded file shows the name it was given', () {
    const bucket = FirebaseObservationsService.STORAGE_BUCKET_NAME;
    final url = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
        '${Uri.encodeComponent('audio/AbCdEfGhIjKlMnOpQrSt_Talus call.m4a')}?alt=media&token=t';

    expect(FirebaseObservationsService.fileDisplayName(url), 'Talus call');
    expect(FirebaseObservationsService.fileDisplayName('/data/user/0/app/files/Talus call.m4a'), 'Talus call');
  });
}
