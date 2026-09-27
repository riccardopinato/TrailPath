import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planner suspends UI-only GPS tracking outside foreground', () {
    final source = File('lib/features/planner/presentation/planner_screen.dart')
        .readAsStringSync();

    expect(source, contains('with WidgetsBindingObserver'));
    expect(source, contains('WidgetsBinding.instance.addObserver(this)'));
    expect(source, contains('WidgetsBinding.instance.removeObserver(this)'));
    expect(source, contains('didChangeAppLifecycleState'));
    expect(source, contains('state == AppLifecycleState.resumed'));
    expect(source, contains('unawaited(_stopPositionWatch())'));
    expect(source, contains('unawaited(_startPositionWatch())'));
    expect(source, contains('if (!mounted || !_appInForeground)'));
    expect(source, contains('await subscription?.cancel()'));
  });
}
