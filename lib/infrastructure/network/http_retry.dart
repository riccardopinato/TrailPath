typedef NetworkDelay = Future<void> Function(Duration duration);
typedef NetworkClock = DateTime Function();

Future<void> defaultNetworkDelay(Duration duration) =>
    Future<void>.delayed(duration);

bool isTransientHttpStatus(int statusCode) {
  return statusCode == 408 ||
      statusCode == 425 ||
      statusCode == 429 ||
      statusCode == 500 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;
}

Duration exponentialBackoff({
  required int attempt,
  required Duration baseDelay,
  required Duration maxDelay,
}) {
  final boundedAttempt = attempt < 0
      ? 0
      : attempt > 8
          ? 8
          : attempt;
  final multiplier = 1 << boundedAttempt;
  return capNetworkDelay(
    Duration(milliseconds: baseDelay.inMilliseconds * multiplier),
    maxDelay,
  );
}

Duration? retryAfterDelay(
  String? value, {
  required DateTime now,
  required Duration maxDelay,
}) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final seconds = int.tryParse(normalized);
  if (seconds != null && seconds >= 0) {
    return capNetworkDelay(Duration(seconds: seconds), maxDelay);
  }

  final date = tryParseHttpDate(normalized);
  if (date == null) {
    return null;
  }

  final remaining = date.difference(now.toUtc());
  if (remaining.isNegative) {
    return Duration.zero;
  }
  return capNetworkDelay(remaining, maxDelay);
}

Duration capNetworkDelay(Duration value, Duration maxDelay) {
  if (value > maxDelay) {
    return maxDelay;
  }
  if (value.isNegative) {
    return Duration.zero;
  }
  return value;
}

DateTime? tryParseHttpDate(String value) {
  final iso = DateTime.tryParse(value);
  if (iso != null) {
    return iso.toUtc();
  }

  final match = RegExp(
    r'^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),\\s*(\\d{2})\\s+'
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+'
    r'(\\d{4})\\s+(\\d{2}):(\\d{2}):(\\d{2})\\s+GMT$',
    caseSensitive: false,
  ).firstMatch(value.trim());

  if (match == null) {
    return null;
  }

  const months = <String, int>{
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  final day = int.tryParse(match.group(1)!);
  final month = months[match.group(2)!.toLowerCase()];
  final year = int.tryParse(match.group(3)!);
  final hour = int.tryParse(match.group(4)!);
  final minute = int.tryParse(match.group(5)!);
  final second = int.tryParse(match.group(6)!);

  if (day == null ||
      month == null ||
      year == null ||
      hour == null ||
      minute == null ||
      second == null) {
    return null;
  }

  final parsed = DateTime.utc(year, month, day, hour, minute, second);
  if (parsed.year != year ||
      parsed.month != month ||
      parsed.day != day ||
      parsed.hour != hour ||
      parsed.minute != minute ||
      parsed.second != second) {
    return null;
  }

  return parsed;
}
