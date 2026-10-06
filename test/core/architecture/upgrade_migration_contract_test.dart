import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upgrade gate uses a real previous release artifact', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final runner = File('.maestro/run-upgrade-migration.sh').readAsStringSync();
    final seed = File('.maestro/upgrade-seed-v1511.yaml').readAsStringSync();
    final verify = File('.maestro/upgrade-verify-v1513.yaml')
        .readAsStringSync();

    expect(workflow, contains('TrailPath Upgrade / Migration AppLab'));
    expect(workflow, contains('11021533532'));
    expect(runner, contains('36544385449'));
    expect(workflow, contains('upgrade-migration-report'));

    expect(runner, contains('adb install -r'));
    expect(runner, contains('versionName=1.5.11'));
    expect(runner, contains('EXPECTED_NEW_VERSION'));
    expect(runner, contains('EXPECTED_NEW_CODE'));
    expect(runner, contains('Baseline bootstrap artifact ID: 11021533532'));

    expect(seed, contains('clearState: false'));
    expect(runner, contains('adb shell pm clear'));
    expect(runner, contains('expected_new_version'));
    expect(runner, contains('diagnostics.txt'));
    expect(seed, contains('Upgrade Activity'));
    expect(seed, contains('Upgrade Route'));
    expect(seed, contains('.*(Metric|Metriche|Métricas|Métriques).*'));
    expect(seed, contains('Imperial'));
    expect(runner, contains('trailpath_prepare_maestro_attempt'));
    expect(runner, isNot(contains('FOREIGN_ANR_GUARD_PID')));
    expect(seed, contains('Available offline'));

    expect(verify, contains('clearState: false'));
    expect(verify, contains('Upgrade Activity'));
    expect(verify, contains('Upgrade Route'));
    expect(verify, contains('.*(Imperial|Imperiali|Imperiales|Impériales|Imperiais).*'));
    expect(verify, contains('Imperial'));
    expect(verify, contains('Available offline'));
  });
}
