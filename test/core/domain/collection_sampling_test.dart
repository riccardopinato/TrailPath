import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/collection_sampling.dart';

void main() {
  test('sampleEvenly preserves endpoints and maximum count', () {
    final values = List<int>.generate(100, (index) => index);

    final sampled = sampleEvenly(values, maxItems: 10);

    expect(sampled, hasLength(10));
    expect(sampled.first, 0);
    expect(sampled.last, 99);
    expect(sampled.toSet(), hasLength(sampled.length));
  });

  test('sampleEvenly leaves short lists unchanged', () {
    final sampled = sampleEvenly([1, 2, 3], maxItems: 5);

    expect(sampled, [1, 2, 3]);
  });

  test('sampleEvenly rejects invalid limits', () {
    expect(() => sampleEvenly([1, 2, 3], maxItems: 1), throwsArgumentError);
  });
}
