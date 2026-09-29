import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/offline_region_math.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/settings/application/settings_controller.dart';

bool allowsOfflineDownloadOnConnectivity({
  required bool wifiOnly,
  required List<ConnectivityResult> connectivity,
}) {
  if (!wifiOnly) {
    return true;
  }
  return connectivity.contains(ConnectivityResult.wifi) ||
      connectivity.contains(ConnectivityResult.ethernet);
}

final offlineDownloadsProvider =
    NotifierProvider<OfflineDownloadsController, OfflineDownloadsState>(
      OfflineDownloadsController.new,
    );

class OfflineDownloadsState {
  const OfflineDownloadsState({
    this.snapshots = const {},
    this.activeRouteIds = const {},
    this.isReconciling = false,
    this.error,
  });

  final Map<String, OfflineRegion> snapshots;
  final Set<String> activeRouteIds;
  final bool isReconciling;
  final String? error;

  bool isDownloading(String routeId) => activeRouteIds.contains(routeId);

  double progress(String routeId) => snapshots[routeId]?.progress ?? 0;

  bool isReady(String routeId) => snapshots[routeId]?.isComplete ?? false;

  OfflineDownloadsState copyWith({
    Map<String, OfflineRegion>? snapshots,
    Set<String>? activeRouteIds,
    bool? isReconciling,
    String? error,
    bool clearError = false,
  }) {
    return OfflineDownloadsState(
      snapshots: snapshots ?? this.snapshots,
      activeRouteIds: activeRouteIds ?? this.activeRouteIds,
      isReconciling: isReconciling ?? this.isReconciling,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class OfflineDownloadsController extends Notifier<OfflineDownloadsState> {
  bool _restoreScheduled = false;
  final Map<String, StreamSubscription<OfflineRegion>> _downloadSubscriptions =
      {};
  final Map<String, Completer<bool>> _downloadCompletions = {};
  final Set<String> _cancelledRouteIds = {};

  @override
  OfflineDownloadsState build() {
    if (!_restoreScheduled) {
      _restoreScheduled = true;
      unawaited(Future<void>.microtask(reconcileNativeState));
    }
    return const OfflineDownloadsState();
  }

  Future<void> reconcileNativeState() async {
    if (state.isReconciling) {
      return;
    }

    state = state.copyWith(isReconciling: true, clearError: true);
    final manager = ref.read(offlineMapManagerProvider);
    final database = ref.read(appDatabaseProvider);

    try {
      final regions = await manager.listRegions();
      if (!ref.mounted) {
        return;
      }

      final snapshots = <String, OfflineRegion>{
        for (final region in regions) region.id: region,
      };
      final completeIds = regions
          .where((region) => region.isComplete)
          .map((region) => region.id)
          .toSet();

      final routes = await database.listSavedRoutes();
      for (final route in routes) {
        final actualReady = completeIds.contains(route.id);
        if (route.isOfflineReady != actualReady) {
          await database.setSavedRouteOfflineReady(
            route.id,
            isReady: actualReady,
          );
        }
      }

      if (!ref.mounted) {
        return;
      }

      final active = state.activeRouteIds
          .where((routeId) => !completeIds.contains(routeId))
          .toSet();

      state = state.copyWith(
        snapshots: Map<String, OfflineRegion>.unmodifiable(snapshots),
        activeRouteIds: Set<String>.unmodifiable(active),
        isReconciling: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isReconciling: false, error: error.toString());
      }
    }
  }

  Future<bool> prepareRoute({
    required String routeId,
    required String routeName,
    required List<GeoPoint> geometry,
  }) async {
    if (state.activeRouteIds.contains(routeId)) {
      return false;
    }

    final manager = ref.read(offlineMapManagerProvider);
    final database = ref.read(appDatabaseProvider);

    try {
      final preferences =
          ref.read(settingsControllerProvider).asData?.value ??
          await ref.read(settingsControllerProvider.future);
      final connectivity = preferences?.wifiOnlyDownloads ?? false
          ? await Connectivity().checkConnectivity()
          : const <ConnectivityResult>[];
      if (!allowsOfflineDownloadOnConnectivity(
        wifiOnly: preferences?.wifiOnlyDownloads ?? false,
        connectivity: connectivity,
      )) {
        if (ref.mounted) {
          state = state.copyWith(
            error: 'Offline downloads are limited to Wi-Fi by user preference.',
          );
        }
        return false;
      }
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: error.toString());
      }
      return false;
    }

    try {
      final existingRegions = await manager.listRegions();
      OfflineRegion? existing;
      for (final region in existingRegions) {
        if (region.id == routeId) {
          existing = region;
          break;
        }
      }

      if (existing?.isComplete ?? false) {
        await database.setSavedRouteOfflineReady(routeId, isReady: true);
        if (ref.mounted) {
          state = state.copyWith(
            snapshots: {...state.snapshots, routeId: existing!},
            clearError: true,
          );
        }
        return true;
      }
    } on Object {
      // A native inventory failure should not prevent an explicit retry.
    }

    state = state.copyWith(
      activeRouteIds: {...state.activeRouteIds, routeId},
      clearError: true,
    );

    try {
      final request = offlineRegionRequestForRoute(
        id: routeId,
        name: routeName,
        points: geometry,
      );

      var completed = false;
      final completion = Completer<bool>();
      _downloadCompletions[routeId] = completion;

      late final StreamSubscription<OfflineRegion> subscription;
      subscription = manager
          .download(request)
          .listen(
            (snapshot) {
              if (!ref.mounted || _cancelledRouteIds.contains(routeId)) {
                return;
              }
              state = state.copyWith(
                snapshots: {...state.snapshots, routeId: snapshot},
                clearError: true,
              );
              completed = snapshot.isComplete;
              if (completed && !completion.isCompleted) {
                completion.complete(true);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!completion.isCompleted) {
                completion.completeError(error, stackTrace);
              }
            },
            onDone: () {
              if (!completion.isCompleted) {
                completion.complete(completed);
              }
            },
          );
      _downloadSubscriptions[routeId] = subscription;

      completed = await completion.future;
      await subscription.cancel();

      if (_cancelledRouteIds.contains(routeId)) {
        await database.setSavedRouteOfflineReady(routeId, isReady: false);
        return false;
      }

      await database.setSavedRouteOfflineReady(routeId, isReady: completed);
      return completed;
    } on Object catch (error) {
      try {
        await database.setSavedRouteOfflineReady(routeId, isReady: false);
      } on Object {
        // Preserve the original download failure if reconciliation also fails.
      }

      if (ref.mounted) {
        state = state.copyWith(error: error.toString());
      }
      return false;
    } finally {
      _downloadCompletions.remove(routeId);
      final subscription = _downloadSubscriptions.remove(routeId);
      await subscription?.cancel();
      _cancelledRouteIds.remove(routeId);
      if (ref.mounted) {
        final active = {...state.activeRouteIds}..remove(routeId);
        state = state.copyWith(
          activeRouteIds: Set<String>.unmodifiable(active),
        );
      }
    }
  }

