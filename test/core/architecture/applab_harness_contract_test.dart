import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLab blocking harnesses execute atomically and certification fails closed', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final migrationSeed = File(
      '.maestro/upgrade-seed-v1511.yaml',
    ).readAsStringSync();
    final migrationVerify = File(
      '.maestro/upgrade-verify-v1513.yaml',
    ).readAsStringSync();

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
      contains('name: Enforce automated certification result'),
    );
    expect(
      workflow,
      contains('test "\$failed" -eq 0'),
    );

    expect(
      migrationSeed,
      contains("text: 'Metric \\(km, m\\)'"),
    );
    expect(
      migrationSeed,
      contains("text: 'Imperial \\(mi, ft\\)'"),
    );
    expect(
      migrationVerify,
      contains("text: 'Imperial \\(mi, ft\\)'"),
    );
  });
}
