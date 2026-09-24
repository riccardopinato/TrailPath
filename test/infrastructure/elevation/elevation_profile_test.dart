import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trail_path/core/domain/elevation_math.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/infrastructure/elevation/open_meteo_elevation_engine.dart';

void main() {
  test('elevation profile calculates ascent descent and grade', () {
    final profile = buildElevationProfile(
      const [
        GeoPoint(
          latitude: 45.0,
          longitude: 11.0,
          elevationMeters: 100,
        ),
        GeoPoint(
          latitude: 45.005,
          longitude: 11.005,
          elevationMeters: 130,
        ),
        GeoPoint(
          latitude: 45.01,
          longitude: 11.01,
          elevationMeters: 120,
        ),
      ],
      source: 'test',
      noiseThresholdMeters: 0,
    );

    expect(profile.isAvailable, isTrue);
    expect(profile.ascentMeters, 30);
    expect(profile.descentMeters, 10);
    expect(profile.minElevationMeters, 100);
    expect(profile.maxElevationMeters, 130);
    expect(profile.samples, hasLength(3));
    expect(profile.samples[1].gradePercent, greaterThan(0));
    expect(profile.samples[2].gradePercent, lessThan(0));
  });

  test('elevation noise threshold filters tiny DEM oscillations', () {
    final profile = buildElevationProfile(
      const [
        GeoPoint(
          latitude: 45.0,
          longitude: 11.0,
          elevationMeters: 100,
        ),
        GeoPoint(
          latitude: 45.001,
          longitude: 11.001,
          elevationMeters: 101,
        ),
        GeoPoint(
          latitude: 45.002,
          longitude: 11.002,
          elevationMeters: 100,
        ),
      ],
      source: 'test',
      noiseThresholdMeters: 2,
    );

    expect(profile.ascentMeters, 0);
    expect(profile.descentMeters, 0);
  });

  test('route resampling respects the 100 point elevation API limit', () {
    final points = List<GeoPoint>.generate(
      250,
      (index) => GeoPoint(
        latitude: 45 + index * 0.0001,
        longitude: 11 + index * 0.0001,
      ),
    );

    final sampled = resampleRouteByDistance(points, maxPoints: 100);

    expect(sampled, hasLength(100));
    expect(sampled.first.latitude, points.first.latitude);
    expect(sampled.last.latitude, closeTo(points.last.latitude, 0.000001));
  });

  test('elevation engine retries transient failures and returns a profile',
      () async {
    var requests = 0;
    final engine = OpenMeteoElevationEngine(
      client: MockClient((request) async {
        requests++;
        if (requests == 1) {
          return http.Response('busy', 503);
        }
        return http.Response(
          jsonEncode({
            'elevation': [100.0, 125.0],
          }),
          200,
        );
      }),
      maxRetries: 1,
      retryBaseDelay: Duration.zero,
      delay: (_) async {},
    );
    addTearDown(engine.dispose);

    final profile = await engine.resolve(
      const [
        GeoPoint(latitude: 45.0, longitude: 11.0),
        GeoPoint(latitude: 45.01, longitude: 11.01),
      ],
    );

    expect(requests, 2);
    expect(profile.isAvailable, isTrue);
    expect(profile.samples, hasLength(2));
    expect(profile.samples.last.elevationMeters, 125);
  });

  test('elevation engine does not retry permanent HTTP failures', () async {
    var requests = 0;
    final engine = OpenMeteoElevationEngine(
      client: MockClient((request) async {
        requests++;
        return http.Response('bad request', 400);
      }),
      maxRetries: 2,
      delay: (_) async {},
    );
    addTearDown(engine.dispose);

    await expectLater(
      engine.resolve(
        const [
          GeoPoint(latitude: 45.0, longitude: 11.0),
          GeoPoint(latitude: 45.01, longitude: 11.01),
        ],
      ),
      throwsA(isA<ElevationException>()),
    );
    expect(requests, 1);
  });
}
