import '../model/observation.dart';
import '../model/storage_file.dart';

enum FileFixConfidence { high, likely, possible }

enum FileFixReason {
  // The file is still in Storage, but the observation's link to it no longer works
  refreshLink,
  // The observation points to a file on someone's phone (or a missing file) with this file's name
  sameName,
  // The file was uploaded close to when the observation was made or saved
  uploadedNearby,
}

// One proposed repair of an observation's photo or recording link
class FileFix {
  final Observation observation;
  final StorageFile file;
  final bool isImage;
  // The broken entry this fix replaces; null to fill the next broken entry or add at the end
  final String? brokenUrl;
  final FileFixReason reason;
  final FileFixConfidence confidence;
  final Duration? timeApart;

  const FileFix({
    required this.observation,
    required this.file,
    required this.isImage,
    required this.brokenUrl,
    required this.reason,
    required this.confidence,
    this.timeApart,
  });
}

// Finds broken photo and recording links on observations, and the Storage files most likely to
// be the missing ones. Pure logic, no Firebase calls, so it can be tested.
//
// How links broke in older versions:
//  - A re-upload replaced a file's access token, so the old link stopped working (refreshLink)
//  - An observation was saved with a path on the phone instead of a Storage link, while the
//    file itself was uploaded under the same name (sameName)
//  - An observation points to a Storage file that no longer exists (sameName or uploadedNearby)
class StorageFileCorrelator {

  static const Duration likelyWindow = Duration(minutes: 10);
  static const Duration possibleWindow = Duration(hours: 24);

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

  ({List<FileFix> fixes, List<StorageFile> unmatched}) correlate() {
    final fixes = <FileFix>[];

    // 1. Links to files that still exist but whose token changed
    for (var observation in observations) {
      for (var isImage in [true, false]) {
        for (var url in (isImage ? observation.imageUrls : observation.audioUrls) ?? <String>[]) {
          final path = storagePathFromUrl(url);
          final file = path == null ? null : filesByPath[path];
          final currentUrl = path == null ? null : currentUrlsByPath[path];
          if (file != null && currentUrl != null && _token(url) != _token(currentUrl)) {
            fixes.add(FileFix(observation: observation, file: file, isImage: isImage, brokenUrl: url,
                reason: FileFixReason.refreshLink, confidence: FileFixConfidence.high));
          }
        }
      }
    }

    // Broken entries each observation still needs filled, by type
    final openSlots = <Observation, Map<bool, List<String>>>{
      for (var observation in observations)
        observation: {
          true: (observation.imageUrls ?? <String>[]).where(isBroken).toList(),
          false: (observation.audioUrls ?? <String>[]).where(isBroken).toList(),
        }
    };

    final unassigned = orphans.toSet();

    // 2. Orphan files with the same name as a broken entry
    for (var file in orphans) {
      for (var entry in openSlots.entries) {
        final slots = entry.value[file.isImage]!;
        final match = slots.where((url) => baseName(url) == baseName(file.path)).firstOrNull;
        if (match != null) {
          fixes.add(FileFix(observation: entry.key, file: file, isImage: file.isImage, brokenUrl: match,
              reason: FileFixReason.sameName, confidence: FileFixConfidence.high));
          slots.remove(match);
          unassigned.remove(file);
          break;
        }
      }
    }

    // 3. Remaining orphans to the observation saved or made closest in time, closest pairs first,
    //    never more files than an observation has broken entries
    final pairs = <({StorageFile file, Observation observation, Duration apart})>[];
    for (var file in unassigned) {
      final created = file.created;
      if (created == null) continue;
      for (var entry in openSlots.entries) {
        if (entry.value[file.isImage]!.isEmpty) continue;
        final apart = _closest(created, [entry.key.dateUpdatedInGoogleSheets, entry.key.date]);
        if (apart != null && apart <= possibleWindow) {
          pairs.add((file: file, observation: entry.key, apart: apart));
        }
      }
    }
    pairs.sort((a, b) => a.apart.compareTo(b.apart));
    for (var pair in pairs) {
      final slots = openSlots[pair.observation]![pair.file.isImage]!;
      if (!unassigned.contains(pair.file) || slots.isEmpty) continue;
      fixes.add(FileFix(observation: pair.observation, file: pair.file, isImage: pair.file.isImage,
          brokenUrl: slots.removeAt(0),
          reason: FileFixReason.uploadedNearby,
          confidence: pair.apart <= likelyWindow ? FileFixConfidence.likely : FileFixConfidence.possible,
          timeApart: pair.apart));
      unassigned.remove(pair.file);
    }

    fixes.sort((a, b) => a.confidence.index.compareTo(b.confidence.index));
    return (fixes: fixes, unmatched: unassigned.toList());
  }

  static Duration? _closest(DateTime time, List<DateTime?> candidates) {
    Duration? best;
    for (var candidate in candidates) {
      if (candidate == null) continue;
      final apart = time.difference(candidate).abs();
      if (best == null || apart < best) best = apart;
    }
    return best;
  }

  // The observation's lists with the chosen fixes applied. Each fix replaces its broken entry in
  // place, so the order (and the cover photo) stays the same.
  static ({List<String> imageUrls, List<String> audioUrls}) applyFixes(
    Observation observation,
    List<FileFix> fixes,
    Map<String, String> newUrlsByPath,
  ) {
    List<String> apply(List<String>? urls, bool isImage) {
      final result = [...?urls];
      for (var fix in fixes.where((fix) => fix.isImage == isImage)) {
        final newUrl = newUrlsByPath[fix.file.path];
        if (newUrl == null) continue;
        final index = fix.brokenUrl == null ? -1 : result.indexOf(fix.brokenUrl!);
        if (index >= 0) {
          result[index] = newUrl;
        } else if (!result.contains(newUrl)) {
          result.add(newUrl);
        }
      }
      return result;
    }

    return (imageUrls: apply(observation.imageUrls, true), audioUrls: apply(observation.audioUrls, false));
  }
}
