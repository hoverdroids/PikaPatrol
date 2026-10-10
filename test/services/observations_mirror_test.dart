import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/services/observations_mirror.dart';

ObservationChanges changes({List<(String, DateTime?, String)> changed = const [], List<(String, DateTime?)> deleted = const []}) {
  final result = ObservationChanges();
  for (final (uid, at, location) in changed) {
    result.changed.add((observation: Observation(uid: uid, location: location), at: at));
  }
  for (final (uid, at) in deleted) {
    result.deleted.add((uid: uid, at: at));
  }
  return result;
}

void main() {
  final t0 = DateTime.utc(2026, 10, 10, 12);
  DateTime at(int minutes) => t0.add(Duration(minutes: minutes));

  group('ObservationsMirror', () {
    late DateTime clock;
    late List<DateTime?> fetchedSince;
    late List<ObservationChanges> responses;
    Map<String, dynamic>? saved;

    ObservationsMirror mirror() => ObservationsMirror(
      fetchChanges: (since) async {
        fetchedSince.add(since);
        return responses.removeAt(0);
      },
      loadJson: () async => saved,
      saveJson: (json) async => saved = json,
      now: () => clock,
    );

    setUp(() {
      clock = at(0);
      fetchedSince = [];
      responses = [];
      saved = null;
    });

    test('the first sync reads everything, later syncs start from the newest change seen', () async {
      final m = mirror();
      responses = [
        changes(changed: [('a', at(-30), 'A'), ('b', at(-10), 'B')]),
        changes(changed: [('c', at(20), 'C')]),
      ];
      expect(await m.sync(), isTrue);
      expect(fetchedSince, [null]);
      expect(m.observations.map((o) => o.uid), unorderedEquals(['a', 'b']));

      clock = at(30);
      await m.sync();
      expect(fetchedSince.last, at(-10));
      expect(m.observations.map((o) => o.uid), unorderedEquals(['a', 'b', 'c']));
    });

    test('syncs at most every 15 minutes unless forced', () async {
      final m = mirror();
      responses = [changes(), changes()];
      await m.sync();
      clock = at(5);
      await m.sync();
      expect(fetchedSince.length, 1);
      await m.sync(force: true);
      expect(fetchedSince.length, 2);
    });

    test('deletes remove observations, unless the observation changed after the delete', () {
      final m = mirror();
      m.apply(changes(changed: [('a', at(0), 'A'), ('b', at(0), 'B')]), full: true, syncStartedAt: at(1));
      m.apply(changes(deleted: [('a', at(5))]), full: false, syncStartedAt: at(6));
      expect(m.observations.map((o) => o.uid), ['b']);

      // Saved again after it was deleted: keep it
      m.apply(changes(changed: [('b', at(10), 'B2')], deleted: [('b', at(8))]), full: false, syncStartedAt: at(11));
      expect(m.observations.single.location, 'B2');
    });

    test('an older change never replaces a newer one', () {
      final m = mirror();
      m.apply(changes(changed: [('a', at(10), 'new')]), full: true, syncStartedAt: at(11));
      m.apply(changes(changed: [('a', at(5), 'old')]), full: false, syncStartedAt: at(12));
      expect(m.observations.single.location, 'new');
    });

    test('without server times, the next sync starts a little before the last one', () async {
      final m = mirror();
      responses = [changes(changed: [('a', null, 'A')])];
      await m.sync();
      clock = at(20);
      responses = [changes()];
      await m.sync();
      expect(fetchedSince.last, at(0).subtract(ObservationsMirror.clockMargin));
    });

    test('the saved copy is used on the next start, with no read until it is due', () async {
      responses = [changes(changed: [('a', at(-1), 'A')])];
      await mirror().sync();

      final restarted = mirror();
      clock = at(5);
      expect(await restarted.sync(), isTrue);
      expect(fetchedSince.length, 1);
      expect(restarted.observations.single.location, 'A');
    });

    test('a failed sync keeps the copy and tries again next time', () async {
      var fail = true;
      final m = ObservationsMirror(
        fetchChanges: (since) async {
          if (fail) throw Exception('offline');
          return changes(changed: [('a', at(0), 'A')]);
        },
        loadJson: () async => null,
        saveJson: (_) async {},
        now: () => clock,
      );
      expect(await m.sync(), isFalse);
      expect(m.hasSynced, isFalse);
      fail = false;
      expect(await m.sync(), isTrue);
    });

    test('saves and deletes on this device show at once', () async {
      final m = mirror();
      responses = [changes(changed: [('a', at(0), 'A')])];
      await m.sync();
      m.put(Observation(uid: 'b', location: 'B'));
      m.remove('a');
      expect(m.observations.map((o) => o.uid), ['b']);
    });
  });
}
