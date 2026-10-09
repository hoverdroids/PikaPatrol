import 'dart:math';

import '../model/observation.dart';
import '../model/storage_file.dart';

// A clue that a stored file belongs to an observation
enum MatchSignalKind {
  // The file is still in Storage, but the observation's link to it no longer works
  linkExpired,
  // The observation points to a file on someone's phone (or a missing file) with this file's name
  sameName,
  // Uploaded within moments of a file the observation already has: one save uploads all its files
  uploadedWithLinkedFile,
  // The file name holds the time it was made (cropped photos do), close to when the observation was started
  madeNearObservationStart,
  // Uploaded close to when the observation was last saved to the server
  uploadedNearSave,
  // Uploaded some time after the observation's date, for example back home after a day offline
  uploadedAfterObservationDate,
  // The observation has a broken link of the same kind (photo or recording)
  observationHasBrokenLink,
  // Another observation matches almost as well, so this match is less certain
  closeRunnerUp,
}

class MatchSignal {
  final MatchSignalKind kind;
  final Duration? apart;

  const MatchSignal(this.kind, [this.apart]);
}

// One observation a file might belong to
class FileMatch {
  final Observation observation;
  // 0 to 1; 1 only for exact matches (expired link, same file name)
  final double certainty;
  final List<MatchSignal> signals;
  // The broken entry this file replaces when it's an exact match
  final String? brokenUrl;

  const FileMatch({required this.observation, required this.certainty, required this.signals, this.brokenUrl});
}

// A stored file and the observations it might belong to, best first. The admin can pick another.
class FileFix {
  final StorageFile file;
  final List<FileMatch> candidates;
  int chosen = 0;

  FileFix(this.file, this.candidates);

  FileMatch get match => candidates[chosen];
  Observation get observation => match.observation;
  double get certainty => match.certainty;
  bool get isImage => file.isImage;
}

// Finds broken photo and recording links on observations, and scores how likely each stored
// file nothing uses is to belong to each observation. Pure logic, no Firebase calls, so it can
// be tested and run off the main thread.
//
// Exact matches (100%):
//  - The observation links to this file, but with an old access token (a re-upload replaced it)
//  - The observation links to a phone path or missing file with this file's name
//
// Otherwise each clue gives a score that halves for every "half-life" of time between the two
// moments, and the clues combine (any one strong clue is enough):
//  - Uploaded with a file the observation has:      95%, halves every 2 minutes
//  - File name time near the observation's start:   90%, halves every 30 minutes
//  - Uploaded near the observation's last save:     85%, halves every 30 minutes
//  - Uploaded after the observation's date:         70%, halves every 12 hours
// An observation with a broken link of the same kind gets a boost (it is missing a file). When
// another observation matches almost as well, half the runner-up's score is taken off, so close
// calls never look certain.
class StorageFileCorrelator {

  static const double minimumScore = 0.05;
  static const int maxCandidates = 3;

  final List<Observation> observations;
  // Every file in Storage by path
  final Map<String, StorageFile> filesByPath;
  // A working download URL for each file an observation points to, by path
  final Map<String, String> currentUrlsByPath;
  final String? Function(String url) storagePathFromUrl;

  StorageFileCorrelator({
    required this.observations,
    required this.filesByPath,
    required this.currentUrlsByPath,
    required this.storagePathFromUrl,
  });

  late final Set<String> _usedPaths = {
    for (var observation in observations)
      for (var url in [...?observation.imageUrls, ...?observation.audioUrls])
        if (storagePathFromUrl(url) case final path? when filesByPath.containsKey(path)) path,
  };

  // Files that no observation points to
  List<StorageFile> get orphans => filesByPath.values.where((file) => !_usedPaths.contains(file.path)).toList();

  bool isBroken(String url) {
    final path = storagePathFromUrl(url);
    return path == null || !filesByPath.containsKey(path);
  }

  // The token in a download URL, which changes when a file is uploaded again
  static String? _token(String url) => Uri.tryParse(url)?.queryParameters['token'];

