import 'package:flutter_test/flutter_test.dart';
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
}
