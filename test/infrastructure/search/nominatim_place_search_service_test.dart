import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trail_path/infrastructure/search/nominatim_place_search_service.dart';

void main() {
  test('decodes valid Nominatim search results', () {
    const body = '''
[
  {
    "lat": "45.2320",
    "lon": "11.7500",
    "name": "Monselice",
    "display_name": "Monselice, Padova, Veneto, Italia"
  }
]
''';

    final results = decodeNominatimSearchResults(body);

    expect(results, hasLength(1));
    expect(results.single.name, 'Monselice');
    expect(results.single.displayName, contains('Padova'));
    expect(results.single.point.latitude, closeTo(45.232, 0.000001));
    expect(results.single.point.longitude, closeTo(11.75, 0.000001));
  });

  test('ignores malformed coordinates', () {
    const body = '''
[
  {
    "lat": "not-a-number",
    "lon": "11.7500",
    "display_name": "Broken result"
  },
  {
    "lat": "95",
    "lon": "11.7500",
    "display_name": "Outside earth"
  }
]
''';

    expect(decodeNominatimSearchResults(body), isEmpty);
  });

  test('reuses cached results without issuing a second HTTP request', () async {
    var requests = 0;
    final service = NominatimPlaceSearchService(
      client: MockClient((request) async {
        requests++;
        return http.Response(_validBody, 200);
      }),
      minimumRequestGap: Duration.zero,
    );
    addTearDown(service.dispose);

    final first = await service.search('Monselice', languageCode: 'it');
    final second = await service.search('Monselice', languageCode: 'it');

    expect(first, hasLength(1));
    expect(second, same(first));
    expect(requests, 1);
  });

  test('serializes uncached searches and enforces the request gap', () async {
    var now = DateTime.utc(2026, 9, 24, 12);
    final delays = <Duration>[];
    final requestedQueries = <String>[];

    final service = NominatimPlaceSearchService(
      client: MockClient((request) async {
        requestedQueries.add(request.url.queryParameters['q'] ?? '');
        return http.Response(_validBody, 200);
      }),
      delay: (duration) async {
        delays.add(duration);
        now = now.add(duration);
      },
      clock: () => now,
    );
    addTearDown(service.dispose);

    await Future.wait([
      service.search('Monselice', languageCode: 'it'),
      service.search('Padova', languageCode: 'it'),
    ]);

    expect(requestedQueries, ['Monselice', 'Padova']);
    expect(delays, [const Duration(seconds: 1)]);
  });
  test('retries transient search failures and then succeeds', () async {
    var requests = 0;
    final delays = <Duration>[];
    final service = NominatimPlaceSearchService(
      client: MockClient((request) async {
        requests++;
        if (requests < 3) {
          return http.Response('busy', 503);
        }
        return http.Response(_validBody, 200);
      }),
      minimumRequestGap: Duration.zero,
      retryBaseDelay: const Duration(milliseconds: 10),
      maxRetryDelay: const Duration(milliseconds: 40),
      delay: (duration) async => delays.add(duration),
    );
    addTearDown(service.dispose);

    final results = await service.search('Monselice', languageCode: 'it');

    expect(results, hasLength(1));
    expect(requests, 3);
    expect(delays, [
      const Duration(milliseconds: 10),
      const Duration(milliseconds: 20),
    ]);
  });

  test('does not retry permanent search failures', () async {
    var requests = 0;
    final service = NominatimPlaceSearchService(
      client: MockClient((request) async {
        requests++;
        return http.Response('bad request', 400);
      }),
      minimumRequestGap: Duration.zero,
      delay: (_) async {},
    );
    addTearDown(service.dispose);

    await expectLater(
      service.search('Monselice', languageCode: 'it'),
      throwsA(isA<PlaceSearchException>()),
    );
    expect(requests, 1);
  });
}

const _validBody = '''
[
  {
    "lat": "45.2320",
    "lon": "11.7500",
    "name": "Monselice",
    "display_name": "Monselice, Padova, Veneto, Italia"
  }
]
''';
