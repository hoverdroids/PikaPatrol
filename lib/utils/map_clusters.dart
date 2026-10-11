import 'dart:math';

// Groups map points that would sit on top of each other at a zoom level, so a map with thousands
// of points draws a few dozen markers. Works with any map that uses Web Mercator tiles (Syncfusion
// Maps, OpenStreetMap, MapTiler and most others), and knows nothing about what the points are.
// Syncfusion Maps has no clustering of its own, which is why this exists.

class MapCluster<T> {
  final List<T> items;
  final double latitude;
  final double longitude;

  const MapCluster(this.items, this.latitude, this.longitude);

  int get count => items.length;
  bool get isSingle => items.length == 1;
}

// Points in the same square of cellPixels by cellPixels screen pixels, at this zoom, become one
// cluster at their average position. Order follows the first point in each square.
List<MapCluster<T>> clusterPoints<T>(
  Iterable<T> items, {
  required double Function(T) latitude,
  required double Function(T) longitude,
  required double zoom,
  double cellPixels = 48.0,
  int tileSize = 256,
}) {
  final worldPixels = tileSize * pow(2, zoom);
  final cells = <(int, int), List<T>>{};
  for (final item in items) {
    final lat = latitude(item).clamp(-85.05112878, 85.05112878);
    final x = (longitude(item) + 180.0) / 360.0 * worldPixels;
    final sinLat = sin(lat * pi / 180.0);
    final y = (0.5 - log((1 + sinLat) / (1 - sinLat)) / (4 * pi)) * worldPixels;
    (cells[((x / cellPixels).floor(), (y / cellPixels).floor())] ??= []).add(item);
  }
  return [
    for (final group in cells.values)
      MapCluster(
        group,
        group.fold(0.0, (sum, item) => sum + latitude(item)) / group.length,
        group.fold(0.0, (sum, item) => sum + longitude(item)) / group.length,
      ),
  ];
}
