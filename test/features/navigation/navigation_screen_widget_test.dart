import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/navigation/presentation/navigation_screen.dart';

void main() {
  testWidgets('navigation starts after localization dependencies are ready',
      (tester) async {
    final database = AppDatabase.memory();
    final engine = _FakeNavigationEngine();
    addTearDown(database.close);
    addTearDown(engine.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          navigationEngineProvider.overrideWithValue(engine),
          navigationFeedbackProvider.overrideWithValue(
            const _SilentNavigationFeedback(),
          ),
        ],
        child: MaterialApp(
          home: NavigationScreen(
            routeName: 'Test route',
            route: RoutePlan(
              geometry: const [
                GeoPoint(latitude: 45.0, longitude: 11.0),
                GeoPoint(latitude: 45.01, longitude: 11.01),
              ],
              distanceMeters: 1500,
              ascentMeters: 40,
              descentMeters: 20,
              estimatedDuration: const Duration(minutes: 20),
              profile: RouteProfile.hiking,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Test route'), findsOneWidget);
    expect(engine.started, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _FakeNavigationEngine implements NavigationEngine {
  final StreamController<NavigationEvent> _controller =
      StreamController<NavigationEvent>.broadcast();

  bool started = false;

  @override
  Stream<NavigationEvent> get events => _controller.stream;

  @override
  Future<void> start(
    RoutePlan route, {
    BatteryMode mode = BatteryMode.balanced,
  }) async {
    started = true;
    _controller.add(
      NavigationEvent(
        type: NavigationEventType.started,
        routeDistanceMeters: route.distanceMeters,
        remainingMeters: route.distanceMeters,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (!_controller.isClosed) {
      _controller.add(
        const NavigationEvent(type: NavigationEventType.stopped),
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _SilentNavigationFeedback implements NavigationFeedback {
  const _SilentNavigationFeedback();

  @override
  Future<void> alert() async {}

  @override
  Future<void> configure(String languageCode) async {}

  @override
  Future<void> speak(String message) async {}

  @override
  Future<void> stop() async {}
}
