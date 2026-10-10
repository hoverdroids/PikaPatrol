import 'observation.dart';

// The numbers behind the dashboard, worked out from whatever observations the viewer can see.
// Pure Dart so it can be tested without Flutter or Firebase.
class ObservationStats {

  final int total;
  final int sites;
  final int observers;
  final int withPikas;
  // Oldest month first; months with no observations in between are included as zero
  final List<MapEntry<DateTime, int>> perMonth;
  final Map<String, int> species;
  final Map<String, int> pikasDetected;
  final Map<String, int> signs;
  final Map<String, int> searchDuration;
  final Map<String, int> projects;
  final List<double> elevationsInMeters;

  const ObservationStats._({
    required this.total,
    required this.sites,
    required this.observers,
    required this.withPikas,
    required this.perMonth,
    required this.species,
    required this.pikasDetected,
    required this.signs,
    required this.searchDuration,
    required this.projects,
    required this.elevationsInMeters,
  });

  factory ObservationStats.from(Iterable<Observation> observations) {
    final list = observations.toList();
    final sites = <String>{};
    final observers = <String>{};
    final months = <DateTime, int>{};
    final species = <String, int>{};
    final pikasDetected = <String, int>{};
    final signs = <String, int>{};
    final searchDuration = <String, int>{};
    final projects = <String, int>{};
    final elevations = <double>[];
    var withPikas = 0;

    void count(Map<String, int> counts, String? value) {
      final key = value?.trim() ?? "";
      if (key.isEmpty) return;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    for (final observation in list) {
      final site = siteKey(observation);
      if (site != null) sites.add(site);

      final observer = observation.observerUid?.trim() ?? "";
      if (observer.isNotEmpty) observers.add(observer);

      final date = observation.date;
      if (date != null) {
        final month = DateTime(date.year, date.month);
        months[month] = (months[month] ?? 0) + 1;
      }

      if (hasPikas(observation)) withPikas++;

      count(species, observation.species);
      count(pikasDetected, observation.pikasDetected);
      count(searchDuration, observation.searchDuration);
      for (final sign in {...?observation.signs}) {
        count(signs, sign);
      }
      for (final project in {...?observation.sharedWithProjects}) {
        count(projects, project);
      }

      final altitude = observation.altitudeInMeters;
      if (altitude != null) elevations.add(altitude);
    }

    return ObservationStats._(
      total: list.length,
      sites: sites.length,
      observers: observers.length,
      withPikas: withPikas,
      perMonth: _fillMonths(months),
      species: species,
      pikasDetected: pikasDetected,
      signs: signs,
      searchDuration: searchDuration,
      projects: projects,
      elevationsInMeters: elevations,
    );
  }

  // One site per named location; unnamed observations fall back to their coordinates, rounded to
  // about 100 m so repeat visits to the same talus patch count once
  static String? siteKey(Observation observation) {
    final name = observation.location?.trim().toLowerCase() ?? "";
    if (name.isNotEmpty) return "name:$name";
    final latitude = observation.latitude;
    final longitude = observation.longitude;
    if (latitude == null || longitude == null) return null;
    return "at:${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}";
  }

  // A pika was seen or heard: any count other than zero
  static bool hasPikas(Observation observation) {
    final detected = observation.pikasDetected?.trim() ?? "";
    return detected.isNotEmpty && detected != "0";
  }

  static List<MapEntry<DateTime, int>> _fillMonths(Map<DateTime, int> months) {
    if (months.isEmpty) return [];
    final sorted = months.keys.toList()..sort();
    final filled = <MapEntry<DateTime, int>>[];
    for (var month = sorted.first; !month.isAfter(sorted.last); month = DateTime(month.year, month.month + 1)) {
      filled.add(MapEntry(month, months[month] ?? 0));
    }
    return filled;
  }
}
