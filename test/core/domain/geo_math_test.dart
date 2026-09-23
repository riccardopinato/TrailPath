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

  test('simplifyTraceForRouting preserves corners and caps waypoints', () {
    final trace = <GeoPoint>[
      for (var index = 0; index <= 30; index++)
        GeoPoint(latitude: 45.0, longitude: 11.0 + index * 0.0001),
      for (var index = 1; index <= 30; index++)
        GeoPoint(latitude: 45.0 + index * 0.0001, longitude: 11.003),
    ];

    final simplified = simplifyTraceForRouting(
      trace,
      minSpacingMeters: 0,
      toleranceMeters: 2,
      maxWaypoints: 12,
    );

    expect(simplified.length, lessThanOrEqualTo(12));
    expect(simplified.first, trace.first);
    expect(simplified.last, trace.last);
    expect(
      simplified.any(
        (point) =>
            (point.latitude - 45.0).abs() < 0.000001 &&
            (point.longitude - 11.003).abs() < 0.000001,
      ),
      isTrue,
    );
  });

  test('simplifyTraceForRouting drops dense near-duplicate samples', () {
    final trace = [
      for (var index = 0; index <= 100; index++)
        GeoPoint(latitude: 45.0, longitude: 11.0 + index * 0.000001),
    ];

    final simplified = simplifyTraceForRouting(
      trace,
      minSpacingMeters: 8,
      toleranceMeters: 1,
    );

    expect(simplified.length, lessThan(10));
    expect(simplified.first, trace.first);
    expect(simplified.last, trace.last);
  });

  test('chunkRouteWaypoints overlaps seams without dropping points', () {
    final points = [
      for (var index = 0; index < 47; index++)
        GeoPoint(latitude: 45.0, longitude: 11.0 + index * 0.001),
    ];

    final chunks = chunkRouteWaypoints(points, maxPointsPerChunk: 20);

    expect(chunks, hasLength(3));
    expect(chunks[0], hasLength(20));
    expect(chunks[1], hasLength(20));
    expect(chunks[2], hasLength(9));
    expect(chunks[0].last, same(chunks[1].first));
    expect(chunks[1].last, same(chunks[2].first));

    final reconstructed = <GeoPoint>[
      ...chunks.first,
      for (final chunk in chunks.skip(1)) ...chunk.skip(1),
    ];
    expect(reconstructed, points);
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
