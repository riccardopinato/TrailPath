import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/infrastructure/routing/openstreetmap_routing_engine.dart';

void main() {
  test(
    'retries transient server errors and then returns snapped route',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        if (requests == 1) {
          return http.Response('busy', 503);
        }
        return http.Response(
          jsonEncode(_successPayload()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final engine = OpenStreetMapRoutingEngine(
        client: client,
        maxRetries: 2,
        retryBaseDelay: Duration.zero,
        delay: (_) async {},
      );
      addTearDown(engine.dispose);

      final plan = await engine.calculate(_request());

      expect(requests, 2);
      expect(plan.isSnapped, isTrue);
      expect(plan.geometry, hasLength(3));
      expect(plan.snappedWaypoints, hasLength(2));
      expect(plan.distanceMeters, 1250);
    },
  );

  test(
    'requests alternatives and chooses the shortest two-point route',
    () async {
      Uri? requestedUri;
      final payload = _successPayload();
      (payload['routes'] as List).add({
        'distance': 980.0,
        'duration': 940.0,
        'geometry': {
          'coordinates': [
            [11.0, 45.0],
            [11.004, 45.004],
            [11.01, 45.01],
          ],
        },
      });
      final engine = OpenStreetMapRoutingEngine(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(jsonEncode(payload), 200);
        }),
        maxRetries: 0,
      );
      addTearDown(engine.dispose);

      final plan = await engine.calculate(_request());

      expect(requestedUri?.queryParameters['alternatives'], 'true');
      expect(requestedUri?.queryParameters['continue_straight'], 'false');
      expect(plan.distanceMeters, 980);
    },
  );

  test(
    'selects shortest provider alternative with multiple waypoints',
    () async {
      Uri? requestedUri;
      final payload = _successPayload()
        ..['routes'] = [
          {
            'distance': 1800.0,
            'duration': 1000.0,
            'geometry': {
              'coordinates': [
                [11.0, 45.0],
                [11.005, 45.005],
                [11.01, 45.01],
              ],
            },
          },
          {
            'distance': 1450.0,
            'duration': 950.0,
            'geometry': {
              'coordinates': [
                [11.0, 45.0],
                [11.004, 45.004],
                [11.01, 45.01],
              ],
            },
          },
        ]
        ..['waypoints'] = [
          {
            'location': [11.0, 45.0],
          },
          {
            'location': [11.005, 45.005],
          },
          {
            'location': [11.01, 45.01],
          },
        ];
      final engine = OpenStreetMapRoutingEngine(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(jsonEncode(payload), 200);
        }),
        maxRetries: 0,
      );
      addTearDown(engine.dispose);

      final plan = await engine.calculate(
        const RouteRequest(
          points: [
            GeoPoint(latitude: 45.0, longitude: 11.0),
            GeoPoint(latitude: 45.005, longitude: 11.005),
            GeoPoint(latitude: 45.01, longitude: 11.01),
          ],
          profile: RouteProfile.hiking,
        ),
      );

      expect(requestedUri?.queryParameters['alternatives'], 'true');
      expect(plan.distanceMeters, 1450);
    },
  );

  test(
    'chunks dense waypoint routes before calling the public router',
    () async {
      var requests = 0;
      final engine = OpenStreetMapRoutingEngine(
        client: MockClient((request) async {
          requests++;
          final coordinates = request.url.pathSegments.last.split(';');
          final payload = {
            'code': 'Ok',
            'routes': [
              {
                'distance': 1000.0,
                'duration': 600.0,
                'geometry': {
                  'coordinates': [
                    for (final coordinate in coordinates)
                      [
                        double.parse(coordinate.split(',')[0]),
                        double.parse(coordinate.split(',')[1]),
                      ],
                  ],
                },
              },
            ],
            'waypoints': [
              for (final coordinate in coordinates)
                {
                  'location': [
                    double.parse(coordinate.split(',')[0]),
                    double.parse(coordinate.split(',')[1]),
                  ],
                },
            ],
          };
          return http.Response(jsonEncode(payload), 200);
        }),
        maxRetries: 0,
      );
      addTearDown(engine.dispose);

      final points = [
        for (var i = 0; i < 20; i++)
          GeoPoint(latitude: 45 + i * 0.001, longitude: 11 + i * 0.001),
      ];
      final plan = await engine.calculate(
        RouteRequest(points: points, profile: RouteProfile.hiking),
      );

      expect(requests, greaterThan(1));
      expect(plan.snappedWaypoints, hasLength(20));
      expect(plan.isSnapped, isTrue);
    },
  );

  test(
    'honors numeric Retry-After for rate limiting before retrying',
    () async {
      var requests = 0;
      final delays = <Duration>[];
      final client = MockClient((request) async {
        requests++;
        if (requests == 1) {
          return http.Response(
            'rate limited',
            429,
            headers: {'retry-after': '2'},
          );
        }
        return http.Response(jsonEncode(_successPayload()), 200);
      });
      final engine = OpenStreetMapRoutingEngine(
        client: client,
        maxRetries: 1,
        maxRetryDelay: const Duration(seconds: 4),
        delay: (duration) async => delays.add(duration),
      );
      addTearDown(engine.dispose);

      await engine.calculate(_request());

      expect(requests, 2);
      expect(delays, [const Duration(seconds: 2)]);
    },
  );

  test('honors HTTP-date Retry-After before retrying', () async {
    var requests = 0;
    final delays = <Duration>[];
    final client = MockClient((request) async {
      requests++;
      if (requests == 1) {
        return http.Response(
          'rate limited',
          429,
          headers: {'retry-after': 'Thu, 24 Sep 2026 14:00:00 GMT'},
        );
      }
      return http.Response(jsonEncode(_successPayload()), 200);
    });
    final engine = OpenStreetMapRoutingEngine(
      client: client,
      maxRetries: 1,
      maxRetryDelay: const Duration(seconds: 4),
      delay: (duration) async => delays.add(duration),
      clock: () => DateTime.utc(2026, 9, 24, 13, 59, 58),
    );
    addTearDown(engine.dispose);

    await engine.calculate(_request());

    expect(requests, 2);
    expect(delays, [const Duration(seconds: 2)]);
  });

  test('does not retry non-transient HTTP failures', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response('bad request', 400);
    });
    final engine = OpenStreetMapRoutingEngine(
      client: client,
      maxRetries: 3,
      delay: (_) async {},
    );
    addTearDown(engine.dispose);

    await expectLater(
      engine.calculate(_request()),
      throwsA(
        isA<RoutingException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 400'),
        ),
      ),
    );
    expect(requests, 1);
  });

  test('rejects incomplete provider waypoint snapping', () async {
    final payload = _successPayload()
      ..['waypoints'] = [
        {
          'location': [11.0, 45.0],
        },
      ];
    final engine = OpenStreetMapRoutingEngine(
      client: MockClient(
        (request) async => http.Response(jsonEncode(payload), 200),
      ),
      maxRetries: 0,
    );
    addTearDown(engine.dispose);

    await expectLater(
      engine.calculate(_request()),
      throwsA(
        isA<RoutingException>().having(
          (error) => error.message,
          'message',
          contains('Waypoint snapping is incomplete'),
        ),
      ),
    );
  });
}

RouteRequest _request() {
  return const RouteRequest(
    points: [
      GeoPoint(latitude: 45.0, longitude: 11.0),
      GeoPoint(latitude: 45.01, longitude: 11.01),
    ],
    profile: RouteProfile.hiking,
  );
}

Map<String, dynamic> _successPayload() {
  return {
    'code': 'Ok',
    'routes': [
      {
        'distance': 1250.0,
        'duration': 900.0,
        'geometry': {
          'coordinates': [
            [11.0, 45.0],
            [11.005, 45.005],
            [11.01, 45.01],
          ],
        },
      },
    ],
    'waypoints': [
      {
        'location': [11.0, 45.0],
      },
      {
        'location': [11.01, 45.01],
      },
    ],
  };
}
