import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/location/application/location_controller.dart';

void main() {
  test('location controller becomes ready and receives live samples', () async {
    final engine = _FakeLocationEngine(
      permission: LocationPermissionState.whileInUse,
      serviceEnabled: true,
    );
    final container = ProviderContainer(
      overrides: [locationEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);
    addTearDown(engine.dispose);

    container.read(locationControllerProvider);
    await _settle();

    expect(
      container.read(locationControllerProvider).status,
      LocationUiStatus.ready,
    );

    engine.emit(
      const PositionSample(
        point: GeoPoint(latitude: 45.4, longitude: 11.8),
        accuracyMeters: 6,
        headingDegrees: 90,
      ),
    );
    await _settle();

    final state = container.read(locationControllerProvider);
    expect(state.sample?.point.latitude, 45.4);
    expect(state.sample?.headingDegrees, 90);
  });

  test('location controller exposes denied permission state', () async {
    final engine = _FakeLocationEngine(
      permission: LocationPermissionState.denied,
      serviceEnabled: true,
    );
    final container = ProviderContainer(
      overrides: [locationEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);
    addTearDown(engine.dispose);

    container.read(locationControllerProvider);
    await _settle();

    expect(
      container.read(locationControllerProvider).status,
      LocationUiStatus.permissionDenied,
    );
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 30));
}

class _FakeLocationEngine implements LocationEngine {
  _FakeLocationEngine({
    required this.permission,
    required this.serviceEnabled,
  });

  LocationPermissionState permission;
  bool serviceEnabled;

  final _positions = StreamController<PositionSample>.broadcast();
  final _services = StreamController<bool>.broadcast();

  void emit(PositionSample sample) => _positions.add(sample);

  void dispose() {
    _positions.close();
    _services.close();
  }

  @override
  Future<PositionSample?> current() async => const PositionSample(
    point: GeoPoint(latitude: 45.0, longitude: 11.0),
    accuracyMeters: 8,
  );

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationPermissionState> permissionStatus() async => permission;

  @override
  Future<LocationPermissionState> requestPermission() async => permission;

  @override
  Stream<bool> serviceStatus() => _services.stream;

  @override
  Stream<PositionSample> watch() => _positions.stream;
}
