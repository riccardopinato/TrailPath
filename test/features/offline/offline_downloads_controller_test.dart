import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/core/database/app_database.dart';
import 'package:trail_path/core/database/database_providers.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/core/services/service_providers.dart';
import 'package:trail_path/features/offline/application/offline_downloads_controller.dart';

void main() {
  test('Wi-Fi-only policy blocks mobile connectivity', () {
    expect(
      allowsOfflineDownloadOnConnectivity(
        wifiOnly: true,
        connectivity: const [ConnectivityResult.mobile],
      ),
      isFalse,
    );
    expect(
      allowsOfflineDownloadOnConnectivity(
        wifiOnly: true,
        connectivity: const [ConnectivityResult.wifi],
      ),
      isTrue,
    );
    expect(
      allowsOfflineDownloadOnConnectivity(
        wifiOnly: false,
        connectivity: const [ConnectivityResult.mobile],
      ),
      isTrue,
    );
  });

  test(
    'reconcile restores native offline state and repairs database flag',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);

      final routeId = await database.savePlannedRoute(
        name: 'Recovery route',
        profile: RouteProfile.hiking.name,
        waypointsData: const [
          GeoPoint(latitude: 45.20, longitude: 11.70),
          GeoPoint(latitude: 45.21, longitude: 11.71),
        ],
        geometryData: const [
          GeoPoint(latitude: 45.20, longitude: 11.70),
          GeoPoint(latitude: 45.21, longitude: 11.71),
        ],
        distanceMeters: 1500,
        ascentMeters: 50,
        descentMeters: 30,
        estimatedDuration: const Duration(minutes: 25),
      );

      final manager = _FakeOfflineMapManager(
        regions: [
          OfflineRegion(
            id: routeId,
            name: 'Recovery route',
            downloadedBytes: 42000,
            isComplete: true,
            progress: 1,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          offlineMapManagerProvider.overrideWithValue(manager),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(offlineDownloadsProvider.notifier)
          .reconcileNativeState();

      final state = container.read(offlineDownloadsProvider);
      expect(state.isReady(routeId), isTrue);
      expect(state.snapshots[routeId]?.downloadedBytes, 42000);

      final routes = await database.listSavedRoutes();
      expect(routes.single.isOfflineReady, isTrue);
    },
  );

  test('route deletion also removes its native offline region', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    final routeId = await database.savePlannedRoute(
      name: 'Delete route',
      profile: RouteProfile.hiking.name,
      waypointsData: const [
        GeoPoint(latitude: 45.20, longitude: 11.70),
        GeoPoint(latitude: 45.21, longitude: 11.71),
      ],
      geometryData: const [
        GeoPoint(latitude: 45.20, longitude: 11.70),
        GeoPoint(latitude: 45.21, longitude: 11.71),
      ],
      distanceMeters: 1200,
      ascentMeters: 40,
      descentMeters: 20,
      estimatedDuration: const Duration(minutes: 20),
    );

    final manager = _FakeOfflineMapManager(
      regions: [
        OfflineRegion(
          id: routeId,
          name: 'Delete route',
          downloadedBytes: 32000,
          isComplete: true,
          progress: 1,
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        offlineMapManagerProvider.overrideWithValue(manager),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(offlineDownloadsProvider.notifier)
        .reconcileNativeState();

    final deleted = await container
        .read(offlineDownloadsProvider.notifier)
        .deleteRouteAndOfflineData(routeId);

    expect(deleted, isTrue);
    expect(manager.deletedIds, contains(routeId));
    expect(await database.listSavedRoutes(), isEmpty);
    expect(container.read(offlineDownloadsProvider).snapshots, isEmpty);
  });

  test('active offline download can be cancelled cleanly', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    final routeId = await database.savePlannedRoute(
      name: 'Cancelable route',
      profile: RouteProfile.hiking.name,
      waypointsData: const [
        GeoPoint(latitude: 45.20, longitude: 11.70),
        GeoPoint(latitude: 45.23, longitude: 11.73),
      ],
      geometryData: const [
        GeoPoint(latitude: 45.20, longitude: 11.70),
        GeoPoint(latitude: 45.23, longitude: 11.73),
      ],
      distanceMeters: 3200,
      ascentMeters: 90,
      descentMeters: 70,
      estimatedDuration: const Duration(minutes: 45),
    );

    final manager = _ControllableOfflineMapManager();
    addTearDown(manager.dispose);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        offlineMapManagerProvider.overrideWithValue(manager),
      ],
    );
    addTearDown(container.dispose);

    final prepare = container
        .read(offlineDownloadsProvider.notifier)
        .prepareRoute(
          routeId: routeId,
          routeName: 'Cancelable route',
          geometry: const [
            GeoPoint(latitude: 45.20, longitude: 11.70),
            GeoPoint(latitude: 45.23, longitude: 11.73),
          ],
        );

    await Future<void>.delayed(Duration.zero);
    await manager.waitUntilStarted();

    manager.emit(
      OfflineRegion(
        id: routeId,
        name: 'Cancelable route',
        downloadedBytes: 16000,
        isComplete: false,
        progress: 0.4,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(offlineDownloadsProvider).isDownloading(routeId),
      isTrue,
    );

    final cancelled = await container
        .read(offlineDownloadsProvider.notifier)
        .cancelDownload(routeId);
    final completed = await prepare;

    expect(cancelled, isTrue);
    expect(completed, isFalse);
    expect(manager.deletedIds, contains(routeId));
    expect(
      container.read(offlineDownloadsProvider).isDownloading(routeId),
      isFalse,
    );
    expect(container.read(offlineDownloadsProvider).snapshots[routeId], isNull);

    final routes = await database.listSavedRoutes();
    expect(routes.single.isOfflineReady, isFalse);
  });

  test(
    'incomplete region is restartable after process-state recovery',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);

      final routeId = await database.savePlannedRoute(
        name: 'Interrupted route',
        profile: RouteProfile.walking.name,
        waypointsData: const [
          GeoPoint(latitude: 45.20, longitude: 11.70),
          GeoPoint(latitude: 45.22, longitude: 11.72),
        ],
        geometryData: const [
          GeoPoint(latitude: 45.20, longitude: 11.70),
          GeoPoint(latitude: 45.22, longitude: 11.72),
        ],
        distanceMeters: 2200,
        ascentMeters: 20,
        descentMeters: 20,
        estimatedDuration: const Duration(minutes: 30),
      );

      final manager = _FakeOfflineMapManager(
        regions: [
          OfflineRegion(
            id: routeId,
            name: 'Interrupted route',
            downloadedBytes: 12000,
            isComplete: false,
            progress: 0.35,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          offlineMapManagerProvider.overrideWithValue(manager),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(offlineDownloadsProvider.notifier)
          .reconcileNativeState();

      expect(
        container.read(offlineDownloadsProvider).isDownloading(routeId),
        isFalse,
      );
      expect(container.read(offlineDownloadsProvider).progress(routeId), 0.35);

      final success = await container
          .read(offlineDownloadsProvider.notifier)
          .prepareRoute(
            routeId: routeId,
            routeName: 'Interrupted route',
            geometry: const [
              GeoPoint(latitude: 45.20, longitude: 11.70),
              GeoPoint(latitude: 45.22, longitude: 11.72),
            ],
          );

      expect(success, isTrue);
      expect(manager.downloadCount, 1);
      expect(container.read(offlineDownloadsProvider).isReady(routeId), isTrue);

      final routes = await database.listSavedRoutes();
      expect(routes.single.isOfflineReady, isTrue);
    },
  );
}

class _FakeOfflineMapManager implements OfflineMapManager {
  _FakeOfflineMapManager({required List<OfflineRegion> regions})
    : _regions = List<OfflineRegion>.from(regions);

  List<OfflineRegion> _regions;
  int downloadCount = 0;
  final List<String> deletedIds = <String>[];

  @override
  Future<List<OfflineRegion>> listRegions() async =>
      List<OfflineRegion>.unmodifiable(_regions);

  @override
  Stream<OfflineRegion> download(OfflineRegionRequest request) async* {
    downloadCount++;
    final progress = OfflineRegion(
      id: request.id,
      name: request.name,
      downloadedBytes: 24000,
      isComplete: false,
      progress: 0.65,
    );
    _regions = [progress];
    yield progress;

    final complete = OfflineRegion(
      id: request.id,
      name: request.name,
      downloadedBytes: 48000,
      isComplete: true,
      progress: 1,
    );
    _regions = [complete];
    yield complete;
  }

  @override
  Future<void> delete(String regionId) async {
    deletedIds.add(regionId);
    _regions.removeWhere((region) => region.id == regionId);
  }

  @override
  Future<void> clearCache() async {}

  Future<void> dispose() => _controller.close();
}

class _ControllableOfflineMapManager implements OfflineMapManager {
  final StreamController<OfflineRegion> _controller =
      StreamController<OfflineRegion>();
  final Completer<void> _started = Completer<void>();
  final List<String> deletedIds = <String>[];

  Future<void> waitUntilStarted() => _started.future;

  void emit(OfflineRegion region) {
    if (!_controller.isClosed) {
      _controller.add(region);
    }
  }

  @override
  Future<List<OfflineRegion>> listRegions() async => const [];

  @override
  Stream<OfflineRegion> download(OfflineRegionRequest request) {
    if (!_started.isCompleted) {
      _started.complete();
    }
    return _controller.stream;
  }

  @override
  Future<void> delete(String regionId) async {
    deletedIds.add(regionId);
  }

  @override
  Future<void> clearCache() async {}
}
