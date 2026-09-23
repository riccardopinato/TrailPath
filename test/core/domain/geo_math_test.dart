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

  test('simplifyPolylineForDisplay removes redundant straight-line points', () {
    final points = [
      for (var index = 0; index <= 100; index++)
        GeoPoint(latitude: 45.0, longitude: 11.0 + index * 0.00001),
    ];

    final simplified = simplifyPolylineForDisplay(points);

    expect(simplified, hasLength(2));
    expect(simplified.first, points.first);
    expect(simplified.last, points.last);
  });

  test('simplifyPolylineForDisplay preserves meaningful bends and caps output', () {
    final points = <GeoPoint>[
      const GeoPoint(latitude: 45.0, longitude: 11.0),
      const GeoPoint(latitude: 45.0, longitude: 11.01),
      const GeoPoint(latitude: 45.01, longitude: 11.01),
      for (var index = 1; index <= 40; index++)
        GeoPoint(
          latitude: 45.01 + index * 0.00001,
          longitude: 11.01,
        ),
    ];

    final simplified = simplifyPolylineForDisplay(
      points,
      toleranceMeters: 0.5,
      maxPoints: 8,
    );

    expect(simplified.length, lessThanOrEqualTo(8));
    expect(
      simplified.any((point) =>
          (point.latitude - 45.0).abs() < 0.000001 &&
          (point.longitude - 11.01).abs() < 0.000001),
      isTrue,
    );
    expect(simplified.first, points.first);
    expect(simplified.last, points.last);
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
