import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planner keeps the map primary and confirms candidate points', () {
    final source = File('lib/features/planner/presentation/planner_screen.dart')
        .readAsStringSync();
    final candidateCard = File(
      'lib/features/planner/presentation/candidate_selection_card.dart',
    ).readAsStringSync();

    expect(source, contains('GeoPoint? _candidatePoint'));
    expect(source, contains('_previewCandidateLatLng'));
    expect(source, contains('_confirmCandidate(_CandidateIntent intent)'));
    expect(source, contains('CandidateSelectionCard('));
    expect(candidateCard, contains('class CandidateSelectionCard'));
    expect(source, contains('class _DestinationPromptBar'));
    expect(source, contains('class _RouteSummaryBar'));
    expect(source, contains('DraggableScrollableSheet'));
    expect(source, contains('if (_candidatePoint != null)'));
    expect(source, contains('else if (planner.points.length == 1)'));
    expect(source, contains('else if (planner.points.length >= 2)'));
    expect(source, contains('_schedulePlannerAnnotationSync'));
    expect(source, isNot(contains('_addWaypoint(coordinates)')));
  });
}