  // Strips the random prefix the app adds to new uploads ("<20 characters>_name.jpg")
  static String baseName(String pathOrUrl) {
    var name = Uri.decodeComponent(pathOrUrl.split('?').first).split('/').last;
    final prefixed = RegExp(r'^[A-Za-z0-9]{20}_(.+)$').firstMatch(name);
    return prefixed?.group(1) ?? name;
  }

  // The time in a file name, for example image_cropper_1719853200000.jpg (milliseconds)
  static DateTime? timeInName(String name) {
    for (var match in RegExp(r'\d{10,13}').allMatches(name)) {
      final digits = match.group(0)!;
      final value = int.parse(digits);
      final time = digits.length == 13
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
      // Pika Patrol has existed since 2019
      if (time.year >= 2019 && time.isBefore(DateTime.now().add(const Duration(days: 1)))) return time;
    }
    return null;
  }

  static double _decay(double peak, Duration apart, Duration halfLife) =>
      peak * pow(0.5, apart.inSeconds / halfLife.inSeconds).toDouble();

  ({List<FileFix> fixes, List<StorageFile> unmatched}) correlate({double unusedBelow = 0.2}) {
    final fixes = <FileFix>[];

    // 1. Links to files that still exist but whose token changed
    for (var observation in observations) {
      for (var url in [...?observation.imageUrls, ...?observation.audioUrls]) {
        final path = storagePathFromUrl(url);
        final file = path == null ? null : filesByPath[path];
        final currentUrl = path == null ? null : currentUrlsByPath[path];
        if (file != null && currentUrl != null && _token(url) != _token(currentUrl)) {
          fixes.add(FileFix(file, [
            FileMatch(observation: observation, certainty: 1, signals: const [MatchSignal(MatchSignalKind.linkExpired)], brokenUrl: url),
          ]));
        }
      }
    }

    // Broken entries each observation still has, by type
    final brokenEntries = <Observation, Map<bool, List<String>>>{
      for (var observation in observations)
        observation: {
          true: (observation.imageUrls ?? <String>[]).where(isBroken).toList(),
          false: (observation.audioUrls ?? <String>[]).where(isBroken).toList(),
        }
    };

    // Upload times of the files each observation already has
    final linkedUploadTimes = <Observation, List<DateTime>>{
      for (var observation in observations)
        observation: [
          for (var url in [...?observation.imageUrls, ...?observation.audioUrls])
            if (filesByPath[storagePathFromUrl(url) ?? '']?.created case final created?) created,
        ]
    };

    final unmatched = <StorageFile>[];
    for (var file in orphans) {
      // 2. Same file name as a broken entry
      FileMatch? exact;
      for (var entry in brokenEntries.entries) {
        final slots = entry.value[file.isImage]!;
        final match = slots.where((url) => baseName(url) == baseName(file.path)).firstOrNull;
        if (match != null) {
          exact = FileMatch(observation: entry.key, certainty: 1, signals: const [MatchSignal(MatchSignalKind.sameName)], brokenUrl: match);
          slots.remove(match);
          break;
        }
      }
      if (exact != null) {
        fixes.add(FileFix(file, [exact]));
        continue;
      }

      // 3. Score every observation by time clues
      final scored = <({Observation observation, double score, List<MatchSignal> signals})>[];
      for (var observation in observations) {
        final result = _score(file, observation, linkedUploadTimes[observation]!, brokenEntries[observation]![file.isImage]!.isNotEmpty);
        if (result.score >= minimumScore) {
          scored.add((observation: observation, score: result.score, signals: result.signals));
        }
      }
      scored.sort((a, b) => b.score.compareTo(a.score));

      final candidates = <FileMatch>[];
      for (var i = 0; i < min(maxCandidates, scored.length); i++) {
        final bestOther = i == 0 ? (scored.length > 1 ? scored[1].score : 0.0) : scored[0].score;
        final penalty = bestOther / 2;
        candidates.add(FileMatch(
          observation: scored[i].observation,
          certainty: max(0.0, min(0.99, scored[i].score - penalty)),
          signals: [
            ...scored[i].signals,
            if (penalty >= minimumScore) const MatchSignal(MatchSignalKind.closeRunnerUp),
          ],
        ));
      }
      candidates.sort((a, b) => b.certainty.compareTo(a.certainty));

      if (candidates.isEmpty || candidates.first.certainty < unusedBelow) {
        unmatched.add(file);
      }
      if (candidates.isNotEmpty) {
        fixes.add(FileFix(file, candidates));
      }
    }

    fixes.sort((a, b) => b.certainty.compareTo(a.certainty));
    return (fixes: fixes, unmatched: unmatched);
  }

