import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/domain/offline_region_math.dart';
import 'package:trail_path/core/services/service_providers.dart';

final offlineDownloadsProvider =
    NotifierProvider<OfflineDownloadsController, OfflineDownloadsState>(
  OfflineDownloadsController.new,
);

class OfflineDownloadsState {
  const OfflineDownloadsState({
    this.snapshots = const {},
    this.activeRouteIds = const {},
  });

  final Map<String, OfflineRegion> snapshots;
  final Set<String> activeRouteIds;

  bool isDownloading(String routeId) => activeRouteIds.contains(routeId);

  double progress(String routeId) => snapshots[routeId]?.progress ?? 0;

  OfflineDownloadsState copyWith({
    Map<String, OfflineRegion>? snapshots,
    Set<String>? activeRouteIds,
  }) {
    return OfflineDownloadsState(
      snapshots: snapshots ?? this.snapshots,
      activeRouteIds: activeRouteIds ?? this.activeRouteIds,
    );
  }
}

class OfflineDownloadsController extends Notifier<OfflineDownloadsState> {
  @override
  OfflineDownloadsState build() => const OfflineDownloadsState();

  Future<bool> prepareRoute({
    required String routeId,
    required String routeName,
    required List<GeoPoint> geometry,
  }) async {
    if (state.activeRouteIds.contains(routeId)) {
      return false;
    }

    state = state.copyWith(
      activeRouteIds: {...state.activeRouteIds, routeId},
    );

    final manager = ref.read(offlineMapManagerProvider);
    final database = ref.read(appDatabaseProvider);

    try {
      final request = offlineRegionRequestForRoute(
        id: routeId,
        name: routeName,
        points: geometry,
      );

      var completed = false;
      await for (final snapshot in manager.download(request)) {
        if (!ref.mounted) {
          return false;
        }
        state = state.copyWith(
          snapshots: {...state.snapshots, routeId: snapshot},
        );
        completed = snapshot.isComplete;
      }

      await database.setSavedRouteOfflineReady(routeId, isReady: completed);
      return completed;
    } on Object {
      try {
        await database.setSavedRouteOfflineReady(routeId, isReady: false);
      } on Object {
        // Preserve the original download failure if reconciliation also fails.
      }
      return false;
    } finally {
      if (ref.mounted) {
        final active = {...state.activeRouteIds}..remove(routeId);
        state = state.copyWith(activeRouteIds: active);
      }
    }
  }
}
