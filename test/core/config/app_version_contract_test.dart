import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MapConfig appVersion matches the pubspec semantic version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final mapConfig = File('lib/core/config/map_config.dart')
        .readAsStringSync();

    final pubspecMatch = RegExp(
      r'^version:\s*([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    final configMatch = RegExp(r"appVersion\s*=\s*'([^']+)'")
        .firstMatch(mapConfig);

    expect(pubspecMatch, isNotNull);
    expect(configMatch, isNotNull);
    expect(configMatch!.group(1), pubspecMatch!.group(1));
  });
}
