import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/utils/map_clusters.dart';

void main() {
  // Two points about 100 m apart near Boulder, and one in Denver
  final points = [(40.0150, -105.2705), (40.0158, -105.2700), (39.7392, -104.9903)];
  List<MapCluster<(double, double)>> at(double zoom) =>
      clusterPoints(points, latitude: (p) => p.$1, longitude: (p) => p.$2, zoom: zoom);

  test('Zoomed out, nearby points share one marker', () {
    final clusters = at(3);
    expect(clusters.length, 1);
    expect(clusters.single.count, 3);
  });

  test('Zoomed in, every point has its own marker', () {
    expect(at(18).every((cluster) => cluster.isSingle), isTrue);
  });

  test('In between, the two Boulder points group and Denver stands alone', () {
    final clusters = at(11);
    expect(clusters.map((cluster) => cluster.count).toList()..sort(), [1, 2]);
  });
}
