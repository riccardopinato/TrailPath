import 'dart:async';
import 'dart:io';

import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';

class MapLibreOfflineMapManager implements OfflineMapManager {
  const MapLibreOfflineMapManager();

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<List<OfflineRegion>> listRegions() async {
    if (!_isSupported) {
      return const [];
    }

    final nativeRegions = await ml.getListOfRegions();
    final regions = <OfflineRegion>[];

    for (final nativeRegion in nativeRegions) {
      final status = await ml.getOfflineRegionStatus(nativeRegion.id);
      regions.add(_toDomain(nativeRegion, status));
    }

    regions.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<OfflineRegion>.unmodifiable(regions);
  }

  @override
  Stream<OfflineRegion> download(OfflineRegionRequest request) {
    final controller = StreamController<OfflineRegion>();
    unawaited(_download(request, controller));
    return controller.stream;
  }

  Future<void> _download(
    OfflineRegionRequest request,
    StreamController<OfflineRegion> controller,
  ) async {
    try {
      if (!_isSupported) {
        throw UnsupportedError('Offline maps require Android or iOS.');
      }

      final existing = await ml.getListOfRegions();
      for (final region in existing) {
        if (!_matches(region, request.id)) {
          continue;
        }
        final status = await ml.getOfflineRegionStatus(region.id);
        if (status.isComplete) {
          controller.add(_toDomain(region, status));
          return;
        }
        await ml.deleteOfflineRegion(region.id);
      }

      controller.add(
        OfflineRegion(
          id: request.id,
          name: request.name,
          downloadedBytes: 0,
          isComplete: false,
        ),
      );

      final completion = Completer<void>();
      var lastBytes = 0;
      var lastProgress = 0.0;

      final nativeRegion = await ml.downloadOfflineRegion(
        ml.OfflineRegionDefinition(
          bounds: ml.LatLngBounds(
            southwest: ml.LatLng(request.south, request.west),
            northeast: ml.LatLng(request.north, request.east),
          ),
          mapStyleUrl: MapConfig.styleUrl,
          minZoom: request.minZoom,
          maxZoom: request.maxZoom,
        ),
        metadata: {
          'trailPathRegionId': request.id,
          'name': request.name,
        },
        onEvent: (event) {
          if (event is ml.InProgress) {
            lastBytes = event.completedResourceSize;
            lastProgress = (event.progress / 100).clamp(0.0, 1.0).toDouble();
            if (!controller.isClosed) {
              controller.add(
                OfflineRegion(
                  id: request.id,
                  name: request.name,
                  downloadedBytes: lastBytes,
                  isComplete: false,
                  progress: lastProgress,
                ),
              );
            }
          } else if (event is ml.Success && !completion.isCompleted) {
            completion.complete();
          } else if (event is ml.Error && !completion.isCompleted) {
            completion.completeError(StateError(event.cause.toString()));
          }
        },
      );

      await completion.future;

      final status = await ml.getOfflineRegionStatus(nativeRegion.id);
      if (!controller.isClosed) {
        controller.add(
          OfflineRegion(
            id: request.id,
            name: request.name,
            downloadedBytes: status.completedResourceSize > 0
                ? status.completedResourceSize
                : lastBytes,
            isComplete: status.isComplete,
            progress: status.isComplete
                ? 1
                : (status.downloadProgress / 100)
                    .clamp(lastProgress, 1.0)
                    .toDouble(),
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    } finally {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  @override
  Future<void> delete(String regionId) async {
    if (!_isSupported) {
      return;
    }

    final regions = await ml.getListOfRegions();
    for (final region in regions) {
      if (_matches(region, regionId)) {
        await ml.deleteOfflineRegion(region.id);
      }
    }
  }

  @override
  Future<void> clearCache() async {
    if (_isSupported) {
      await ml.clearAmbientCache();
    }
  }

  bool _matches(ml.OfflineRegion region, String domainId) {
    return region.metadata['trailPathRegionId']?.toString() == domainId ||
        region.id.toString() == domainId;
  }

  OfflineRegion _toDomain(
    ml.OfflineRegion region,
    ml.OfflineRegionStatus status,
  ) {
    return OfflineRegion(
      id: region.metadata['trailPathRegionId']?.toString() ??
          region.id.toString(),
      name: region.metadata['name']?.toString() ?? 'Offline map',
      downloadedBytes: status.completedResourceSize,
      isComplete: status.isComplete,
      progress: status.isComplete
          ? 1
          : (status.downloadProgress / 100).clamp(0.0, 1.0).toDouble(),
    );
  }
}
