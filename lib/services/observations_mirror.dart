import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../model/observation.dart';
import 'firebase_observations_service.dart';

typedef ObservationChange = ({Observation observation, DateTime? at});
typedef ObservationDelete = ({String uid, DateTime? at});

// What changed on the server since a time: observations added or edited, and ones deleted.
// "at" is the server's time of each change.
class ObservationChanges {
  final List<ObservationChange> changed = [];
  final List<ObservationDelete> deleted = [];
}

// A copy of every observation on the device, for supporters and admins. The first sync reads
// every observation once; after that each sync reads only what changed since the last one, and
// syncs at most every 15 minutes unless the user asks. The map, dashboard and Shared Observations
// all read this copy, never Firestore directly, so viewing them costs nothing.
// See docs/design/2026-10-10-supporters-plan.md, "Caching".
class ObservationsMirror {

  static const Duration syncInterval = Duration(minutes: 15);
  // Until the server stamps change times (the stampObservationUpdatedAt function), the next sync
  // starts this long before the last one by the device clock, to allow for a wrong clock
  static const Duration clockMargin = Duration(minutes: 10);
  static const int _jsonVersion = 1;
  static const String _fileName = "observations_mirror.json";

  final Future<ObservationChanges> Function(DateTime? since) fetchChanges;
  final Future<Map<String, dynamic>?> Function() loadJson;
  final Future<void> Function(Map<String, dynamic> json) saveJson;
  final DateTime Function() now;

