import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  group('GeoPoint', () {
    test('stores valid geographic coordinates', () {
      const point = GeoPoint(
        latitude: 45.23,
        longitude: 11.75,
        elevationMeters: 18,
      );

      expect(point.latitude, 45.23);
      expect(point.longitude, 11.75);
      expect(point.elevationMeters, 18);
    });

    test('copyWith preserves unspecified values', () {
      const point = GeoPoint(
        latitude: 45,
        longitude: 11,
        elevationMeters: 100,
      );

      final moved = point.copyWith(latitude: 46);

      expect(moved.latitude, 46);
      expect(moved.longitude, 11);
      expect(moved.elevationMeters, 100);
    });
  });

  test('RoutePlan keeps provider-independent route metrics', () {
    const plan = RoutePlan(
      geometry: [
        GeoPoint(latitude: 45, longitude: 11),
        GeoPoint(latitude: 45.01, longitude: 11.01),
      ],
      distanceMeters: 8400,
      ascentMeters: 620,
      descentMeters: 615,
      estimatedDuration: Duration(hours: 2, minutes: 35),
      profile: RouteProfile.hiking,
    );

    expect(plan.distanceMeters, 8400);
    expect(plan.ascentMeters, 620);
    expect(plan.profile, RouteProfile.hiking);
  });
}
