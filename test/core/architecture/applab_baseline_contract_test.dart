import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main AppLab gate persists pass-only visual and performance baselines', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();

    expect(workflow, contains('Restore AppLab visual baseline'));
    expect(workflow, contains('Restore AppLab performance baseline'));
    expect(workflow, contains('APPLAB_VISUAL_BASELINE_DIR'));
    expect(workflow, contains('APPLAB_PERFORMANCE_BASELINE_JSON'));
    expect(workflow, contains('prepare_visual_baseline.py'));
    expect(workflow, contains('prepare_performance_baseline.py'));
    expect(workflow, contains('Save PASS-only AppLab visual baseline'));
    expect(workflow, contains('Save PASS-only AppLab performance baseline'));
    expect(
      workflow,
      contains('trailpath-applab-visual-v2-main-e2e-'),
    );
    expect(
      workflow,
      contains('trailpath-applab-performance-v1-main-e2e-'),
    );
  });
}
