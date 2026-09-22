import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/app/app.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';

void main() {
  testWidgets('TrailPath boots into interactive planner shell', (tester) async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const TrailPathApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('TrailPath'), findsOneWidget);
    expect(find.text('0 m'), findsOneWidget);
    expect(find.text('v0.5.0'), findsOneWidget);
  });
}
