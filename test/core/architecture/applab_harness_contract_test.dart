import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLab blocking harnesses execute atomically and certification fails closed', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final mainFlow = File('.maestro/applab-e2e.yaml').readAsStringSync();
    final proRunner = File('.maestro/run-applab-v15-pro.sh').readAsStringSync();
    final uxRunner = File('.maestro/run-applab-ux-matrix.sh')
        .readAsStringSync();
    final helper = File('.maestro/ci_runtime_helpers.sh').readAsStringSync();
    final resourcePolicy = File('.maestro/applab-resource.json')
        .readAsStringSync();
    final configurationPolicy = File('.maestro/applab-configuration.json')
        .readAsStringSync();
    final migrationSeed = File('.maestro/upgrade-seed-v1511.yaml')
        .readAsStringSync();
    final migrationVerify = File('.maestro/upgrade-verify-v1513.yaml')
        .readAsStringSync();

    expect(
      workflow,
      contains(
        'script: bash "\$GITHUB_WORKSPACE/.maestro/run-applab-v15-pro.sh"',
      ),
    );
    expect(
      workflow,
      contains(
        'script: bash "\$GITHUB_WORKSPACE/.maestro/run-applab-ux-matrix.sh"',
      ),
    );
    expect(
      workflow,
      isNot(contains('bash "\$GITHUB_WORKSPACE/.maestro/run-offline-e2e.sh"')),
    );
    expect(
      workflow,
      contains('APPLAB_PROJECT_ROOT="\$GITHUB_WORKSPACE" RUN_MAESTRO=true'),
    );
    expect(workflow, contains('name: Enforce automated certification result'));
    expect(workflow, contains('test "\$failed" -eq 0'));

    expect(mainFlow, contains('- setAirplaneMode: enabled'));
    expect(mainFlow, contains('- setAirplaneMode: disabled'));
    expect(mainFlow, contains('.*Available offline.*'));

    expect(helper, contains('MaestroDriverStartupException'));
    expect(helper, contains('AndroidDriverTimeoutException'));
    expect(helper, contains('DeadSystemException'));
    expect(helper, contains('DeviceServerDiedException'));
    expect(helper, contains('StatusRuntimeException: UNAVAILABLE'));
    expect(helper, contains('UiAutomationService.*already registered'));
    expect(helper, contains('Bad file descriptor'));
    expect(helper, contains('dev.mobile.maestro'));
    expect(helper, contains('adb kill-server'));
    expect(helper, contains('adb start-server'));
    expect(helper, contains('adb forward --remove-all'));
    expect(proRunner, contains('MAX_INFRA_ATTEMPTS=3'));
    expect(proRunner, contains('trailpath_maestro_failure_is_transient'));
    expect(uxRunner, contains('MAX_INFRA_ATTEMPTS=3'));
    expect(uxRunner, contains('trailpath_maestro_failure_is_transient'));
    expect(
      uxRunner,
      contains('Runtime recovery did not fully settle; next Maestro attempt'),
    );

    expect(resourcePolicy, contains('"trim_levels": ["RUNNING_LOW"]'));
    expect(resourcePolicy, contains('"settle_seconds": 5.0'));
    expect(resourcePolicy, contains('"process_death_cycles": 1'));
    expect(configurationPolicy, contains('"rotation_cycles": 1'));
    expect(configurationPolicy, contains('"background_cycles": 1'));
    expect(configurationPolicy, contains('"settle_seconds": 5.0'));

    expect(uxRunner, contains('adb shell wm size 720x1280'));
    expect(uxRunner, contains('adb shell wm density 320'));
    expect(uxRunner, isNot(contains('adb shell wm size 360x640')));

    expect(
      migrationSeed,
      contains(
        'text: ".*(Settings|Impostazioni|Ajustes|Réglages|Definições).*"',
      ),
    );
    expect(
      migrationVerify,
      contains(
        'text: ".*(Settings|Impostazioni|Ajustes|Réglages|Definições).*"',
      ),
    );
    expect(migrationSeed, contains("(?s).*(Units|Unità|Unidades|Unités)"));
    expect(migrationSeed, contains("Metriche \\(km, m\\)"));
    expect(migrationSeed, contains("Impériales \\(mi, ft\\)"));
    expect(migrationVerify, contains("(?s).*(Units|Unità|Unidades|Unités)"));
    expect(migrationVerify, contains("Imperiais \\(mi, ft\\)"));
  });
}
