import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planner custom map actions keep release accessibility contract', () {
    final source = File(
      'lib/features/planner/presentation/planner_screen.dart',
    ).readAsStringSync();

    expect(source, contains('class _MapActionButton'));
    expect(source, contains('Semantics('));
    expect(source, contains('button: true'));
    expect(source, contains('label: tooltip'));
    expect(source, contains('enabled: onTap != null'));
    expect(source, contains('selected: active'));
    expect(source, contains('Tooltip('));
    expect(source, contains('message: tooltip'));
    expect(source, contains('width: 48'));
    expect(source, contains('height: 48'));

    expect(
      source,
      contains('liveRegion: planner.isRouting || planner.hasRoutingError'),
    );
    expect(source, contains('class _TraceStatusChip'));
    expect(source, contains('liveRegion: true'));
  });
}
