import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/app/app.dart';\nimport 'package:trail_path/features/planner/presentation/planner_screen.dart';

void main() {
  testWidgets('TrailPath foundation boots into planner shell', (tester) async {
    await tester.pumpWidget(\n      ProviderScope(\n        overrides: [mapRenderingEnabledProvider.overrideWithValue(false)],\n        child: const TrailPathApp(),\n      ),\n    );
    await tester.pumpAndSettle();

    expect(find.text('TrailPath'), findsOneWidget);
    expect(find.text('0.0 km'), findsOneWidget);
  });
}
