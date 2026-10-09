import '../model/observation.dart';

// Copies of one observation, as found on the server
class DuplicateGroup {
  final List<Observation> observations;
  // The copy to keep; the others are merged into it and deleted
  Observation keep;

  DuplicateGroup(this.observations) : keep = DuplicateObservationFinder.bestToKeep(observations);

  List<Observation> get others => observations.where((observation) => observation != keep).toList();
}

// Finds observations saved to the server more than once. Before July 2026, two upload attempts
// could race and save the same offline observation under two uids. Copies share the observer and
// the moment the observation was started, and the same site name or coordinates (a later edit can
// change one of them). Pure logic, so it can be tested.
class DuplicateObservationFinder {

  static const Duration sameMoment = Duration(minutes: 1);

  static List<DuplicateGroup> find(List<Observation> observations) {
    final byObserver = <String, List<Observation>>{};
    for (var observation in observations) {
      final observer = observation.observerUid ?? '';
      if (observer.isEmpty || observation.date == null || (observation.uid ?? '').isEmpty) continue;
      byObserver.putIfAbsent(observer, () => []).add(observation);
    }

    final groups = <DuplicateGroup>[];
    for (var list in byObserver.values) {
      list.sort((a, b) => a.date!.compareTo(b.date!));
      final grouped = <Observation>{};
      for (var i = 0; i < list.length; i++) {
        if (grouped.contains(list[i])) continue;
        final group = [list[i]];
        for (var j = i + 1; j < list.length && list[j].date!.difference(list[i].date!) <= sameMoment; j++) {
          if (!grouped.contains(list[j]) && _samePlace(list[i], list[j])) group.add(list[j]);
        }
        if (group.length > 1) {
          grouped.addAll(group);
          groups.add(DuplicateGroup(group));
        }
      }
    }

    groups.sort((a, b) => b.keep.date!.compareTo(a.keep.date!));
    return groups;
  }

  static bool _samePlace(Observation a, Observation b) {
    final nameA = (a.location ?? '').trim().toLowerCase();
    final nameB = (b.location ?? '').trim().toLowerCase();
    if (nameA.isNotEmpty && nameA == nameB) return true;
    final latA = a.latitude, lonA = a.longitude, latB = b.latitude, lonB = b.longitude;
    if (latA == null || lonA == null || latB == null || lonB == null || (latA == 0 && lonA == 0)) return false;
    // About 10 m
    return (latA - latB).abs() < 0.0001 && (lonA - lonB).abs() < 0.0001;
  }

  // The copy with the most photos and recordings, then the one saved most recently
  static Observation bestToKeep(List<Observation> copies) {
    int media(Observation o) => (o.imageUrls?.length ?? 0) + (o.audioUrls?.length ?? 0);
    final sorted = [...copies]..sort((a, b) {
      final byMedia = media(b).compareTo(media(a));
      if (byMedia != 0) return byMedia;
      return (b.dateUpdatedInGoogleSheets ?? DateTime(0)).compareTo(a.dateUpdatedInGoogleSheets ?? DateTime(0));
    });
    return sorted.first;
  }

  // The kept observation's lists with every other copy's photos, recordings and projects added,
  // keeping its own order (and cover photo) first. Links to the same Storage file count once.
  static ({List<String> imageUrls, List<String> audioUrls, List<String> sharedWithProjects}) merge(
    Observation keep,
    List<Observation> others,
    String? Function(String url) storagePathFromUrl,
  ) {
    List<String> union(List<String>? first, Iterable<List<String>?> rest) {
      final result = <String>[];
      final seen = <String>{};
      for (var url in [...?first, for (var list in rest) ...?list]) {
        if (seen.add(storagePathFromUrl(url) ?? url)) result.add(url);
      }
      return result;
    }

    return (
      imageUrls: union(keep.imageUrls, others.map((o) => o.imageUrls)),
      audioUrls: union(keep.audioUrls, others.map((o) => o.audioUrls)),
      sharedWithProjects: {...?keep.sharedWithProjects, for (var o in others) ...?o.sharedWithProjects}.toList(),
    );
  }
}
