import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/outdoor/application/battery_mode_controller.dart';

final recordingControllerProvider =
    NotifierProvider<RecordingController, RecordingState>(
  RecordingController.new,
);

class RecordingState {
  const RecordingState({
    this.snapshot = const TrackRecorderSnapshot(
      status: TrackRecorderStatus.idle,
      points: [],
      distanceMeters: 0,
      elapsed: Duration.zero,
    ),
    this.profile = RouteProfile.hiking,
    this.activityId,
    this.hasRecoveredDraft = false,
    this.isCheckingRecovery = false,
    this.error,
  });

  final TrackRecorderSnapshot snapshot;
  final RouteProfile profile;
  final String? activityId;
  final bool hasRecoveredDraft;
  final bool isCheckingRecovery;
  final String? error;

  bool get isActive =>
      snapshot.status == TrackRecorderStatus.recording ||
      snapshot.status == TrackRecorderStatus.paused;

  RecordingState copyWith({
    TrackRecorderSnapshot? snapshot,
    RouteProfile? profile,
    String? activityId,
    bool clearActivityId = false,
    bool? hasRecoveredDraft,
    bool? isCheckingRecovery,
    String? error,
    bool clearError = false,
  }) {
    return RecordingState(
      snapshot: snapshot ?? this.snapshot,
      profile: profile ?? this.profile,
      activityId: clearActivityId ? null : activityId ?? this.activityId,
      hasRecoveredDraft: hasRecoveredDraft ?? this.hasRecoveredDraft,
      isCheckingRecovery: isCheckingRecovery ?? this.isCheckingRecovery,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class RecordingController extends Notifier<RecordingState> {
  StreamSubscription<TrackRecorderSnapshot>? _subscription;
  Future<void> _persistChain = Future<void>.value();
  DateTime? _lastPersistedAt;
  int _lastPersistedPointCount = 0;
  TrackRecorderStatus? _lastPersistedStatus;
  bool _recoveryChecked = false;
  late TrackRecorder _recorder;
  late AppDatabase _database;

  @override
  RecordingState build() {
    _recorder = ref.read(trackRecorderProvider);
    _database = ref.read(appDatabaseProvider);
    ref.listen(batteryModeProvider, (previous, next) {
      next.whenData((mode) {
        if (state.isActive) {
          unawaited(_recorder.setBatteryMode(mode));
        }
      });
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const RecordingState();
  }

  Future<void> checkRecovery() async {
    if (_recoveryChecked || state.isActive) {
      return;
    }
    _recoveryChecked = true;
    state = state.copyWith(
      isCheckingRecovery: true,
      clearError: true,
    );

    try {
      final activity = await _database.latestRecoverableActivity();
      if (!ref.mounted) {
        return;
      }
      if (activity == null) {
        state = state.copyWith(isCheckingRecovery: false);
        return;
      }

      final points = _database.decodeActivityPoints(activity);
      final snapshot = TrackRecorderSnapshot(
        status: TrackRecorderStatus.paused,
        points: points,
        distanceMeters: activity.distanceMeters,
        ascentMeters: activity.ascentMeters,
        elapsed: Duration(seconds: activity.movingSeconds),
      );
      await _recorder.restore(snapshot);
      if (!ref.mounted) {
        return;
      }
      await _bindRecorder();
      if (!ref.mounted) {
        return;
      }

      _lastPersistedAt = activity.updatedAt ?? activity.startedAt;
      _lastPersistedPointCount = points.length;
      _lastPersistedStatus = TrackRecorderStatus.paused;

      state = state.copyWith(
        snapshot: snapshot,
        profile: _profileFromName(activity.profile),
        activityId: activity.id,
        hasRecoveredDraft: true,
        isCheckingRecovery: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          isCheckingRecovery: false,
          error: error.toString(),
        );
      }
    }
  }

  void setProfile(RouteProfile profile) {
    if (state.isActive) {
      return;
    }
    state = state.copyWith(profile: profile);
  }

  Future<void> start() async {
    if (state.isActive) {
      return;
    }

    final profile = state.profile;
    final permissions = ref.read(runtimePermissionProvider);
    final batteryModeFuture = ref.read(batteryModeProvider.future);
    String? activityId;

    try {
      activityId = await _database.createActivityDraft(profile: profile);
      if (!ref.mounted) {
        await _safeDiscardDraft(activityId);
        return;
      }

      state = state.copyWith(
        activityId: activityId,
        hasRecoveredDraft: false,
        clearError: true,
      );

      await permissions.prepareRecording();
      if (!ref.mounted) {
        await _safeDiscardDraft(activityId);
        return;
      }

      final batteryMode = await batteryModeFuture;
      if (!ref.mounted) {
        await _safeDiscardDraft(activityId);
        return;
      }

      await _recorder.setBatteryMode(batteryMode);
      if (!ref.mounted) {
        await _safeDiscardDraft(activityId);
        return;
      }

      await _bindRecorder();
      if (!ref.mounted) {
        await _safeDiscardDraft(activityId);
        return;
      }
      await _recorder.start();
    } on Object catch (error) {
      if (activityId != null) {
        await _safeDiscardDraft(activityId);
      }
      if (ref.mounted) {
        state = state.copyWith(
          clearActivityId: true,
          error: error.toString(),
        );
      }
    }
  }

  Future<void> pause() async {
    if (state.snapshot.status != TrackRecorderStatus.recording) {
      return;
    }
    await _recorder.pause();
    if (ref.mounted) {
      await _flushAutosave();
    }
  }

  Future<void> resume() async {
    if (state.snapshot.status != TrackRecorderStatus.paused) {
      return;
    }

    final permissions = ref.read(runtimePermissionProvider);
    final batteryModeFuture = ref.read(batteryModeProvider.future);
    state = state.copyWith(
      hasRecoveredDraft: false,
      clearError: true,
    );

    try {
      await permissions.prepareRecording();
      if (!ref.mounted) {
        return;
      }
      final batteryMode = await batteryModeFuture;
      if (!ref.mounted) {
        return;
      }
      await _recorder.setBatteryMode(batteryMode);
      if (!ref.mounted) {
        return;
      }
      await _recorder.resume();
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: error.toString());
      }
    }
  }

  Future<bool> finish(String name) async {
    final activityId = state.activityId;
    if (activityId == null || !state.isActive) {
      return false;
    }

    final profile = state.profile;
    try {
      final completed = await _recorder.stop();
      await _persistChain;

      if (completed.points.length < 2) {
        await _database.discardActivity(activityId);
        if (ref.mounted) {
          state = RecordingState(profile: profile);
          _resetPersistenceState();
        }
        return false;
      }

      await _database.completeActivity(
        activityId: activityId,
        name: name.trim().isEmpty ? 'TrailPath activity' : name.trim(),
        snapshot: completed,
      );

      if (ref.mounted) {
        state = RecordingState(profile: profile);
        _resetPersistenceState();
      }
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: error.toString());
      }
      return false;
    }
  }

