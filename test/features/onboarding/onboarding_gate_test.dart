import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/localization/app_localizations.dart';
import 'package:trail_path/features/onboarding/presentation/onboarding_gate.dart';

void main() {
  testWidgets(
    'small-screen large-text keeps onboarding CTA inside the viewport',
    (tester) async {
      final database = AppDatabase.memory();
      addTearDown(database.close);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const OnboardingGate(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final startButton = find.byKey(const ValueKey('onboarding_start'));
      expect(startButton, findsOneWidget);
      final rect = tester.getRect(startButton);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(640));
      expect(find.text('Start TrailPath'), findsOneWidget);
    },
  );

  testWidgets('first launch persists onboarding completion', (tester) async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const OnboardingGate(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Before you head out'), findsOneWidget);
    expect(find.text('Start TrailPath'), findsOneWidget);
    expect(await database.getSetting(onboardingCompletedSettingKey), isNull);

    final startButton = find.byKey(const ValueKey('onboarding_start'));
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(await database.getSetting(onboardingCompletedSettingKey), 'true');
    expect(find.text('Search place or trail'), findsOneWidget);
    expect(find.text('Start TrailPath'), findsNothing);
  });
}
