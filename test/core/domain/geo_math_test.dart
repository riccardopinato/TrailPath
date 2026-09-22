import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/geo_math.dart';
import 'package:trail_path/core/domain/models.dart';

void main() {
  test('bearing points north east south and west', () {
    const origin = GeoPoint(latitude: 0, longitude: 0);

    expect(
      bearingDegrees(origin, const GeoPoint(latitude: 1, longitude: 0)),
      closeTo(0, 0.01),
    );
    expect(
      bearingDegrees(origin, const GeoPoint(latitude: 0, longitude: 1)),
      closeTo(90, 0.01),
    );
    expect(
      bearingDegrees(origin, const GeoPoint(latitude: -1, longitude: 0)),
      closeTo(180, 0.01),
    );
    expect(
      bearingDegrees(origin, const GeoPoint(latitude: 0, longitude: -1)),
      closeTo(270, 0.01),
    );
  });

  test('normalizes negative bearings', () {
    expect(normalizeDegrees(-45), 315);
    expect(normalizeDegrees(405), 45);
  });
}
