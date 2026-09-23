import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  test('pointAlongPolyline returns midpoint by route distance', () {
    final midpoint = pointAlongPolyline(
      const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.0, longitude: 11.01),
        GeoPoint(latitude: 45.0, longitude: 11.02),
      ],
    );

    expect(midpoint.latitude, closeTo(45.0, 0.000001));
    expect(midpoint.longitude, closeTo(11.01, 0.0001));
  });

  test('distanceToPolylineMeters rejects presses far from route', () {
    const line = [
      GeoPoint(latitude: 45.0, longitude: 11.0),
      GeoPoint(latitude: 45.0, longitude: 11.02),
    ];

    final near = distanceToPolylineMeters(
      const GeoPoint(latitude: 45.0002, longitude: 11.01),
      line,
    );
    final far = distanceToPolylineMeters(
      const GeoPoint(latitude: 45.002, longitude: 11.01),
      line,
    );

    expect(near, lessThan(60));
    expect(far, greaterThan(60));
  });
}
