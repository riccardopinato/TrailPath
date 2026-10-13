import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec remains the only semantic version source', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final mapConfig = File('lib/core/config/map_config.dart')
        .readAsStringSync();

    final versionLine = pubspec
        .split('\n')
        .firstWhere((line) => line.startsWith('version: '));

    expect(versionLine, matches(RegExp(r'^version: \d+\.\d+\.\d+\+\d+$')));
    expect(mapConfig, isNot(contains('appVersion')));
    expect(mapConfig, contains("TrailPath (+\$projectUrl)"));
  });
}
