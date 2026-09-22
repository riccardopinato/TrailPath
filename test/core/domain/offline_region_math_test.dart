import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/offline_region_math.dart';

void main() {
  test('offline request pads route bounds and selects detail zoom', () {
    final request = offlineRegionRequestForRoute(
      id: 'route-1',
      name: 'Test route',
      points: const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.1, longitude: 11.2),
        GeoPoint(latitude: 45.05, longitude: 11.1),
      ],
    );

    expect(request.id, 'route-1');
    expect(request.south, closeTo(44.982, 0.000001));
    expect(request.north, closeTo(45.118, 0.000001));
    expect(request.west, closeTo(10.964, 0.000001));
    expect(request.east, closeTo(11.236, 0.000001));
    expect(request.minZoom, 8);
    expect(request.maxZoom, 15);
  });

  test('offline request lowers maximum zoom for very large routes', () {
    final request = offlineRegionRequestForRoute(
      id: 'route-large',
      name: 'Large route',
      points: const [
        GeoPoint(latitude: 45, longitude: 10),
        GeoPoint(latitude: 46.1, longitude: 11.2),
      ],
    );

    expect(request.maxZoom, 13);
  });

  test('offline request rejects incomplete geometry', () {
    expect(
      () => offlineRegionRequestForRoute(
        id: 'route-short',
        name: 'Short route',
        points: const [GeoPoint(latitude: 45, longitude: 11)],
      ),
      throwsArgumentError,
    );
  });
}
