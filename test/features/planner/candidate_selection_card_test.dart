import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/planner/presentation/candidate_selection_card.dart';

void main() {
  const strings = AppLocalizations(Locale('en'));
  const point = GeoPoint(latitude: 45.232, longitude: 11.75);

  testWidgets('candidate card protects destination until a start exists', (
    tester,
  ) async {
    var starts = 0;
    var destinations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CandidateSelectionCard(
            strings: strings,
            point: point,
            label: 'Test point',
            canUseCurrentLocation: false,
            pointCount: 0,
            onStart: () => starts++,
            onDestination: () => destinations++,
            onWaypoint: () {},
            onCancel: () {},
          ),
        ),
      ),
    );

    final destination = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, strings.setDestination),
    );
    expect(destination.onPressed, isNull);
    expect(find.text(strings.addWaypoint), findsNothing);

    await tester.tap(find.text(strings.startHere));
    await tester.pump();

    expect(starts, 1);
    expect(destinations, 0);
  });

  testWidgets('candidate card exposes waypoint and destination actions', (
    tester,
  ) async {
    var waypoints = 0;
    var destinations = 0;
    var cancelled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CandidateSelectionCard(
            strings: strings,
            point: point,
            label: null,
            canUseCurrentLocation: false,
            pointCount: 2,
            onStart: () {},
            onDestination: () => destinations++,
            onWaypoint: () => waypoints++,
            onCancel: () => cancelled++,
          ),
        ),
      ),
    );

    await tester.tap(find.text(strings.addWaypoint));
    await tester.tap(find.text(strings.setDestination));
    await tester.tap(find.byTooltip(strings.cancel));
    await tester.pump();

    expect(waypoints, 1);
    expect(destinations, 1);
    expect(cancelled, 1);
  });

  testWidgets('candidate card remains usable on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: CandidateSelectionCard(
              strings: strings,
              point: point,
              label: 'A long candidate label that must not overflow',
              canUseCurrentLocation: true,
              pointCount: 2,
              onStart: () {},
              onDestination: () {},
              onWaypoint: () {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(strings.startHere), findsOneWidget);
    expect(find.text(strings.addWaypoint), findsOneWidget);
    expect(find.text(strings.setDestination), findsOneWidget);
  });
}