  Future<bool> cancelDownload(String routeId) async {
    if (!state.activeRouteIds.contains(routeId)) {
      return false;
    }

    final manager = ref.read(offlineMapManagerProvider);
    final database = ref.read(appDatabaseProvider);
    _cancelledRouteIds.add(routeId);

    final completion = _downloadCompletions[routeId];
    if (completion != null && !completion.isCompleted) {
      completion.complete(false);
    }

    try {
      await _downloadSubscriptions.remove(routeId)?.cancel();
      await manager.delete(routeId);
      await database.setSavedRouteOfflineReady(routeId, isReady: false);

      if (ref.mounted) {
        final snapshots = {...state.snapshots}..remove(routeId);
        final active = {...state.activeRouteIds}..remove(routeId);
        state = state.copyWith(
          snapshots: Map<String, OfflineRegion>.unmodifiable(snapshots),
          activeRouteIds: Set<String>.unmodifiable(active),
          clearError: true,
        );
      }
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: error.toString());
      }
      return false;
    }
  }

  Future<bool> deleteRouteAndOfflineData(String routeId) async {
    final manager = ref.read(offlineMapManagerProvider);
    final database = ref.read(appDatabaseProvider);

    try {
      // Native offline data belongs to the saved route lifecycle. Remove it
      // first so a failed native cleanup never leaves an invisible orphan
      // after the database row has already disappeared.
      await manager.delete(routeId);
      await database.deleteSavedRoute(routeId);

      if (ref.mounted) {
        final snapshots = {...state.snapshots}..remove(routeId);
        final active = {...state.activeRouteIds}..remove(routeId);
        state = state.copyWith(
          snapshots: Map<String, OfflineRegion>.unmodifiable(snapshots),
          activeRouteIds: Set<String>.unmodifiable(active),
          clearError: true,
        );
      }
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: error.toString());
      }
      return false;
    }
  }

  Future<bool> deleteRegion(String routeId) async {
    final manager = ref.read(offlineMapManagerProvider);
    final database = ref.read(appDatabaseProvider);

    try {
      await manager.delete(routeId);
      await database.setSavedRouteOfflineReady(routeId, isReady: false);

      if (ref.mounted) {
        final snapshots = {...state.snapshots}..remove(routeId);
        final active = {...state.activeRouteIds}..remove(routeId);
        state = state.copyWith(
          snapshots: Map<String, OfflineRegion>.unmodifiable(snapshots),
          activeRouteIds: Set<String>.unmodifiable(active),
          clearError: true,
        );
      }
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: error.toString());
      }
      return false;
    }
  }
}
