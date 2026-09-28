import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.5 Pro QA has dedicated x86 AppLab coverage', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final flow = File('.maestro/applab-v15-pro-e2e.yaml').readAsStringSync();

    expect(workflow, contains('Build x86_64 internal Pro QA release'));
    expect(workflow, contains('AppLab v1.5 Pro Routing Gate'));
    expect(workflow, contains('TRAILPATH_INTERNAL_PRO=true'));
    expect(flow, contains('Route Lab'));
    expect(flow, contains('Generate routes'));
    expect(flow, contains('Follow roads'));
    expect(flow, contains('- swipe:'));
    expect(flow, contains('Close loop'));
  });

  test('main AppLab flow accepts localized Outdoor labels', () {
    final flow = File('.maestro/applab-e2e.yaml').readAsStringSync();
    expect(flow, contains('Strumenti Outdoor'));
    expect(flow, contains('Herramientas Outdoor'));
    expect(flow, contains('Outils Outdoor'));
    expect(flow, contains('Ferramentas Outdoor'));
    expect(flow, contains('visibilityPercentage: 60'));
  });
}
