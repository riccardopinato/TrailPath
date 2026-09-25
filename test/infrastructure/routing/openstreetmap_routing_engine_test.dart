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