  ObservationsMirror({
    required this.fetchChanges,
    required this.loadJson,
    required this.saveJson,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  // Kept in a file in the app's support folder
  factory ObservationsMirror.onDevice(FirebaseObservationsService remote) => ObservationsMirror(
    fetchChanges: remote.getChangesSince,
    loadJson: () async {
      final file = await _file;
      if (!await file.exists()) return null;
      final text = await file.readAsString();
      return Isolate.run(() => jsonDecode(text) as Map<String, dynamic>);
    },
    saveJson: (json) async {
      final text = await Isolate.run(() => jsonEncode(json));
      await (await _file).writeAsString(text, flush: true);
    },
  );

  static Future<File> get _file async => File(join((await getApplicationSupportDirectory()).path, _fileName));

  final Map<String, Observation> _byUid = {};
  // The server time of each observation's last change, so an old change never undoes a newer one
  final Map<String, DateTime> _changedAt = {};
  // Where the next sync starts: the newest server time seen
  DateTime? _syncedUpTo;
  // When this device last synced, by its own clock
  DateTime? _lastSyncedAt;
  bool _loaded = false;
  Future<bool>? _syncing;

  final StreamController<List<Observation>> _changes = StreamController<List<Observation>>.broadcast();
  Stream<List<Observation>> get changes => _changes.stream;

  List<Observation> get observations => _byUid.values.toList();
  bool get hasSynced => _lastSyncedAt != null;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  // Loads the saved copy (once), then syncs if it's been long enough. Returns whether anything
  // changed. Calls while a sync is running share it.
  Future<bool> sync({bool force = false}) => _syncing ??= _sync(force).whenComplete(() => _syncing = null);

  Future<bool> _sync(bool force) async {
    var changed = await _load();
    final last = _lastSyncedAt;
    if (!force && last != null && now().difference(last) < syncInterval) {
      if (changed) _publish();
      return changed;
    }

    final startedAt = now();
    try {
      final since = _syncedUpTo;
      final changes = await fetchChanges(since);
      changed = apply(changes, full: since == null, syncStartedAt: startedAt) || changed;
      _lastSyncedAt = startedAt;
      await _save();
    } catch (e) {
      // Offline or denied: keep showing the copy we have and try again next time
      developer.log('Could not sync all observations: $e', name: 'ObservationsMirror');
    }
    if (changed) _publish();
    return changed;
  }

  // Applies a sync's changes in the order they happened on the server. A full sync replaces the
  // whole copy. Returns whether anything changed.
  bool apply(ObservationChanges changes, {required bool full, required DateTime syncStartedAt}) {
    var changed = false;
    if (full) {
      changed = _byUid.isNotEmpty;
      _byUid.clear();
      _changedAt.clear();
    }

    DateTime? newest;
    void seen(DateTime? at) {
      if (at != null && (newest == null || at.isAfter(newest!))) newest = at;
    }
    bool isOlder(String uid, DateTime? at) {
      final known = _changedAt[uid];
      return known != null && at != null && at.isBefore(known);
    }

    final events = <(DateTime?, void Function())>[
      for (final change in changes.changed)
        (change.at, () {
          final uid = change.observation.uid ?? "";
          seen(change.at);
          if (uid.isEmpty || isOlder(uid, change.at)) return;
          _byUid[uid] = change.observation;
          if (change.at != null) _changedAt[uid] = change.at!;
          changed = true;
        }),
      for (final delete in changes.deleted)
        (delete.at, () {
          seen(delete.at);
          if (isOlder(delete.uid, delete.at)) return;
          if (_byUid.remove(delete.uid) != null) changed = true;
          if (delete.at != null) _changedAt[delete.uid] = delete.at!;
        }),
    ];
    // Untimed changes first, then oldest to newest
    events.sort((a, b) => a.$1 == null ? (b.$1 == null ? 0 : -1) : (b.$1 == null ? 1 : a.$1!.compareTo(b.$1!)));
    for (final event in events) {
      event.$2();
    }

    final fallback = syncStartedAt.subtract(clockMargin);
    _syncedUpTo = newest ?? (full ? fallback : _syncedUpTo ?? fallback);
    return changed;
  }

  // This device saved or deleted an observation: show it at once, without waiting for a sync
  void put(Observation observation) {
    final uid = observation.uid ?? "";
    if (uid.isEmpty || !hasSynced) return;
    _byUid[uid] = observation.copy();
    _publish();
    _save();
  }

  void remove(String? uid) {
    if (uid == null || _byUid.remove(uid) == null) return;
    _publish();
    _save();
  }

  void _publish() => _changes.add(observations);

  Future<bool> _load() async {
    if (_loaded) return false;
    _loaded = true;
    try {
      final json = await loadJson();
      if (json == null || json['version'] != _jsonVersion) return false;
      _syncedUpTo = _parse(json['syncedUpTo']);
      _lastSyncedAt = _parse(json['lastSyncedAt']);
      for (final entry in (json['observations'] as Map<String, dynamic>).entries) {
        _byUid[entry.key] = FirebaseObservationsService.observationFromMap(entry.key, entry.value as Map<String, dynamic>);
      }
      for (final entry in (json['changedAt'] as Map<String, dynamic>).entries) {
        final at = _parse(entry.value);
        if (at != null) _changedAt[entry.key] = at;
      }
      return _byUid.isNotEmpty;
    } catch (e) {
      // A damaged copy just means reading everything again
      developer.log('Could not read the saved observations: $e', name: 'ObservationsMirror');
      _byUid.clear();
      _changedAt.clear();
      _syncedUpTo = null;
      _lastSyncedAt = null;
      return false;
    }
  }

  Future<void> _save() async {
    try {
      await saveJson({
        'version': _jsonVersion,
        'syncedUpTo': _syncedUpTo?.toIso8601String(),
        'lastSyncedAt': _lastSyncedAt?.toIso8601String(),
        'observations': {for (final entry in _byUid.entries) entry.key: entry.value.toJsonObservation()},
        'changedAt': {for (final entry in _changedAt.entries) entry.key: entry.value.toIso8601String()},
      });
    } catch (e) {
      developer.log('Could not save the observations: $e', name: 'ObservationsMirror');
    }
  }

  static DateTime? _parse(dynamic value) => value is String ? DateTime.tryParse(value) : null;
}