  ({double score, List<MatchSignal> signals}) _score(StorageFile file, Observation observation, List<DateTime> linkedUploadTimes, bool hasBrokenLink) {
    final created = file.created;
    final signals = <MatchSignal>[];
    final scores = <double>[];

    void add(MatchSignalKind kind, double score, Duration apart) {
      if (score < minimumScore) return;
      scores.add(score);
      signals.add(MatchSignal(kind, apart));
    }

    if (created != null) {
      Duration? nearestLinked;
      for (var time in linkedUploadTimes) {
        final apart = created.difference(time).abs();
        if (nearestLinked == null || apart < nearestLinked) nearestLinked = apart;
      }
      if (nearestLinked != null) {
        add(MatchSignalKind.uploadedWithLinkedFile, _decay(0.95, nearestLinked, const Duration(minutes: 2)), nearestLinked);
      }

      final saved = observation.dateUpdatedInGoogleSheets;
      if (saved != null) {
        final apart = created.difference(saved).abs();
        add(MatchSignalKind.uploadedNearSave, _decay(0.85, apart, const Duration(minutes: 30)), apart);
      }

      final date = observation.date;
      if (date != null && created.isAfter(date.subtract(const Duration(hours: 1)))) {
        final apart = created.difference(date).abs();
        add(MatchSignalKind.uploadedAfterObservationDate, _decay(0.7, apart, const Duration(hours: 12)), apart);
      }
    }

    final madeAt = timeInName(file.name);
    final started = observation.date;
    if (madeAt != null && started != null) {
      final apart = madeAt.difference(started).abs();
      add(MatchSignalKind.madeNearObservationStart, _decay(0.9, apart, const Duration(minutes: 30)), apart);
    }

    if (scores.isEmpty) return (score: 0.0, signals: signals);

    // Any one strong clue is enough: the chance that every clue is wrong is what's left over
    var missing = scores.fold<double>(1.0, (left, score) => left * (1 - score));
    if (hasBrokenLink) {
      missing *= 0.7;
      signals.add(const MatchSignal(MatchSignalKind.observationHasBrokenLink));
    }
    return (score: 1 - missing, signals: signals);
  }

  // The observation's lists with the chosen fixes applied, keeping the order (and cover photo).
  // A fix that replaces a known broken entry goes in its place; any other fix fills the next
  // broken entry of its kind, or goes at the end if there is none.
  static ({List<String> imageUrls, List<String> audioUrls}) applyFixes(
    Observation observation,
    List<FileFix> fixes,
    Map<String, String> newUrlsByPath,
    bool Function(String url) isBroken,
  ) {
    List<String> apply(List<String>? urls, bool isImage) {
      final result = [...?urls];
      final replaced = <int>{};
      final typed = fixes.where((fix) => fix.isImage == isImage).toList()
        // Exact replacements first, so they keep their own spots
        ..sort((a, b) => (a.match.brokenUrl == null ? 1 : 0).compareTo(b.match.brokenUrl == null ? 1 : 0));
      for (var fix in typed) {
        final newUrl = newUrlsByPath[fix.file.path];
        if (newUrl == null || result.contains(newUrl)) continue;
        var index = fix.match.brokenUrl == null ? -1 : result.indexOf(fix.match.brokenUrl!);
        if (index < 0) {
          index = Iterable<int>.generate(result.length)
              .where((i) => !replaced.contains(i) && isBroken(result[i]))
              .firstOrNull ?? -1;
        }
        if (index >= 0) {
          result[index] = newUrl;
          replaced.add(index);
        } else {
          result.add(newUrl);
        }
      }
      return result;
    }

    return (imageUrls: apply(observation.imageUrls, true), audioUrls: apply(observation.audioUrls, false));
  }
}
