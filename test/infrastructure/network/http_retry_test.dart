import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/infrastructure/network/http_retry.dart';

void main() {
  test('parses standard HTTP-date Retry-After values', () {
    final delay = retryAfterDelay(
      'Thu, 24 Sep 2026 14:00:00 GMT',
      now: DateTime.utc(2026, 9, 24, 13, 59, 57),
      maxDelay: const Duration(seconds: 10),
    );

    expect(delay, const Duration(seconds: 3));
  });

  test('caps Retry-After and exponential backoff', () {
    expect(
      retryAfterDelay(
        '30',
        now: DateTime.utc(2026, 9, 24),
        maxDelay: const Duration(seconds: 4),
      ),
      const Duration(seconds: 4),
    );
    expect(
      exponentialBackoff(
        attempt: 4,
        baseDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(seconds: 4),
      ),
      const Duration(seconds: 4),
    );
  });

  test('rejects malformed HTTP-date values', () {
    expect(tryParseHttpDate('not-a-date'), isNull);
    expect(
      tryParseHttpDate('Thu, 31 Sep 2026 14:00:00 GMT'),
      isNull,
    );
  });
}
