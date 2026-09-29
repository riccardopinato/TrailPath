import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.5.13 upgrade gate uses a real previous release artifact', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final runner = File(
      '.maestro/run-upgrade-migration.sh',
    ).readAsStringSync();
    final seed = File('.maestro/upgrade-seed-v1511.yaml').readAsStringSync();
    final verify = File(
      '.maestro/upgrade-verify-v1513.yaml',
    ).readAsStringSync();

    expect(workflow, contains('TrailPath Upgrade / Migration AppLab'));
    expect(workflow, contains('11021533532'));
    expect(workflow, contains('36544385449'));
    expect(workflow, contains('upgrade-migration-report'));

    expect(runner, contains('adb install -r'));
    expect(runner, contains('versionName=1.5.11'));
    expect(runner, contains('versionName=1.5.13'));
    expect(runner, contains('Baseline artifact ID: 11021533532'));

    expect(seed, contains('clearState: true'));
    expect(seed, contains('Upgrade Activity'));
    expect(seed, contains('Upgrade Route'));
    expect(seed, contains('Imperial \\(mi, ft\\)'));
    expect(seed, contains('Available offline'));

    expect(verify, contains('clearState: false'));
    expect(verify, contains('Upgrade Activity'));
    expect(verify, contains('Upgrade Route'));
    expect(verify, contains('Imperial \\(mi, ft\\)'));
    expect(verify, contains('Available offline'));
  });
}
