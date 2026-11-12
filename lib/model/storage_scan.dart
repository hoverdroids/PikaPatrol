import '../services/firebase_observations_service.dart';
import '../services/storage_file_correlator.dart';
import 'storage_file.dart';

// The result of an admin Storage scan. It is saved on the phone, so the file screens open
// instantly, even after a restart, until the admin pulls down to scan again. Fixes and deletes
// made from those screens update it in place.
class StorageScan {
  static const int _jsonVersion = 1;

  final List<FileFix> fixes;
  final List<StorageFile> unused;
  final int observationCount;
  int totalFileCount;
  // Storage paths observations pointed to that did not exist when scanned. A path the scan never
  // saw (for example a photo uploaded since) is not treated as broken.
  final Set<String> missingPaths;
  final DateTime scannedAt;

  StorageScan({
    required this.fixes,
    required this.unused,
    required this.observationCount,
    required this.totalFileCount,
    required this.missingPaths,
    required this.scannedAt,
  });

  bool isBroken(String url) {
    final path = FirebaseObservationsService.storagePathFromUrl(url);
    return path == null || missingPaths.contains(path);
  }

  // Applied fixes leave the list, and their files are no longer unused
  void removeFixes(Iterable<FileFix> applied) {
    final appliedSet = applied.toSet();
    final paths = {for (var fix in appliedSet) fix.file.path};
    fixes.removeWhere(appliedSet.contains);
    // A file now linked to one observation is no longer a candidate for another
    fixes.removeWhere((fix) => paths.contains(fix.file.path) && fix.match.brokenUrl == null);
    unused.removeWhere((file) => paths.contains(file.path));
  }

  void removeDeletedFiles(Iterable<StorageFile> files) {
    final paths = {for (var file in files) file.path};
    fixes.removeWhere((fix) => paths.contains(fix.file.path));
    unused.removeWhere((file) => paths.contains(file.path));
    totalFileCount -= paths.length;
  }

  // Each observation and file is written once and referred to by uid or path
  Map<String, dynamic> toJson() {
    final observations = <String, Map<String, dynamic>>{};
    final files = <String, Map<String, dynamic>>{};

    void addFile(StorageFile file) => files[file.path] = {
      'isImage': file.isImage,
      'size': file.sizeBytes,
      'created': file.created?.toIso8601String(),
    };

    for (var fix in fixes) {
      addFile(fix.file);
      for (var candidate in fix.candidates) {
        final observation = candidate.observation;
        observations[observation.uid!] = observation.toFirebaseObservation().map(
          (key, value) => MapEntry(key, value is DateTime ? value.toIso8601String() : value),
        );
      }
    }
    unused.forEach(addFile);

    return {
      'version': _jsonVersion,
      'scannedAt': scannedAt.toIso8601String(),
      'observationCount': observationCount,
      'totalFileCount': totalFileCount,
      'missingPaths': missingPaths.toList(),
      'observations': observations,
      'files': files,
      'fixes': [
        for (var fix in fixes)
          {
            'file': fix.file.path,
            'chosen': fix.chosen,
            'candidates': [
              for (var candidate in fix.candidates)
                {
                  'observation': candidate.observation.uid,
                  'certainty': candidate.certainty,
                  'brokenUrl': candidate.brokenUrl,
                  'signals': [
                    for (var signal in candidate.signals)
                      {'kind': signal.kind.name, 'apartSeconds': signal.apart?.inSeconds}
                  ],
                }
            ],
          }
      ],
      'unused': [for (var file in unused) file.path],
    };
  }

  // Null when the saved scan is from another version of the app or can't be read
  static StorageScan? fromJson(Map<String, dynamic> json) {
    if (json['version'] != _jsonVersion) return null;

    final observations = {
      for (var entry in (json['observations'] as Map<String, dynamic>).entries)
        entry.key: FirebaseObservationsService.observationFromMap(entry.key, entry.value as Map<String, dynamic>)
    };
    final files = {
      for (var entry in (json['files'] as Map<String, dynamic>).entries)
        entry.key: StorageFile(
          path: entry.key,
          isImage: entry.value['isImage'] as bool,
          sizeBytes: entry.value['size'] as int,
          created: entry.value['created'] == null ? null : DateTime.parse(entry.value['created'] as String),
        )
    };

    FileMatch match(Map<String, dynamic> candidate) => FileMatch(
      observation: observations[candidate['observation']]!,
      certainty: (candidate['certainty'] as num).toDouble(),
      brokenUrl: candidate['brokenUrl'] as String?,
      signals: [
        for (var signal in candidate['signals'] as List<dynamic>)
          MatchSignal(
            MatchSignalKind.values.byName(signal['kind'] as String),
            signal['apartSeconds'] == null ? null : Duration(seconds: signal['apartSeconds'] as int),
          )
      ],
    );

    return StorageScan(
      fixes: [
        for (var fix in json['fixes'] as List<dynamic>)
          FileFix(files[fix['file']]!, [for (var candidate in fix['candidates'] as List<dynamic>) match(candidate)])
            ..chosen = fix['chosen'] as int,
      ],
      unused: [for (var path in json['unused'] as List<dynamic>) files[path]!],
      observationCount: json['observationCount'] as int,
      totalFileCount: json['totalFileCount'] as int,
      missingPaths: (json['missingPaths'] as List<dynamic>).cast<String>().toSet(),
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
}
