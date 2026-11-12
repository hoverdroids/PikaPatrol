import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/services/google_sheets_service.dart';

void main() {
  test('Collared pikas go to the Collared pika sheet in every language', () {
    for (var name in ['Collared Pika', 'Pika con Cuello', 'Pika à collier']) {
      final projects = GoogleSheetsService.projectsFor(Observation(species: name, sharedWithProjects: ['Utah Pika Watch']));
      expect(projects, {'Utah Pika Watch', GoogleSheetsService.MASTER_PROJECT, GoogleSheetsService.COLLARED_PIKA_PROJECT}, reason: name);
    }
  });

  test('other species only go to the master sheet and the projects they were shared with', () {
    expect(GoogleSheetsService.projectsFor(Observation(species: 'American Pika')), {GoogleSheetsService.MASTER_PROJECT});
  });
}
