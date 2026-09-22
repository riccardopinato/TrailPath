import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/app/app.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/planner/presentation/planner_screen.dart';

void main() {
  testWidgets('TrailPath v0.2 boots into planner shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapRenderingEnabledProvider.overrideWithValue(false),
          locationEngineProvider.overrideWithValue(
            const _WidgetTestLocationEngine(),
          ),
        ],
        child: const TrailPathApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TrailPath'), findsOneWidget);
    expect(find.text('0.0 km'), findsOneWidget);
    expect(find.text('v0.2'), findsOneWidget);
  });
}

class _WidgetTestLocationEngine implements LocationEngine {
  const _WidgetTestLocationEngine();

  @override
  Future<PositionSample?> current() async => null;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationPermissionState> permissionStatus() async =>
      LocationPermissionState.denied;

  @override
  Future<LocationPermissionState> requestPermission() async =>
      LocationPermissionState.denied;

  @override
  Stream<bool> serviceStatus() => const Stream<bool>.empty();

  @override
  Stream<PositionSample> watch() => const Stream<PositionSample>.empty();
}
