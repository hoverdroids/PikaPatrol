import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/model/observation_stats.dart';
import 'package:pika_patrol/services/observations_service.dart';

void main() {
  Observation obs(String uid, {String observer = 'u1', DateTime? date, String location = '', double? lat, double? lon,
      String pikas = '', List<String>? signs, String species = Observation.SPECIES_DEFAULT, double? altitude, List<String>? projects}) =>
      Observation(uid: uid, observerUid: observer, date: date, location: location, latitude: lat, longitude: lon,
          pikasDetected: pikas, signs: signs, species: species, altitudeInMeters: altitude, sharedWithProjects: projects);

  test('counts observations, sites, observers and pika finds', () {
    final stats = ObservationStats.from([
      obs('a', location: 'Pika Peak', pikas: '2'),
      obs('b', location: ' pika peak ', pikas: '0', observer: 'u2'),
      obs('c', lat: 40.12341, lon: -105.12341, pikas: ''),
      obs('d', lat: 40.12349, lon: -105.12349, pikas: '>5', observer: 'u3'),
      obs('e'),
    ]);

    expect(stats.total, 5);
    expect(stats.sites, 2, reason: 'names match ignoring case and spaces; nearby unnamed points are one site; no place is no site');
    expect(stats.observers, 3);
    expect(stats.withPikas, 2);
  });

  test('months run oldest first with empty months filled in', () {
    final stats = ObservationStats.from([
      obs('a', date: DateTime(2026, 3, 30)),
      obs('b', date: DateTime(2025, 12, 1)),
      obs('c', date: DateTime(2026, 3, 2)),
    ]);

    expect(stats.perMonth.map((e) => '${e.key.year}-${e.key.month}:${e.value}'),
        ['2025-12:1', '2026-1:0', '2026-2:0', '2026-3:2']);
  });

  test('a sign or project listed twice on one observation counts once', () {
    final stats = ObservationStats.from([
      obs('a', signs: ['Saw Pika', 'Saw Pika', 'Heard Pika Calls'], projects: ['RMW', 'RMW']),
      obs('b', signs: ['Saw Pika'], species: 'Collared Pika', altitude: 3200),
    ]);

    expect(stats.signs, {'Saw Pika': 2, 'Heard Pika Calls': 1});
    expect(stats.projects, {'RMW': 1});
    expect(stats.species, {Observation.SPECIES_DEFAULT: 1, 'Collared Pika': 1});
    expect(stats.elevationsInMeters, [3200]);
  });

  test('the map and dashboard list each observation once, preferring the device copy', () {
    final own = [obs('a', location: 'edited on this phone'), obs('', location: 'not uploaded yet')];
    final shared = [obs('a', location: 'server copy'), obs('b'), obs('', location: 'someone else, no id')];

    expect(ObservationsService.mergeVisibleObservations(own, shared, includeShared: false).map((o) => o.location),
        ['edited on this phone', 'not uploaded yet']);
    expect(ObservationsService.mergeVisibleObservations(own, shared, includeShared: true).map((o) => o.location),
        ['edited on this phone', 'not uploaded yet', '', 'someone else, no id']);
  });
}