  Future<void> discard() async {
    final activityId = state.activityId;
    final profile = state.profile;
    try {
      if (state.isActive) {
        await _recorder.stop();
      }
    } on Object {
      // The local draft is discarded even if the platform recorder already
      // stopped or the location stream was interrupted.
    }

    if (activityId != null) {
      await _database.discardActivity(activityId);
    }

    if (ref.mounted) {
      state = RecordingState(profile: profile);
      _resetPersistenceState();
    }
  }

  Future<void> _bindRecorder() async {
    await _subscription?.cancel();
    if (!ref.mounted) {
      return;
    }
    _subscription = _recorder.snapshots.listen(
      (snapshot) {
        if (!ref.mounted) {
          return;
        }
        state = state.copyWith(
          snapshot: snapshot,
          clearError: true,
        );
        _scheduleAutosave(snapshot);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (ref.mounted) {
          state = state.copyWith(error: error.toString());
        }
      },
    );
  }

  void _scheduleAutosave(TrackRecorderSnapshot snapshot) {
    final activityId = state.activityId;
    if (activityId == null ||
        snapshot.status == TrackRecorderStatus.idle ||
        snapshot.status == TrackRecorderStatus.completed) {
      return;
    }

    final now = DateTime.now();
    final statusChanged = _lastPersistedStatus != snapshot.status;
    final pointDelta = snapshot.points.length - _lastPersistedPointCount;
    final age = _lastPersistedAt == null
        ? const Duration(days: 1)
        : now.difference(_lastPersistedAt!);

    if (!statusChanged && pointDelta < 3 && age < const Duration(seconds: 5)) {
      return;
    }

    _lastPersistedAt = now;
    _lastPersistedPointCount = snapshot.points.length;
    _lastPersistedStatus = snapshot.status;

    _queuePersist(
      activityId: activityId,
      snapshot: snapshot,
    );
  }

  Future<void> _flushAutosave() async {
    final activityId = state.activityId;
    if (activityId == null) {
      return;
    }

    final snapshot = state.snapshot;
    _queuePersist(
      activityId: activityId,
      snapshot: snapshot,
    );
    await _persistChain;
  }

  void _queuePersist({
    required String activityId,
    required TrackRecorderSnapshot snapshot,
  }) {
    _persistChain = _persistChain
        .then(
          (_) => _database.updateActivityDraft(
            activityId: activityId,
            snapshot: snapshot,
          ),
        )
        .catchError((Object error, StackTrace stackTrace) {
          if (ref.mounted) {
            state = state.copyWith(error: error.toString());
          }
        });
  }

  Future<void> _safeDiscardDraft(String activityId) async {
    try {
      await _database.discardActivity(activityId);
    } on Object {
      // Best effort cleanup if the owning provider/container is shutting down.
    }
  }

  void _resetPersistenceState() {
    _lastPersistedAt = null;
    _lastPersistedPointCount = 0;
    _lastPersistedStatus = null;
    _persistChain = Future<void>.value();
    _recoveryChecked = true;
  }
}

RouteProfile _profileFromName(String value) {
  for (final profile in RouteProfile.values) {
    if (profile.name == value) {
      return profile;
    }
  }
  return RouteProfile.hiking;
}
