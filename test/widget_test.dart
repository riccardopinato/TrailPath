import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/app/app.dart';

void main() {
  testWidgets('TrailPath foundation boots into planner shell', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TrailPathApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TrailPath'), findsOneWidget);
    expect(find.text('0.0 km'), findsOneWidget);
  });
}
