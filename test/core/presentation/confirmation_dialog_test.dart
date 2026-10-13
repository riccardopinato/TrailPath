import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/presentation/confirmation_dialog.dart';

void main() {
  testWidgets('destructive confirmation returns false when cancelled', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showTrailPathConfirmationDialog(
                  context: context,
                  title: 'Delete route?',
                  message: 'Route A',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete route?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('destructive confirmation returns true when confirmed', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showTrailPathConfirmationDialog(
                  context: context,
                  title: 'Delete route?',
                  message: 'Route A',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
