import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/battery_policy.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/recording/application/recording_controller.dart';

void main() {
  test('recording creates autosaved draft and completes activity', () async {
    final database = AppDatabase.memory();
    final recorder = _FakeTrackRecorder();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        trackRecorderProvider.overrideWithValue(recorder),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await recorder.dispose();
      await database.close();
    });

    final controller = container.read(recordingControllerProvider.notifier);
    await controller.start();

    recorder.emit(
      const TrackRecorderSnapshot(
        status: TrackRecorderStatus.recording,
        points: [
          GeoPoint(latitude: 45, longitude: 11, elevationMeters: 100),
          GeoPoint(latitude: 45.001, longitude: 11.001, elevationMeters: 110),
          GeoPoint(latitude: 45.002, longitude: 11.002, elevationMeters: 112),
        ],
        distanceMeters: 140,
        ascentMeters: 10,
        elapsed: Duration(minutes: 2),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final draft = await database.latestRecoverableActivity();
    expect(draft, isNotNull);
    expect(draft!.distanceMeters, 140);
    expect(draft.ascentMeters, 10);

    final saved = await controller.finish('Morning trail');
    expect(saved, isTrue);
    expect(await database.latestRecoverableActivity(), isNull);

    final completed = await database.watchCompletedActivities().first;
    expect(completed, hasLength(1));
    expect(completed.first.name, 'Morning trail');
    expect(completed.first.movingSeconds, 120);
  });

  test('recording draft is restored paused after restart', () async {
    final database = AppDatabase.memory();
    final id = await database.createActivityDraft(
      profile: RouteProfile.trailRunning,
    );
    await database.updateActivityDraft(
      activityId: id,
      snapshot: const TrackRecorderSnapshot(
        status: TrackRecorderStatus.paused,
        points: [
          GeoPoint(latitude: 45, longitude: 11),
          GeoPoint(latitude: 45.002, longitude: 11.002),
        ],
        distanceMeters: 280,
        ascentMeters: 18,
        elapsed: Duration(minutes: 3),
      ),
    );

    final recorder = _FakeTrackRecorder();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        trackRecorderProvider.overrideWithValue(recorder),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await recorder.dispose();
      await database.close();
    });

    final controller = container.read(recordingControllerProvider.notifier);
    await controller.checkRecovery();

    final state = container.read(recordingControllerProvider);
    expect(state.hasRecoveredDraft, isTrue);
    expect(state.activityId, id);
    expect(state.profile, RouteProfile.trailRunning);
    expect(state.snapshot.status, TrackRecorderStatus.paused);
    expect(state.snapshot.points, hasLength(2));
    expect(state.snapshot.distanceMeters, 280);

    await controller.resume();
    expect(
      container.read(recordingControllerProvider).snapshot.status,
      TrackRecorderStatus.recording,
    );
  });

  test('discard removes recoverable draft', () async {
    final database = AppDatabase.memory();
    final recorder = _FakeTrackRecorder();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        trackRecorderProvider.overrideWithValue(recorder),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await recorder.dispose();
      await database.close();
    });

    final controller = container.read(recordingControllerProvider.notifier);
    await controller.start();
    expect(await database.latestRecoverableActivity(), isNotNull);

    await controller.discard();
    expect(await database.latestRecoverableActivity(), isNull);
    expect(
      container.read(recordingControllerProvider).snapshot.status,
      TrackRecorderStatus.idle,
    );
  });
}

class _FakeTrackRecorder implements TrackRecorder {
  final StreamController<TrackRecorderSnapshot> _controller =
      StreamController<TrackRecorderSnapshot>.broadcast();

  TrackRecorderSnapshot _snapshot = const TrackRecorderSnapshot(
    status: TrackRecorderStatus.idle,
    points: [],
    distanceMeters: 0,
    elapsed: Duration.zero,
  );

  @override
  Stream<TrackRecorderSnapshot> get snapshots => _controller.stream;

  BatteryMode mode = BatteryMode.balanced;

  @override
  Future<void> setBatteryMode(BatteryMode value) async {
    mode = value;
  }

  void emit(TrackRecorderSnapshot snapshot) {
    _snapshot = snapshot;
    _controller.add(snapshot);
  }

  @override
  Future<void> start() async {
    emit(
      const TrackRecorderSnapshot(
        status: TrackRecorderStatus.recording,
        points: [],
        distanceMeters: 0,
        elapsed: Duration.zero,
      ),
    );
  }

  @override
  Future<void> restore(TrackRecorderSnapshot snapshot) async {
    emit(
      TrackRecorderSnapshot(
        status: TrackRecorderStatus.paused,
        points: snapshot.points,
        distanceMeters: snapshot.distanceMeters,
        ascentMeters: snapshot.ascentMeters,
        elapsed: snapshot.elapsed,
      ),
    );
  }

  @override
  Future<void> pause() async {
    emit(
      TrackRecorderSnapshot(
        status: TrackRecorderStatus.paused,
        points: _snapshot.points,
        distanceMeters: _snapshot.distanceMeters,
        ascentMeters: _snapshot.ascentMeters,
        elapsed: _snapshot.elapsed,
      ),
    );
  }

  @override
  Future<void> resume() async {
    emit(
      TrackRecorderSnapshot(
        status: TrackRecorderStatus.recording,
        points: _snapshot.points,
        distanceMeters: _snapshot.distanceMeters,
        ascentMeters: _snapshot.ascentMeters,
        elapsed: _snapshot.elapsed,
      ),
    );
  }

  @override
  Future<TrackRecorderSnapshot> stop() async {
    final completed = TrackRecorderSnapshot(
      status: TrackRecorderStatus.completed,
      points: _snapshot.points,
      distanceMeters: _snapshot.distanceMeters,
      ascentMeters: _snapshot.ascentMeters,
      elapsed: _snapshot.elapsed,
    );
    emit(completed);
    return completed;
  }

  @override
  Future<void> dispose() => _controller.close();
}
